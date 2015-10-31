open HolKernel boolLib bossLib OpenTheoryMap OpenTheoryBoolTheory lcsymtacs

val Thy = "HOL4bool"
val _ = new_theory Thy

val n = ref 0;
fun export (tm,tac) =
  store_thm(("th"^Int.toString(!n)),tm,tac)
  before n := !n+1

val res0 = export(``!t. F ==> t``,
  gen_tac >>
  qspec_then`t`(ACCEPT_TAC o C MATCH_MP OTbool136 o snd o EQ_IMP_RULE) OTbool98)
  (* DB.match["OpenTheoryBool"]``F ==> t`` *)

val res = export(``~~p ==> p``,
  qspec_then`p`(ACCEPT_TAC o fst o EQ_IMP_RULE) OTbool110)
  (* DB.match["OpenTheoryBool"]``~~p`` *)

val res2 = export(``~(p ==> q) ==> p``,
  strip_tac >>
  qspecl_then[`p`,`q`](ACCEPT_TAC o CONJUNCT1 o UNDISCH o fst o EQ_IMP_RULE) OTbool52)
  (* DB.match["OpenTheoryBool"]``~(p ==> q)`` *)

val res3 = export(``!x. x = (x = T)``,
  ACCEPT_TAC(GSYM OTbool106))
  (* DB.match["OpenTheoryBool"]``x = T`` *)

val res = export(``~(p ==> q) ==> ~q``,
  strip_tac >>
  qspecl_then[`p`,`q`](ACCEPT_TAC o CONJUNCT2 o UNDISCH o fst o EQ_IMP_RULE) OTbool52)
  (* DB.match["OpenTheoryBool"]``~(p ==> q)`` *)

val res = export(``~(p \/ q) ==> ~p``,
  strip_tac >>
  qspecl_then[`p`,`q`](ACCEPT_TAC o CONJUNCT1 o UNDISCH o fst o EQ_IMP_RULE) OTbool50)
  (* DB.match["OpenTheoryBool"]``~(p \/ q)`` *)

val res = export(``~(p \/ q) ==> ~q``,
  strip_tac >>
  qspecl_then[`p`,`q`](ACCEPT_TAC o CONJUNCT2 o UNDISCH o fst o EQ_IMP_RULE) OTbool50)
  (* DB.match["OpenTheoryBool"]``~(p \/ q)`` *)

val res7 = export(``!A. A ==> ~A ==> F``,
  gen_tac >> strip_tac >>
  disch_then(fn th => qspec_then`A`(mp_tac o C EQ_MP th o SYM)OTbool104) >>
  disch_then(fn th => pop_assum(ACCEPT_TAC o EQ_MP (SYM th))))
  (* DB.match["OpenTheoryBool"]``(F ⇔ t) ⇔ ~t`` *)

val res8 = export(``!t1 t2. (t1 ==> t2) ==> (t2 ==> t1) ==> (t1 <=> t2)``,
  deductAntisym
  (MP (ASSUME``t2 ==> t1``) (ASSUME``t2:bool``))
  (MP (ASSUME``t1 ==> t2``) (ASSUME``t1:bool``))
  |> DISCH``t2 ==> t1`` |> DISCH_ALL
  |> Q.GEN`t2` |> GEN_ALL
  |> ACCEPT_TAC)

val res9 = export(``!t. t ==> F <=> (t = F)``,
  res8
  |> Q.SPECL[`t==>F`,`t <=> F`]
  |> C MP (DISCH_ALL(SYM(UNDISCH(MATCH_MP res8 (SPEC_ALL res0)))))
  |> CONV_RULE(PATH_CONV"lrlr"(REWR_CONV (SPEC_ALL OTbool105) THENC
               RATOR_CONV(REWR_CONV OTbool132) THENC
               BETA_CONV))
  |> C MP (DISCH_ALL(ASSUME``t ==> F``))
  |> GEN_ALL
  |> ACCEPT_TAC)
  (* DB.match["OpenTheoryBool"]``(t <=> F) = ~t`` *)
  (* DB.match["OpenTheoryBool"]``$~ = x`` *)

val res = export(``!x. (x = x) <=> T``,
  EQ_MP(SYM(Q.SPEC`x = x`OTbool106))(REFL``x:'a``)
  |> GEN_ALL |> ACCEPT_TAC)
  (* DB.match["OpenTheoryBool"]``(x = T)`` *)

val _ = OpenTheory_const_name{
  const={Thy=Thy,Name="literal_case"},
  name=(["HOL4"],"literal_case")}
val def = new_definition("literal_case_def",concl boolTheory.literal_case_DEF)
val res = export(``!f x. literal_case f x = f x``,
  rpt gen_tac >> CONV_TAC(PATH_CONV"lrll"(REWR_CONV def)) >>
  CONV_TAC(RATOR_CONV(RAND_CONV (RATOR_CONV BETA_CONV THENC BETA_CONV))) >>
  REFL_TAC);

val _ = OpenTheory_const_name{
  const={Thy=Thy,Name="LET"},
  name=(["Data","Bool"],"let")}
val def = new_definition("LET",concl boolTheory.LET_DEF)
val res = export(``!f x. LET f x = f x``,
  rpt gen_tac >> CONV_TAC(PATH_CONV"lrll"(REWR_CONV def)) >>
  CONV_TAC(RATOR_CONV(RAND_CONV (RATOR_CONV BETA_CONV THENC BETA_CONV))) >>
  REFL_TAC);

val _ = OpenTheory_const_name{
  const={Thy=Thy,Name="TYPE_DEFINITION"},
  name=(["HOL4"],"TYPE_DEFINITION")}
val def = new_definition("TYPE_DEFINITION",concl boolTheory.TYPE_DEFINITION)
val res13 = export(``!P rep. TYPE_DEFINITION P rep <=> ^(rhs(concl(SPEC_ALL boolTheory.TYPE_DEFINITION_THM)))``,
  rpt gen_tac >> CONV_TAC(PATH_CONV"lrll"(REWR_CONV def)) >>
  CONV_TAC(RATOR_CONV(RAND_CONV (RATOR_CONV BETA_CONV THENC BETA_CONV))) >>
  REFL_TAC);

val res = export(``(~A ==> F) ==> (A ==> F) ==> F``,
  CONV_TAC(PATH_CONV"lr"(REWR_CONV res9)) >>
  disch_then(fn th => CONV_TAC(RAND_CONV(REWR_CONV(SYM th)))) >>
  CONV_TAC(PATH_CONV"rl" (REWR_CONV OTbool132)) >>
  CONV_TAC(RAND_CONV BETA_CONV) >>
  disch_then ACCEPT_TAC)

val res = export(``!f g. (f = g) <=> !x. (f x = g x)``,
  ACCEPT_TAC(GSYM OTbool49))
  (* DB.match["OpenTheoryBool"]``!x. f x = g x`` *)

val res = export(``!t1 t2. ((if T then t1 else t2) = t1) ∧ ((if F then t1 else t2) = t2)``,
  rpt gen_tac >> ACCEPT_TAC (CONJ (SPEC_ALL OTbool75) (SPEC_ALL OTbool76)))
  (* DB.match["OpenTheoryBool"]``if a then b else c`` *)

val res = export(``(!t. ~~t <=> t) ∧ (~T <=> F) /\ (~F <=> T)``,
  ACCEPT_TAC (LIST_CONJ[OTbool110,OTbool134,OTbool135]))
  (* DB.match["OpenTheoryBool"]``~~ t <=> t`` *)
  (* DB.match["OpenTheoryBool"]``~T <=> F`` *)
  (* DB.match["OpenTheoryBool"]``~F <=> T`` *)

val res = export(``!t.
       ((T <=> t) <=> t) /\ ((t <=> T) <=> t) /\ ((F <=> t) <=> ~t) /\
       ((t <=> F) <=> ~t)``,
  ACCEPT_TAC (GEN_ALL(LIST_CONJ(map SPEC_ALL [OTbool107,OTbool106,OTbool104,OTbool105]))))
  (* DB.match["OpenTheoryBool"]``T = t`` *)
  (* DB.match["OpenTheoryBool"]``t = T`` *)
  (* DB.match["OpenTheoryBool"]``F = t`` *)
  (* DB.match["OpenTheoryBool"]``t = F`` *)

val res = export(``!t.
       (T /\ t <=> t) /\ (t /\ T <=> t) /\ (F /\ t <=> F) /\
       (t /\ F <=> F) /\ (t /\ t <=> t)``,
  ACCEPT_TAC (GEN_ALL(LIST_CONJ(map SPEC_ALL [OTbool102,OTbool100,OTbool103,OTbool101,OTbool99]))))
  (* DB.match["OpenTheoryBool"]``T ∧ t`` *)
  (* DB.match["OpenTheoryBool"]``t ∧ T`` *)
  (* DB.match["OpenTheoryBool"]``F ∧ t`` *)
  (* DB.match["OpenTheoryBool"]``t ∧ F`` *)
  (* DB.match["OpenTheoryBool"]``t ∧ t = t`` *)

val res = export(``!t.
       (T \/ t <=> T) /\ (t \/ T <=> T) /\ (F \/ t <=> t) /\
       (t \/ F <=> t) /\ (t \/ t <=> t)``,
  ACCEPT_TAC (GEN_ALL(LIST_CONJ(map SPEC_ALL [OTbool93,OTbool91,OTbool94,OTbool92,OTbool90]))))
  (* DB.match["OpenTheoryBool"]``T ∨ t`` *)
  (* DB.match["OpenTheoryBool"]``t ∨ T`` *)
  (* DB.match["OpenTheoryBool"]``F ∨ t`` *)
  (* DB.match["OpenTheoryBool"]``t ∨ F`` *)
  (* DB.match["OpenTheoryBool"]``t ∨ t = t`` *)

val res = export(``!t.
       (T ==> t <=> t) /\ (t ==> T <=> T) /\ (F ==> t <=> T) /\
       (t ==> t <=> T) /\ (t ==> F <=> ~t)``,
  ACCEPT_TAC (GEN_ALL(LIST_CONJ(map SPEC_ALL [OTbool97,OTbool96,OTbool98,
    EQ_MP (Q.SPEC`t ==> t`res3) (SPEC_ALL OTbool84), OTbool95]))))
  (* DB.match["OpenTheoryBool"]``T ⇒ t`` *)
  (* DB.match["OpenTheoryBool"]``t ⇒ T`` *)
  (* DB.match["OpenTheoryBool"]``F ⇒ t`` *)
  (* DB.match["OpenTheoryBool"]``t ⇒ t`` *)
  (* DB.match["OpenTheoryBool"]``t ⇒ F`` *)

val res = export(``~(t /\ ~t)``,
  CONV_TAC(REWR_CONV OTbool51) >>
  MATCH_ACCEPT_TAC OTbool82)
  (* DB.match["OpenTheoryBool"]``~(t /\ q)`` *)
  (* DB.match["OpenTheoryBool"]``t \/ ~t`` *)

val res = export(``!t. ~t ==> t ==> F``,
  gen_tac >>
  CONV_TAC(LAND_CONV(REWR_CONV(GSYM OTbool95))) >>
  MATCH_ACCEPT_TAC OTbool84)
  (* DB.match["OpenTheoryBool"]``t ==> F`` *)
  (* DB.match["OpenTheoryBool"]``t ==> t`` *)

val res = export(``!t. (t ==> F) ==> ~t``,
  gen_tac >>
  CONV_TAC(RAND_CONV(REWR_CONV(GSYM OTbool95))) >>
  MATCH_ACCEPT_TAC OTbool84)

val res = export(``!f b x y. f (if b then x else y) = if b then f x else f y``,
  rpt gen_tac >>
  MATCH_ACCEPT_TAC OTbool6);
  (* DB.match["OpenTheoryBool"]``if x then y else z`` *)

val res = export(``(!(t1:'a) t2. (if T then t1 else t2) = t1) /\
                    !(t1:'a) t2. (if F then t1 else t2) = t2``,
  ACCEPT_TAC(CONJ OTbool75 OTbool76));
  (* DB.match["OpenTheoryBool"]``if x then y else z`` *)

val res = export(``!A B. A ==> B <=> ~A \/ B``,
  rpt gen_tac >>
  qspec_then`A`strip_assume_tac OTbool81 >>
  first_assum(fn th => PURE_REWRITE_TAC [th]) >>
  PURE_REWRITE_TAC[OTbool134,OTbool135,OTbool93,OTbool94,OTbool97,OTbool98] >>
  REFL_TAC )
  (* DB.match["OpenTheoryBool"]``A <=> T`` *)
  (* DB.match["OpenTheoryBool"]``T ==> t`` *)
  (* DB.match["OpenTheoryBool"]``F ==> t`` *)
  (* DB.match["OpenTheoryBool"]``~T`` *)
  (* DB.match["OpenTheoryBool"]``~F`` *)
  (* DB.match["OpenTheoryBool"]``F ∨ b`` *)
  (* DB.match["OpenTheoryBool"]``T ∨ b`` *)

val res = export(``(x ==> y) /\ (z ==> w) ==> x /\ z ==> y /\ w``,
  MATCH_ACCEPT_TAC OTbool3)

val res = export(``(x ==> y) /\ (z ==> w) ==> x \/ z ==> y \/ w``,
  MATCH_ACCEPT_TAC OTbool2)

val res = export(``!t1 t2 t3. t1 /\ t2 /\ t3 <=> (t1 /\ t2) /\ t3``,
  MATCH_ACCEPT_TAC(GSYM OTbool14))
  (* DB.match["OpenTheoryBool"]``a /\ b /\ c`` *)

val res = export(``!A B C. A \/ B \/ C <=> (A \/ B) \/ C``,
  MATCH_ACCEPT_TAC(GSYM OTbool11))
  (* DB.match["OpenTheoryBool"]``a \/ b \/ c`` *)

val res = export(``!Q P. (!e. P e \/ Q) <=> (!x. P x) \/ Q``,
  MATCH_ACCEPT_TAC OTbool40)
  (* DB.match["OpenTheoryBool"]``P e \/ Q`` *)

val res = export(``!t1 t2. (t1 <=> t2) <=> t1 /\ t2 \/ ~t1 /\ ~t2``,
  rpt gen_tac >>
  qspec_then`t1`strip_assume_tac OTbool81 >>
  first_assum(fn th => PURE_REWRITE_TAC[th]) >>
  PURE_REWRITE_TAC[OTbool107,OTbool102,OTbool104,OTbool103,OTbool134,OTbool135,OTbool94,OTbool92] >>
  REFL_TAC)
  (* DB.match["OpenTheoryBool"]``T <=> t`` *)
  (* DB.match["OpenTheoryBool"]``F <=> t`` *)
  (* DB.match["OpenTheoryBool"]``T /\ t`` *)
  (* DB.match["OpenTheoryBool"]``F /\ t`` *)
  (* DB.match["OpenTheoryBool"]``~T`` *)
  (* DB.match["OpenTheoryBool"]``F \/ t`` *)
  (* DB.match["OpenTheoryBool"]``t \/ F`` *)

val res = export(``!A B C. B /\ C \/ A <=> (B \/ A) /\ (C \/ A)``,
  MATCH_ACCEPT_TAC OTbool10)
  (* DB.match["OpenTheoryBool"]``b /\ c \/ a`` *)

val res = export(``(?!x. P x) <=> ((?x. P x) /\ !x y. P x /\ P y ==> (x = y))``,
  Q.ISPEC_THEN`P`MATCH_ACCEPT_TAC OTbool86)
  (* DB.match["OpenTheoryBool"]``?!x. P x`` *)

val res = export(``(!x. P x ==> Q x) ==> (?x. P x) ==> ?x. Q x``,
  MATCH_ACCEPT_TAC OTbool21)

val res = export(``
  !P Q.
    ((?x. P x) ==> Q <=> !x. P x ==> Q) /\
    ((?x. P x) /\ Q <=> ?x. P x /\ Q) /\
    (Q /\ (?x. P x) <=> ?x. Q /\ P x)``,
  rpt gen_tac >>
  conj_tac >- MATCH_ACCEPT_TAC OTbool55 >>
  conj_tac >- MATCH_ACCEPT_TAC (GSYM OTbool36) >>
  MATCH_ACCEPT_TAC OTbool69)
  (* DB.match["OpenTheoryBool"]``(?x. P x) ==> Q`` *)
  (* DB.match["OpenTheoryBool"]``(?x. P x) /\ Q`` *)
  (* DB.match["OpenTheoryBool"]``Q /\ (?x. P x)`` *)

val res = export(
  ``!x x' y y'.
      (x <=> x') /\ (x' ==> (y <=> y')) ==> (x ==> y <=> x' ==> y')``,
  rpt gen_tac >>
  PURE_REWRITE_TAC[GSYM OTbool17] >>
  disch_then(fn th => PURE_REWRITE_TAC[th]) >>
  qspec_then`x'`strip_assume_tac OTbool81 >>
  pop_assum(fn th => PURE_REWRITE_TAC[th]) >>
  PURE_REWRITE_TAC[OTbool97,OTbool98] >>
  TRY(disch_then ACCEPT_TAC) >> REFL_TAC)
  (* DB.match["OpenTheoryBool"]``(p1 ==> p2) <=> p3`` *)
  (* DB.match["OpenTheoryBool"]``T ==> t`` *)
  (* DB.match["OpenTheoryBool"]``F ==> t`` *)

val res = export(``!A B. (~(A /\ B) <=> ~A \/ ~B) /\ (~(A \/ B) <=> ~A /\ ~B)``,
  rpt gen_tac >>
  conj_tac >- MATCH_ACCEPT_TAC OTbool51 >>
  MATCH_ACCEPT_TAC OTbool50)
  (* DB.match["OpenTheoryBool"]``~(a /\ b)`` *)
  (* DB.match["OpenTheoryBool"]``~(a \/ b)`` *)

val res8' = CONV_RULE(STRIP_QUANT_CONV(REWR_CONV OTbool17))res8

val res = export(``!t1 t2. (t1 <=> t2) <=> (t1 ==> t2) /\ (t2 ==> t1)``,
  rpt gen_tac >>
  match_mp_tac res8' >>
  reverse conj_tac >- MATCH_ACCEPT_TAC res8' >>
  disch_then(fn th => ACCEPT_TAC(CONJ
    (MATCH_MP OTbool27 th)
    (MATCH_MP OTbool27 (SYM th) ))))
  (* DB.match["OpenTheoryBool"]``(t1 <=> t2) ==> t3`` *)

val res = export(``
    !P.
      (?(rep:'b -> 'a). TYPE_DEFINITION P rep) ==>
      ?(rep:'b -> 'a) abs. (!a. (abs (rep a) = a)) /\ !r. (P r <=> (rep (abs r) = r))``,
  gen_tac >>
  ho_match_mp_tac OTbool21 >>
  gen_tac >>
  CONV_TAC(LAND_CONV(REWR_CONV res13)) >>
  strip_tac >>
  qexists_tac`λra. @a. rep a = ra` >>
  conj_tac >- (
    CONV_TAC (QUANT_CONV(LAND_CONV BETA_CONV)) >>
    gen_tac >>
    ho_match_mp_tac OTbool23 >>
    gen_tac >>
    match_mp_tac res8' >>
    conj_tac >- first_assum MATCH_ACCEPT_TAC >>
    disch_then(fn th => PURE_REWRITE_TAC[th]) >>
    REFL_TAC ) >>
  gen_tac >>
  CONV_TAC(PATH_CONV"rlrr"BETA_CONV) >>
  match_mp_tac res8' >>
  pop_assum(fn th => PURE_REWRITE_TAC[th]) >>
  conj_tac >- (
    CONV_TAC(HO_REWR_CONV OTbool55) >>
    CONV_TAC(QUANT_CONV(LAND_CONV SYM_CONV)) >>
    Q.ISPEC_THEN`λa. rep a = r`(MATCH_ACCEPT_TAC o BETA_RULE) OTbool29 ) >>
  disch_then(fn th => CONV_TAC(QUANT_CONV(LAND_CONV(REWR_CONV(SYM th))))) >>
  qexists_tac`@a. rep a = r` >>
  REFL_TAC)
  (* DB.match["OpenTheoryBool"]``$@`` *)
  (* DB.match["OpenTheoryBool"]``p ==> q ==> r`` *)

val res = export(``
  !P Q x x' y y'.
    (P <=> Q) /\ (Q ==> (x = x')) /\ (~Q ==> (y = y')) ==>
    ((if P then x else y) = if Q then x' else y')``,
  rpt gen_tac >>
  qspec_then`P`strip_assume_tac OTbool81 >>
  first_assum(fn th => PURE_REWRITE_TAC [th]) >>
  qspec_then`Q`strip_assume_tac OTbool81 >>
  first_assum(fn th => PURE_REWRITE_TAC [th]) >>
  PURE_REWRITE_TAC[OTbool107,OTbool104,OTbool75,OTbool76,OTbool134,OTbool135,OTbool102,OTbool103,OTbool97,OTbool98,OTbool100] >>
  disch_then ACCEPT_TAC )
  (* DB.match["OpenTheoryBool"]``F ⇔ t`` *)
  (* DB.match["OpenTheoryBool"]``T ⇔ t`` *)
  (* DB.match["OpenTheoryBool"]``T ⇒ t`` *)
  (* DB.match["OpenTheoryBool"]``F ⇒ t`` *)
  (* DB.match["OpenTheoryBool"]``T ∧ t`` *)
  (* DB.match["OpenTheoryBool"]``t ∧ T`` *)
  (* DB.match["OpenTheoryBool"]``F ∧ t`` *)
  (* DB.match["OpenTheoryBool"]``~T`` *)
  (* DB.match["OpenTheoryBool"]``~F`` *)
  (* DB.match["OpenTheoryBool"]``if T then x else y`` *)
  (* DB.match["OpenTheoryBool"]``if F then x else y`` *)

val _ = export_theory()
