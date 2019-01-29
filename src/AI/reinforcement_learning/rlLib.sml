(* ========================================================================= *)
(* FILE          : rlProve.sml                                               *)
(* DESCRIPTION   : Datatypes for the robber theorem prover                   *)
(* AUTHOR        : (c) Thibault Gauthier, Czech Technical University         *)
(* DATE          : 2018                                                      *)
(* ========================================================================= *)

structure rlLib :> rlLib =
struct

open HolKernel Abbrev boolLib aiLib
mlFeature mlNearestNeighbor mlTreeNeuralNetwork

val ERR = mk_HOL_ERR "rlProve"

type pos = int list

(* -------------------------------------------------------------------------
   Extra variables
   ------------------------------------------------------------------------- *)

val num_ty = ``:num``;
val numtag_var = mk_var ("numtag_var", mk_type ("fun",[num_ty,num_ty]))
val numhole_var = mk_var ("numhole_var", num_ty)
val active_var = mk_var ("active_var", num_ty)
val pending_var = mk_var ("pending_var", num_ty)

val extra_operl =
  [(numtag_var,1),(numhole_var,0),(active_var,0),(pending_var,0)];

(* -------------------------------------------------------------------------
   Oracle
   ------------------------------------------------------------------------- *)

fun ground_decide thml tm =
  let val (gl,v) = REWRITE_TAC thml ([],tm) in null gl end
  handle HOL_ERR _ => false

(* -------------------------------------------------------------------------
   Readability
   ------------------------------------------------------------------------- *)

val eq1 = ``SUC 0 = 1``;
val eq2 = ``SUC 1 = 2``;
val eq3 = ``SUC 2 = 3``;
val eq4 = ``SUC 3 = 4``;
val eq5 = ``SUC 4 = 5``;
val eql = [eq1,eq2,eq3,eq4,eq5];

(* val ex_tm0 = ``SUC (SUC 0) + SUC 0 = SUC (SUC (SUC 0))``; *)

fun human_readable tm =
  let
    fun eq_to_sub eq = [{redex = lhs eq, residue = rhs eq}]
    val subl = map eq_to_sub eql
    fun f (sub,x) = subst sub x
  in
    foldl f tm subl
  end

(* -------------------------------------------------------------------------
   Term tools
   ------------------------------------------------------------------------- *)

fun fo_terms tm =
  let val (oper,argl) = strip_comb tm in
    tm :: List.concat (map fo_terms argl)
  end

fun operl_of_term tm =
  let
    val tml = mk_fast_set Term.compare (fo_terms tm)
    fun f x = let val (oper,argl) = strip_comb x in (oper, length argl) end
  in
    mk_fast_set (cpl_compare Term.compare Int.compare) (map f tml)
  end

fun negate x = if is_neg x then dest_neg x else mk_neg x

fun is_subtm a b = can (find_term (fn x => x = a)) b

fun is_refl tm =
  let val (a,b) = dest_eq tm in a = b end handle HOL_ERR _ => false

(* -------------------------------------------------------------------------
   Position in term
   ------------------------------------------------------------------------- *)

(* todo: standardize these *)
fun sub_at_pos tm (pos,res) =
  if null pos then res else
  let
    val (oper,argl) = strip_comb tm
    fun f i x =
      if i = hd pos then sub_at_pos x (tl pos,res) else x
    val newargl = mapi f argl
  in
    list_mk_comb (oper,newargl)
  end

fun subtm_at_pos pos tm =
  if null pos then tm else
  let val (oper,argl) = strip_comb tm in
    subtm_at_pos (tl pos) (List.nth (argl,hd pos))
  end

fun recover_cut tm (pos,res) =
  let val red = subtm_at_pos pos tm in
    mk_eq (red,res)
    handle HOL_ERR _ =>
      raise ERR "recover_cut" (term_to_string red ^ " " ^ term_to_string res)
  end

fun all_posred_aux curpos tm =
  let
    val (oper,argl) = strip_comb tm
    fun f i x = all_posred_aux (i :: curpos) x
    val posl = List.concat (mapi f argl)
  in
    (curpos,tm) :: posl
  end

fun all_posred tm = map_fst rev (all_posred_aux [] tm)

fun tag_position (tm,pos) =
  if null pos then (if is_eq tm then tm else mk_comb (numtag_var,tm)) else
  let
    val (oper,argl) = strip_comb tm
    fun f i arg =
      if i = hd pos
      then tag_position (arg,tl pos)
      else arg
  in
    list_mk_comb (oper, mapi f argl)
  end

fun hole_position (tm,pos) =
  if null pos then numhole_var else
  let
    val (oper,argl) = strip_comb tm
    fun f i arg =
      if i = hd pos
      then hole_position (arg,tl pos)
      else arg
  in
    list_mk_comb (oper, mapi f argl)
  end

(* subtm is a variable that appears once in tm1 and tm2 matches tm1 until
   this point *)
fun match_subtm subtm (tm1,tm2) =
  if tm1 = subtm then tm2 else
  let
    val (oper1,argl1) = strip_comb tm1
    val (oper2,argl2) = strip_comb tm2
    val _ = if oper1 <> oper2 then raise ERR "match_subtm" "" else ()
    val argl = combine (argl1,argl2)
    fun f (a,_) = is_subtm subtm a
    val (newtm1,newtm2) = valOf (List.find f argl)
  in
    match_subtm subtm (newtm1,newtm2)
  end

fun sub_tac (tm,pos) ax =
  let val subtm = subtm_at_pos pos tm in
    if can (match_term (lhs ax)) subtm then
      let
        val (sub,_) = match_term (lhs ax) subtm
        val res = subst sub (rhs ax)
        val holetm = hole_position (tm,pos)
        val holesub = [{redex = numhole_var, residue = res}]
      in
        subst holesub holetm
      end
    else raise ERR "sub_tac" ""
  end

fun sym_tac tm = let val (a,b) = dest_eq tm in mk_eq (b,a) end;

(* -------------------------------------------------------------------------
   Arithmetic tools
   ------------------------------------------------------------------------- *)

fun mk_suc x = mk_comb (``SUC``,x);
fun mk_add (a,b) = list_mk_comb (``$+``,[a,b]);
val zero = ``0``;
fun mk_sucn n = funpow n mk_suc zero;
fun mk_mult (a,b) = list_mk_comb (``$*``,[a,b]);

fun dest_suc x =
  let val (a,b) = dest_comb x in
    if a <> ``SUC`` then raise ERR "" "" else b
  end

fun dest_add tm =
  let val (oper,argl) = strip_comb tm in
    if oper <> ``$+`` then raise ERR "" "" else pair_of_list argl
  end



end (* struct *)

