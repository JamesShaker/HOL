signature mlTacticData =
sig

  include Abbrev

  (* term data (can be useful for other purposes) *)
  val export_terml : string -> term list -> unit
  val import_terml : string -> term list

  (* tactic data *)
  type lbl = (string * real * goal * goal list)
  type fea = int list
  type tacdata =
    {
    tacfea : (lbl,fea) Redblackmap.dict,
    tacfea_cthy : (lbl,fea) Redblackmap.dict,
    taccov : (string, int) Redblackmap.dict,
    tacdep : (goal, lbl list) Redblackmap.dict
    }
  val empty_tacdata : tacdata

  val export_tacfea : string -> (lbl,fea) Redblackmap.dict -> unit
  val import_tacfea : string -> (lbl,fea) Redblackmap.dict
  val import_tacdata : string list -> tacdata

  (* tactictoe database *)
  val ttt_tacdata_dir : string
  val exists_tacdata_thy : string -> bool
  val ttt_create_tacdata : unit -> tacdata
  val ttt_update_tacdata : (lbl * tacdata) -> tacdata
  val ttt_export_tacdata : string -> tacdata -> unit



end
