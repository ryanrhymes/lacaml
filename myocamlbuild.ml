(* OASIS_START *)
(* DO NOT EDIT (digest: d33b258b53cbd5661e1d8ea343c6c5ac) *)
module OASISGettext = struct
(* # 22 "src/oasis/OASISGettext.ml" *)


  let ns_ str =
    str


  let s_ str =
    str


  let f_ (str: ('a, 'b, 'c, 'd) format4) =
    str


  let fn_ fmt1 fmt2 n =
    if n = 1 then
      fmt1^^""
    else
      fmt2^^""


  let init =
    []


end

module OASISString = struct
(* # 22 "src/oasis/OASISString.ml" *)


  (** Various string utilities.

      Mostly inspired by extlib and batteries ExtString and BatString libraries.

      @author Sylvain Le Gall
    *)


  let nsplitf str f =
    if str = "" then
      []
    else
      let buf = Buffer.create 13 in
      let lst = ref [] in
      let push () =
        lst := Buffer.contents buf :: !lst;
        Buffer.clear buf
      in
      let str_len = String.length str in
        for i = 0 to str_len - 1 do
          if f str.[i] then
            push ()
          else
            Buffer.add_char buf str.[i]
        done;
        push ();
        List.rev !lst


  (** [nsplit c s] Split the string [s] at char [c]. It doesn't include the
      separator.
    *)
  let nsplit str c =
    nsplitf str ((=) c)


  let find ~what ?(offset=0) str =
    let what_idx = ref 0 in
    let str_idx = ref offset in
      while !str_idx < String.length str &&
            !what_idx < String.length what do
        if str.[!str_idx] = what.[!what_idx] then
          incr what_idx
        else
          what_idx := 0;
        incr str_idx
      done;
      if !what_idx <> String.length what then
        raise Not_found
      else
        !str_idx - !what_idx


  let sub_start str len =
    let str_len = String.length str in
    if len >= str_len then
      ""
    else
      String.sub str len (str_len - len)


  let sub_end ?(offset=0) str len =
    let str_len = String.length str in
    if len >= str_len then
      ""
    else
      String.sub str 0 (str_len - len)


  let starts_with ~what ?(offset=0) str =
    let what_idx = ref 0 in
    let str_idx = ref offset in
    let ok = ref true in
      while !ok &&
            !str_idx < String.length str &&
            !what_idx < String.length what do
        if str.[!str_idx] = what.[!what_idx] then
          incr what_idx
        else
          ok := false;
        incr str_idx
      done;
      if !what_idx = String.length what then
        true
      else
        false


  let strip_starts_with ~what str =
    if starts_with ~what str then
      sub_start str (String.length what)
    else
      raise Not_found


  let ends_with ~what ?(offset=0) str =
    let what_idx = ref ((String.length what) - 1) in
    let str_idx = ref ((String.length str) - 1) in
    let ok = ref true in
      while !ok &&
            offset <= !str_idx &&
            0 <= !what_idx do
        if str.[!str_idx] = what.[!what_idx] then
          decr what_idx
        else
          ok := false;
        decr str_idx
      done;
      if !what_idx = -1 then
        true
      else
        false


  let strip_ends_with ~what str =
    if ends_with ~what str then
      sub_end str (String.length what)
    else
      raise Not_found


  let replace_chars f s =
    let buf = Buffer.create (String.length s) in
    String.iter (fun c -> Buffer.add_char buf (f c)) s;
    Buffer.contents buf

  let lowercase_ascii =
    replace_chars
      (fun c ->
         if (c >= 'A' && c <= 'Z') then
           Char.chr (Char.code c + 32)
         else
           c)

  let uncapitalize_ascii s =
    if s <> "" then
      (lowercase_ascii (String.sub s 0 1)) ^ (String.sub s 1 ((String.length s) - 1))
    else
      s

  let uppercase_ascii =
    replace_chars
      (fun c ->
         if (c >= 'a' && c <= 'z') then
           Char.chr (Char.code c - 32)
         else
           c)

  let capitalize_ascii s =
    if s <> "" then
      (uppercase_ascii (String.sub s 0 1)) ^ (String.sub s 1 ((String.length s) - 1))
    else
      s

end

module OASISExpr = struct
(* # 22 "src/oasis/OASISExpr.ml" *)





  open OASISGettext


  type test = string


  type flag = string


  type t =
    | EBool of bool
    | ENot of t
    | EAnd of t * t
    | EOr of t * t
    | EFlag of flag
    | ETest of test * string



  type 'a choices = (t * 'a) list


  let eval var_get t =
    let rec eval' =
      function
        | EBool b ->
            b

        | ENot e ->
            not (eval' e)

        | EAnd (e1, e2) ->
            (eval' e1) && (eval' e2)

        | EOr (e1, e2) ->
            (eval' e1) || (eval' e2)

        | EFlag nm ->
            let v =
              var_get nm
            in
              assert(v = "true" || v = "false");
              (v = "true")

        | ETest (nm, vl) ->
            let v =
              var_get nm
            in
              (v = vl)
    in
      eval' t


  let choose ?printer ?name var_get lst =
    let rec choose_aux =
      function
        | (cond, vl) :: tl ->
            if eval var_get cond then
              vl
            else
              choose_aux tl
        | [] ->
            let str_lst =
              if lst = [] then
                s_ "<empty>"
              else
                String.concat
                  (s_ ", ")
                  (List.map
                     (fun (cond, vl) ->
                        match printer with
                          | Some p -> p vl
                          | None -> s_ "<no printer>")
                     lst)
            in
              match name with
                | Some nm ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for the choice list '%s': %s")
                         nm str_lst)
                | None ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for a choice list: %s")
                         str_lst)
    in
      choose_aux (List.rev lst)


end


# 292 "myocamlbuild.ml"
module BaseEnvLight = struct
(* # 22 "src/base/BaseEnvLight.ml" *)


  module MapString = Map.Make(String)


  type t = string MapString.t


  let default_filename =
    Filename.concat
      (Sys.getcwd ())
      "setup.data"


  let load ?(allow_empty=false) ?(filename=default_filename) () =
    if Sys.file_exists filename then
      begin
        let chn =
          open_in_bin filename
        in
        let st =
          Stream.of_channel chn
        in
        let line =
          ref 1
        in
        let st_line =
          Stream.from
            (fun _ ->
               try
                 match Stream.next st with
                   | '\n' -> incr line; Some '\n'
                   | c -> Some c
               with Stream.Failure -> None)
        in
        let lexer =
          Genlex.make_lexer ["="] st_line
        in
        let rec read_file mp =
          match Stream.npeek 3 lexer with
            | [Genlex.Ident nm; Genlex.Kwd "="; Genlex.String value] ->
                Stream.junk lexer;
                Stream.junk lexer;
                Stream.junk lexer;
                read_file (MapString.add nm value mp)
            | [] ->
                mp
            | _ ->
                failwith
                  (Printf.sprintf
                     "Malformed data file '%s' line %d"
                     filename !line)
        in
        let mp =
          read_file MapString.empty
        in
          close_in chn;
          mp
      end
    else if allow_empty then
      begin
        MapString.empty
      end
    else
      begin
        failwith
          (Printf.sprintf
             "Unable to load environment, the file '%s' doesn't exist."
             filename)
      end


  let rec var_expand str env =
    let buff =
      Buffer.create ((String.length str) * 2)
    in
      Buffer.add_substitute
        buff
        (fun var ->
           try
             var_expand (MapString.find var env) env
           with Not_found ->
             failwith
               (Printf.sprintf
                  "No variable %s defined when trying to expand %S."
                  var
                  str))
        str;
      Buffer.contents buff


  let var_get name env =
    var_expand (MapString.find name env) env


  let var_choose lst env =
    OASISExpr.choose
      (fun nm -> var_get nm env)
      lst
end


# 397 "myocamlbuild.ml"
module MyOCamlbuildFindlib = struct
(* # 22 "src/plugins/ocamlbuild/MyOCamlbuildFindlib.ml" *)


  (** OCamlbuild extension, copied from
    * http://brion.inria.fr/gallium/index.php/Using_ocamlfind_with_ocamlbuild
    * by N. Pouillard and others
    *
    * Updated on 2009/02/28
    *
    * Modified by Sylvain Le Gall
    *)
  open Ocamlbuild_plugin

  type conf =
    { no_automatic_syntax: bool;
    }

  (* these functions are not really officially exported *)
  let run_and_read =
    Ocamlbuild_pack.My_unix.run_and_read


  let blank_sep_strings =
    Ocamlbuild_pack.Lexers.blank_sep_strings


  let exec_from_conf exec =
    let exec =
      let env_filename = Pathname.basename BaseEnvLight.default_filename in
      let env = BaseEnvLight.load ~filename:env_filename ~allow_empty:true () in
      try
        BaseEnvLight.var_get exec env
      with Not_found ->
        Printf.eprintf "W: Cannot get variable %s\n" exec;
        exec
    in
    let fix_win32 str =
      if Sys.os_type = "Win32" then begin
        let buff = Buffer.create (String.length str) in
        (* Adapt for windowsi, ocamlbuild + win32 has a hard time to handle '\\'.
         *)
        String.iter
          (fun c -> Buffer.add_char buff (if c = '\\' then '/' else c))
          str;
        Buffer.contents buff
      end else begin
        str
      end
    in
      fix_win32 exec

  let split s ch =
    let buf = Buffer.create 13 in
    let x = ref [] in
    let flush () =
      x := (Buffer.contents buf) :: !x;
      Buffer.clear buf
    in
      String.iter
        (fun c ->
           if c = ch then
             flush ()
           else
             Buffer.add_char buf c)
        s;
      flush ();
      List.rev !x


  let split_nl s = split s '\n'


  let before_space s =
    try
      String.before s (String.index s ' ')
    with Not_found -> s

  (* ocamlfind command *)
  let ocamlfind x = S[Sh (exec_from_conf "ocamlfind"); x]

  (* This lists all supported packages. *)
  let find_packages () =
    List.map before_space (split_nl & run_and_read (exec_from_conf "ocamlfind" ^ " list"))


  (* Mock to list available syntaxes. *)
  let find_syntaxes () = ["camlp4o"; "camlp4r"]


  let well_known_syntax = [
    "camlp4.quotations.o";
    "camlp4.quotations.r";
    "camlp4.exceptiontracer";
    "camlp4.extend";
    "camlp4.foldgenerator";
    "camlp4.listcomprehension";
    "camlp4.locationstripper";
    "camlp4.macro";
    "camlp4.mapgenerator";
    "camlp4.metagenerator";
    "camlp4.profiler";
    "camlp4.tracer"
  ]


  let dispatch conf =
    function
      | After_options ->
          (* By using Before_options one let command line options have an higher
           * priority on the contrary using After_options will guarantee to have
           * the higher priority override default commands by ocamlfind ones *)
          Options.ocamlc     := ocamlfind & A"ocamlc";
          Options.ocamlopt   := ocamlfind & A"ocamlopt";
          Options.ocamldep   := ocamlfind & A"ocamldep";
          Options.ocamldoc   := ocamlfind & A"ocamldoc";
          Options.ocamlmktop := ocamlfind & A"ocamlmktop";
          Options.ocamlmklib := ocamlfind & A"ocamlmklib"

      | After_rules ->

          (* When one link an OCaml library/binary/package, one should use
           * -linkpkg *)
          flag ["ocaml"; "link"; "program"] & A"-linkpkg";

          if not (conf.no_automatic_syntax) then begin
            (* For each ocamlfind package one inject the -package option when
             * compiling, computing dependencies, generating documentation and
             * linking. *)
            List.iter
              begin fun pkg ->
                let base_args = [A"-package"; A pkg] in
                (* TODO: consider how to really choose camlp4o or camlp4r. *)
                let syn_args = [A"-syntax"; A "camlp4o"] in
                let (args, pargs) =
                  (* Heuristic to identify syntax extensions: whether they end in
                     ".syntax"; some might not.
                  *)
                  if Filename.check_suffix pkg "syntax" ||
                     List.mem pkg well_known_syntax then
                    (syn_args @ base_args, syn_args)
                  else
                    (base_args, [])
                in
                flag ["ocaml"; "compile";  "pkg_"^pkg] & S args;
                flag ["ocaml"; "ocamldep"; "pkg_"^pkg] & S args;
                flag ["ocaml"; "doc";      "pkg_"^pkg] & S args;
                flag ["ocaml"; "link";     "pkg_"^pkg] & S base_args;
                flag ["ocaml"; "infer_interface"; "pkg_"^pkg] & S args;

                (* TODO: Check if this is allowed for OCaml < 3.12.1 *)
                flag ["ocaml"; "compile";  "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "ocamldep"; "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "doc";      "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "infer_interface"; "package("^pkg^")"] & S pargs;
              end
              (find_packages ());
          end;

          (* Like -package but for extensions syntax. Morover -syntax is useless
           * when linking. *)
          List.iter begin fun syntax ->
          flag ["ocaml"; "compile";  "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "ocamldep"; "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "doc";      "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "infer_interface"; "syntax_"^syntax] &
                S[A"-syntax"; A syntax];
          end (find_syntaxes ());

          (* The default "thread" tag is not compatible with ocamlfind.
           * Indeed, the default rules add the "threads.cma" or "threads.cmxa"
           * options when using this tag. When using the "-linkpkg" option with
           * ocamlfind, this module will then be added twice on the command line.
           *
           * To solve this, one approach is to add the "-thread" option when using
           * the "threads" package using the previous plugin.
           *)
          flag ["ocaml"; "pkg_threads"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "pkg_threads"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "infer_interface"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "package(threads)"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "infer_interface"] (S[A "-thread"]);

      | _ ->
          ()
end

module MyOCamlbuildBase = struct
(* # 22 "src/plugins/ocamlbuild/MyOCamlbuildBase.ml" *)


  (** Base functions for writing myocamlbuild.ml
      @author Sylvain Le Gall
    *)





  open Ocamlbuild_plugin
  module OC = Ocamlbuild_pack.Ocaml_compiler


  type dir = string
  type file = string
  type name = string
  type tag = string


(* # 62 "src/plugins/ocamlbuild/MyOCamlbuildBase.ml" *)


  type t =
      {
        lib_ocaml: (name * dir list * string list) list;
        lib_c:     (name * dir * file list) list;
        flags:     (tag list * (spec OASISExpr.choices)) list;
        (* Replace the 'dir: include' from _tags by a precise interdepends in
         * directory.
         *)
        includes:  (dir * dir list) list;
      }


  let env_filename =
    Pathname.basename
      BaseEnvLight.default_filename


  let dispatch_combine lst =
    fun e ->
      List.iter
        (fun dispatch -> dispatch e)
        lst


  let tag_libstubs nm =
    "use_lib"^nm^"_stubs"


  let nm_libstubs nm =
    nm^"_stubs"


  let dispatch t e =
    let env =
      BaseEnvLight.load
        ~filename:env_filename
        ~allow_empty:true
        ()
    in
      match e with
        | Before_options ->
            let no_trailing_dot s =
              if String.length s >= 1 && s.[0] = '.' then
                String.sub s 1 ((String.length s) - 1)
              else
                s
            in
              List.iter
                (fun (opt, var) ->
                   try
                     opt := no_trailing_dot (BaseEnvLight.var_get var env)
                   with Not_found ->
                     Printf.eprintf "W: Cannot get variable %s\n" var)
                [
                  Options.ext_obj, "ext_obj";
                  Options.ext_lib, "ext_lib";
                  Options.ext_dll, "ext_dll";
                ]

        | After_rules ->
            (* Declare OCaml libraries *)
            List.iter
              (function
                 | nm, [], intf_modules ->
                     ocaml_lib nm;
                     let cmis =
                       List.map (fun m -> (OASISString.uncapitalize_ascii m) ^ ".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^nm^".cma"] cmis
                 | nm, dir :: tl, intf_modules ->
                     ocaml_lib ~dir:dir (dir^"/"^nm);
                     List.iter
                       (fun dir ->
                          List.iter
                            (fun str ->
                               flag ["ocaml"; "use_"^nm; str] (S[A"-I"; P dir]))
                            ["compile"; "infer_interface"; "doc"])
                       tl;
                     let cmis =
                       List.map (fun m -> dir^"/"^(OASISString.uncapitalize_ascii m)^".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^dir^"/"^nm^".cma"]
                         cmis)
              t.lib_ocaml;

            (* Declare directories dependencies, replace "include" in _tags. *)
            List.iter
              (fun (dir, include_dirs) ->
                 Pathname.define_context dir include_dirs)
              t.includes;

            (* Declare C libraries *)
            List.iter
              (fun (lib, dir, headers) ->
                   (* Handle C part of library *)
                   flag ["link"; "library"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("-l"^(nm_libstubs lib)); A"-cclib";
                        A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "library"; "ocaml"; "native"; tag_libstubs lib]
                     (S[A"-cclib"; A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "program"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("dll"^(nm_libstubs lib))]);

                   (* When ocaml link something that use the C library, then one
                      need that file to be up to date.
                      This holds both for programs and for libraries.
                    *)
       dep ["link"; "ocaml"; "program"; tag_libstubs lib]
  		     [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

       dep  ["compile"; "ocaml"; "program"; tag_libstubs lib]
  		      [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

                   (* TODO: be more specific about what depends on headers *)
                   (* Depends on .h files *)
                   dep ["compile"; "c"]
                     headers;

                   (* Setup search path for lib *)
                   flag ["link"; "ocaml"; "use_"^lib]
                     (S[A"-I"; P(dir)]);
              )
              t.lib_c;

              (* Add flags *)
              List.iter
              (fun (tags, cond_specs) ->
                 let spec = BaseEnvLight.var_choose cond_specs env in
                 let rec eval_specs =
                   function
                     | S lst -> S (List.map eval_specs lst)
                     | A str -> A (BaseEnvLight.var_expand str env)
                     | spec -> spec
                 in
                   flag tags & (eval_specs spec))
              t.flags
        | _ ->
            ()


  let dispatch_default conf t =
    dispatch_combine
      [
        dispatch t;
        MyOCamlbuildFindlib.dispatch conf;
      ]


end


# 766 "myocamlbuild.ml"
open Ocamlbuild_plugin;;
let package_default =
  {
     MyOCamlbuildBase.lib_ocaml =
       [("lacaml", ["lib"], []); ("lacaml_top", ["lib"], [])];
     lib_c =
       [
          ("lacaml",
            "lib",
            ["lib/f2c.h"; "lib/lacaml_macros.h"; "lib/utils_c.h"])
       ];
     flags =
       [
          (["oasis_library_lacaml_ccopt"; "compile"],
            [
               (OASISExpr.EBool true, S []);
               (OASISExpr.ETest ("system", "mingw64"),
                 S
                   [A "-ccopt"; A "-DEXTERNAL_EXP10"; A "-ccopt"; A "-DWIN32"
                   ]);
               (OASISExpr.ETest ("system", "macosx"),
                 S [A "-ccopt"; A "-DEXTERNAL_EXP10"]);
               (OASISExpr.EAnd
                  (OASISExpr.ETest ("system", "macosx"),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EFlag "strict",
                    OASISExpr.ETest ("ccomp_type", "cc")),
                 S
                   [
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EFlag "strict",
                       OASISExpr.ETest ("ccomp_type", "cc")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EFlag "strict",
                       OASISExpr.ETest ("ccomp_type", "cc")),
                    OASISExpr.ETest ("system", "macosx")),
                 S
                   [
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EAnd
                        (OASISExpr.EFlag "strict",
                          OASISExpr.ETest ("ccomp_type", "cc")),
                       OASISExpr.ETest ("system", "macosx")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EOr
                  (OASISExpr.ETest ("system", "linux"),
                    OASISExpr.ETest ("system", "linux_elf")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EOr
                     (OASISExpr.ETest ("system", "linux"),
                       OASISExpr.ETest ("system", "linux_elf")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EOr
                     (OASISExpr.ETest ("system", "linux"),
                       OASISExpr.ETest ("system", "linux_elf")),
                    OASISExpr.ETest ("system", "macosx")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf")),
                       OASISExpr.ETest ("system", "macosx")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EOr
                     (OASISExpr.ETest ("system", "linux"),
                       OASISExpr.ETest ("system", "linux_elf")),
                    OASISExpr.EAnd
                      (OASISExpr.EFlag "strict",
                        OASISExpr.ETest ("ccomp_type", "cc"))),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf")),
                       OASISExpr.EAnd
                         (OASISExpr.EFlag "strict",
                           OASISExpr.ETest ("ccomp_type", "cc"))),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf")),
                       OASISExpr.EAnd
                         (OASISExpr.EFlag "strict",
                           OASISExpr.ETest ("ccomp_type", "cc"))),
                    OASISExpr.ETest ("system", "macosx")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EAnd
                        (OASISExpr.EOr
                           (OASISExpr.ETest ("system", "linux"),
                             OASISExpr.ETest ("system", "linux_elf")),
                          OASISExpr.EAnd
                            (OASISExpr.EFlag "strict",
                              OASISExpr.ETest ("ccomp_type", "cc"))),
                       OASISExpr.ETest ("system", "macosx")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=gnu99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.ENot
                  (OASISExpr.EOr
                     (OASISExpr.ETest ("system", "linux"),
                       OASISExpr.ETest ("system", "linux_elf"))),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.ENot
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf"))),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.ENot
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf"))),
                    OASISExpr.ETest ("system", "macosx")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.ENot
                        (OASISExpr.EOr
                           (OASISExpr.ETest ("system", "linux"),
                             OASISExpr.ETest ("system", "linux_elf"))),
                       OASISExpr.ETest ("system", "macosx")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.ENot
                     (OASISExpr.EOr
                        (OASISExpr.ETest ("system", "linux"),
                          OASISExpr.ETest ("system", "linux_elf"))),
                    OASISExpr.EAnd
                      (OASISExpr.EFlag "strict",
                        OASISExpr.ETest ("ccomp_type", "cc"))),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.ENot
                        (OASISExpr.EOr
                           (OASISExpr.ETest ("system", "linux"),
                             OASISExpr.ETest ("system", "linux_elf"))),
                       OASISExpr.EAnd
                         (OASISExpr.EFlag "strict",
                           OASISExpr.ETest ("ccomp_type", "cc"))),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.ENot
                        (OASISExpr.EOr
                           (OASISExpr.ETest ("system", "linux"),
                             OASISExpr.ETest ("system", "linux_elf"))),
                       OASISExpr.EAnd
                         (OASISExpr.EFlag "strict",
                           OASISExpr.ETest ("ccomp_type", "cc"))),
                    OASISExpr.ETest ("system", "macosx")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EAnd
                        (OASISExpr.ENot
                           (OASISExpr.EOr
                              (OASISExpr.ETest ("system", "linux"),
                                OASISExpr.ETest ("system", "linux_elf"))),
                          OASISExpr.EAnd
                            (OASISExpr.EFlag "strict",
                              OASISExpr.ETest ("ccomp_type", "cc"))),
                       OASISExpr.ETest ("system", "macosx")),
                    OASISExpr.ETest ("system", "mingw64")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-std=c99";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DEXTERNAL_EXP10";
                      A "-ccopt";
                      A "-DWIN32"
                   ])
            ]);
          (["oasis_library_lacaml_cclib"; "link"],
            [
               (OASISExpr.EBool true,
                 S [A "-cclib"; A "-lblas"; A "-cclib"; A "-llapack"]);
               (OASISExpr.ETest ("system", "macosx"),
                 S [A "-cclib"; A "-framework"; A "-cclib"; A "Accelerate"])
            ]);
          (["oasis_library_lacaml_cclib"; "ocamlmklib"; "c"],
            [
               (OASISExpr.EBool true, S [A "-lblas"; A "-llapack"]);
               (OASISExpr.ETest ("system", "macosx"),
                 S [A "-framework"; A "Accelerate"])
            ])
       ];
     includes =
       [
          ("examples/svd", ["lib"]);
          ("examples/shuffle", ["lib"]);
          ("examples/schur", ["lib"]);
          ("examples/qr", ["lib"]);
          ("examples/nag", ["lib"]);
          ("examples/lin_reg", ["lib"]);
          ("examples/lin_eq_comp", ["lib"]);
          ("examples/lin_eq", ["lib"]);
          ("examples/eig", ["lib"]);
          ("examples/blas", ["lib"])
       ]
  }
  ;;

let conf = {MyOCamlbuildFindlib.no_automatic_syntax = false}

let dispatch_default = MyOCamlbuildBase.dispatch_default conf package_default;;

# 1377 "myocamlbuild.ml"
(* OASIS_STOP *)

let rec split_on is_delim s i0 i i1 =
  if i >= i1 then [String.sub s i0 (i1 - i0)]
  else if is_delim s.[i] then
    String.sub s i0 (i - i0) :: skip is_delim s (i + 1) i1
  else
    split_on is_delim s i0 (i + 1) i1
and skip is_delim s i i1 =
  if i >= i1 then []
  else if is_delim s.[i] then skip is_delim s (i + 1) i1
  else split_on is_delim s i (i + 1) i1

let split_on_spaces s = skip (fun c -> c = ' ') s 0 (String.length s)
let split_on_tabs s = skip (fun c -> c = '\t') s 0 (String.length s)

let env = BaseEnvLight.load() (* setup.data *)
let ocamlfind = BaseEnvLight.var_get "ocamlfind" env
let stdlib = BaseEnvLight.var_get "standard_library" env

let a l = List.map (fun s -> A s) l
let conf_ccopt = a(split_on_tabs(BaseEnvLight.var_get "conf_ccopt" env))
let conf_cclib = a(split_on_tabs(BaseEnvLight.var_get "conf_cclib" env))

let replace1 want_tags spec ((tags, specs) as ts) =
  let all_tags = List.fold_left (fun a t -> a && List.mem t tags) true want_tags in
  if all_tags then (tags, [(OASISExpr.EBool true, S spec)])
  else ts

let replace tags spec l = List.map (replace1 tags spec) l

let prefix_each p l =
  List.fold_right (fun a l' -> p :: a :: l') l []

let package_default =
  (* Act on conf.ml *)
  let flags = package_default.MyOCamlbuildBase.flags in
  let flags = match conf_ccopt with
    | [] -> flags
    | _ -> replace ["oasis_library_lacaml_ccopt"]
                  (prefix_each (A "-ccopt") conf_ccopt) flags in
  let flags = match conf_cclib with
    | [] -> flags
    | _ ->
      let flags = replace ["oasis_library_lacaml_cclib"; "ocamlmklib"]
                          conf_cclib flags in
      replace ["oasis_library_lacaml_cclib"; "link"]
              (prefix_each (A "-cclib") conf_cclib) flags in
  { package_default with MyOCamlbuildBase.flags = flags }

let () =
  let additional_rules = function
    | After_rules ->
        pflag ["compile"; "ocaml"] "I" (fun x -> S [A "-I"; A x]);

        (* Files included, tailored with macros. *)
        dep ["compile"; "c"]
          [
            "lib"/"fold_col.c"; "lib"/"fold2_col.c";
            "lib"/"mat_fold.c"; "lib"/"mat_fold2.c";
            "lib"/"mat_map.c"; "lib"/"mat_combine.c";
            "lib"/"vec_map.c"; "lib"/"vec_combine.c"; "lib"/"vec_sort.c";
          ];

        (* Special rules for precision dependent C code. *)
        let lacaml_cc desc ~prod ~dep flags =
          rule ("Lacaml: " ^ desc) ~prod ~dep
              (fun env _build ->
                let f = env dep and o = env prod in
                let tags = tags_of_pathname f ++ "compile" ++ "c"
                          ++ "oasis_library_lacaml_ccopt" in

                let add_ccopt f l = A"-ccopt" :: f :: l in
                let flags = List.fold_right add_ccopt flags [] in
                (* unfortunately -o is not respected for C files, use -ccopt. *)
                let cmd = [A ocamlfind; A"ocamlc"; A"-ccopt"; A("-o " ^ o)]
                          @ flags @ [T tags; A"-c"; P f] in
                Seq[Cmd(S(cmd))]
              ) in
        lacaml_cc "simple of SD" ~prod:"%2_S_c.o" ~dep:"%_SD_c.c" [];
        lacaml_cc "double of SD" ~prod:"%2_D_c.o" ~dep:"%_SD_c.c"
                  [A"-DLACAML_DOUBLE"];
        lacaml_cc "simple of CZ" ~prod:"%2_C_c.o" ~dep:"%_CZ_c.c"
                  [A"-DLACAML_COMPLEX"];
        lacaml_cc "double of CZ" ~prod:"%2_Z_c.o" ~dep:"%_CZ_c.c"
                  [A"-DLACAML_COMPLEX"; A"-DLACAML_DOUBLE"];

        lacaml_cc "simple of SDCZ" ~prod:"%4_S_c.o" ~dep:"%_SDCZ_c.c" [];
        lacaml_cc "double of SDCZ" ~prod:"%4_D_c.o" ~dep:"%_SDCZ_c.c"
                  [A"-DLACAML_DOUBLE"];
        lacaml_cc "complex32 of SDCZ" ~prod:"%4_C_c.o" ~dep:"%_SDCZ_c.c"
                  [A"-DLACAML_COMPLEX"];
        lacaml_cc "complex64 of SDCZ" ~prod:"%4_Z_c.o" ~dep:"%_SDCZ_c.c"
                  [A"-DLACAML_COMPLEX"; A"-DLACAML_DOUBLE"];

    | _ -> ()
  in
  dispatch (
    MyOCamlbuildBase.dispatch_combine [dispatch_default; additional_rules])
