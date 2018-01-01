(* ========================================================================== *)
(* FILE          : hhsRedirect.sml                                            *)
(* DESCRIPTION   : Redirecting standard output to a file using the Posix      *)
(* facilities in the SML Basis Library. Implements a stack of output files.   *)
(* AUTHOR        : (c) Rob Arthan 2008. Edited by Thibault Gauthier 2017.     *)
(* DATE          : 2017                                                       *)
(* ========================================================================== *)

structure hhsRedirect :> hhsRedirect = 
struct

open HolKernel boolLib Posix.IO Posix.FileSys TextIO

val ERR = mk_HOL_ERR "hhsRedirect"

(* --------------------------------------------------------------------------
   Take a duplicate of current stdout.
   Create an initially empty stack of file descriptors.
   -------------------------------------------------------------------------- *)

val duplicate_stdout : file_desc = dup stdout
val stack : file_desc list ref = ref []

(* --------------------------------------------------------------------------
   File creation mode: read/write for user, group and others,
   but bits set with umask(1) will be cleared as usual.
   -------------------------------------------------------------------------- *)
   
val rw_rw_rw = S.flags[S.irusr, S.iwusr, S.irgrp,S.iwgrp, S.iroth, S.iwoth]

(* --------------------------------------------------------------------------
   push_out_file: start a new output file, stacking the file descriptor.
   -------------------------------------------------------------------------- *)
   
fun push_output_file {name: string, append : bool} =
  let 
    val flags = if append then O.append else O.trunc
    val fd = createf(name, O_WRONLY, flags, rw_rw_rw)
  in 
    (dup2{old = fd, new = stdout}; stack := fd :: !stack)
  end

(* --------------------------------------------------------------------------
   pop_output_file: 
   close file descriptor at top of stack and
   revert to previous; returns true if the output file stack
   is not empty on exit, so you can close all open output files
   and clear the stack with:
   while pop_output_file() do ();
   -------------------------------------------------------------------------- *)

fun pop_output_file () = 
  (
  (case !stack of
   cur_fd :: rest => (close cur_fd; stack := rest) 
   | [] => ())
  ;
  (case !stack of
    fd :: _ => (dup2{old = fd, new = stdout}; true) 
  | []      => (dup2{old = duplicate_stdout, new = stdout}; false))
  )

val in_flag = ref false

fun hide_in_file file f x = 
  (
  if !in_flag then raise ERR "hide" "recursive hiding" else ();
  in_flag := true;
  push_output_file {name=file, append=false};
    (
    let val r = f x in (pop_output_file (); in_flag := false; r) end
    handle e => (pop_output_file (); in_flag := false; raise e)
    )
  )
  
end
