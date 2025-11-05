let _wallust_preview name =
  Unix.open_process_in (Printf.sprintf "wallust theme %s --preview" name)

let remove_parentheticals line =
  if String.contains line '(' then
    String.split_on_char '(' line |> fun slist -> List.nth slist 0
  else line

let wallust_themes () =
  let cmd = "wallust theme list" in
  let ic = Unix.open_process_in cmd in
  let line = In_channel.input_all ic in
  let _ = Unix.close_process_in ic in
  let content = line |> String.split_on_char '\n' in
  (* Remove " - <theme name>" *)
  let stripped =
    List.map
      (fun line ->
        let len = String.length line in
        if len > 1 then String.sub line 1 (len - 1) else "" )
      content
  in
  (* Remove parenthesis after <random> and <list> options *)
  let no_parenth =
    List.map
      (fun l ->
        let no_parenth = remove_parentheticals l |> String.trim in
        no_parenth )
      stripped
  in
  let only_theme_names =
    List.filter_map
      (fun l ->
        let avail_themes_regex = Str.regexp_string "Available themes:" in
        let extra_regex = Str.regexp_string "Extra:" in
        if
          Str.string_match avail_themes_regex l 0
          || Str.string_match extra_regex l 0
        then None
        else Some l )
      no_parenth
  in
  only_theme_names

let get_16_colors_ansi theme_name =
  let args = [|"wallust"; "theme"; theme_name; "--preview"|] in
  let ic = Unix.open_process_args_in "wallust" args in
  let line = In_channel.input_all ic in
  let _ = Unix.close_process_in ic in
  let content = line in
  content

(* Given a single character with esacpe sequences *)
let format_rgb raw =
  let split = String.split_on_char ';' raw in
  let r = List.nth split 2 in
  let g = List.nth split 3 in
  let b =
    List.nth split 4 |> String.split_on_char 'm' |> fun l -> List.nth l 0
  in
  Printf.sprintf "%s %s %s" r g b

let _debug_print_themes () =
  List.iter (fun l -> Printf.printf "%s" l) (wallust_themes ())

let print_all_theme_names () =
  let themes = wallust_themes () in
  List.iter
    (fun theme_name ->
      let raw = get_16_colors_ansi theme_name in
      let escape_seq_regex = Str.regexp "\027\\[[0-9;]*m" in
      let escape_sequences =
        Str.full_split escape_seq_regex raw
        |> List.filter_map (function
             | Str.Delim s ->
                 Some s
             | Str.Text _ ->
                 None )
      in
      let colors_escape_sequences =
        List.filter_map
          (fun l -> if String.equal l "\027[49m" then None else Some l)
          escape_sequences
      in
      let rgbs = List.map (fun l -> format_rgb l) colors_escape_sequences in
      Printf.printf "Theme: %s\n" theme_name ;
      List.iter (fun c -> Printf.printf "  %s\n" c) rgbs )
    themes

let print_single_theme_name theme_name =
  let raw = get_16_colors_ansi theme_name in
  let escape_seq_regex = Str.regexp "\027\\[[0-9;]*m" in
  let escape_sequences =
    Str.full_split escape_seq_regex raw
    |> List.filter_map (function Str.Delim s -> Some s | Str.Text _ -> None)
  in
  let colors_escape_sequences =
    List.filter_map
      (fun l -> if String.equal l "\027[49m" then None else Some l)
      escape_sequences
  in
  let rgbs = List.map (fun l -> format_rgb l) colors_escape_sequences in
  Printf.printf "%s\n" theme_name ;
  List.iter (fun c -> Printf.printf "%s\n" c) rgbs

(* let () = _print_single_theme_name "Ayu-Dark" *)

let () =
  let usage_msg = "wallust-theme-rgb [<theme-name> | all | help]" in
  match Array.to_list Sys.argv with
  | [_] ->
      Printf.printf "%s\n" usage_msg
  | [_; "all"] ->
      print_all_theme_names ()
  | [_; "help"] ->
      Printf.printf "%s\n" usage_msg
  | [_; theme_name] ->
      print_single_theme_name theme_name
  | _ ->
      Printf.eprintf "Error: too many arguments\n%s\n" usage_msg ;
      exit 1
