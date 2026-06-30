--  Minimal command-line front end for HAC, built for wasm32.
--
--  Linked with -sNODERAWFS=1 (see the Makefile) this behaves like the native
--  `hac` binary for the purpose of HAC's own regression harness
--  (test/all_silent_tests): it takes an Ada source file as its first
--  non-option argument, compiles and runs it, makes the remaining arguments
--  visible to the running HAC program (Argument_Shift = file_pos), and exits
--  with a failure status if the build fails or the HAC VM reports an unhandled
--  exception. Any exit status the HAC program sets itself
--  (Ada.Command_Line.Set_Exit_Status, used by the Advent-of-Code self-checking
--  tests) flows through to the process exit code.
--
--  Supported options (a subset of the native tool's, enough for the suite):
--    -c       compile only (no run); used by the remarks regression test.
--    -r...    enable/disable remarks (warnings or notes); -r0..-r3 set a level,
--             -rk/-rr/-ru/-rv enable a kind, uppercase disables it.
--    -I<dir>  add <dir> to the source search path.
--  The "--!hac_add_to_path <dir>" source directive is honoured too, through the
--  search-path-aware catalogue in HAC_CLI_Paths (needed by the AoC tests, whose
--  shared aoc_toolbox unit lives one directory above the per-year sources).
--
--  This deliberately avoids HAC's full CLI (src/apps/hac.adb + hac_pkg.adb),
--  whose post-mortem reporting uses Ada.Exceptions.Exception_Message and a
--  choice-parameter handler that cannot compile under the wasm runtime's
--  pragma Restrictions (No_Exception_Propagation).

with HAC_Sys.Builder,
     HAC_Sys.Co_Defs,
     HAC_Sys.Defs,
     HAC_Sys.PCode.Interpreter;

with HAC_CLI_Paths;

with HAT;

with Ada.Command_Line,
     Ada.Text_IO;

procedure HAC_CLI_Main is

  use Ada.Command_Line, Ada.Text_IO;

  compile_only : Boolean := False;
  remarks      : HAC_Sys.Defs.Remark_Set := HAC_Sys.Defs.default_remarks;
  search_path  : String (1 .. 4096);
  search_last  : Natural := 0;

  procedure Append_Path (dir : String) is
  begin
     if search_last > 0 then
        search_last := search_last + 1;
        search_path (search_last) := ';';
     end if;
     search_path (search_last + 1 .. search_last + dir'Length) := dir;
     search_last := search_last + dir'Length;
  end Append_Path;

  procedure Process_Remarks (opt : String) is
     use HAC_Sys.Defs;
  begin
     for letter in opt'First + 1 .. opt'Last loop
        if opt (letter) in '0' .. '3' then
           remarks := preset_remarks (Remark_Level'Value (opt (letter .. letter)));
        else
           for r in Compile_Remark loop
              if remark_letter (r) = opt (letter) then
                 remarks (r) := True;
              elsif HAT.To_Upper (remark_letter (r)) = opt (letter) then
                 remarks (r) := False;
              end if;
           end loop;
        end if;
     end loop;
  end Process_Remarks;

  file_pos : Natural := 0;

  procedure Show_Line_Information
    (File_Name   : String;
     Block_Name  : String;
     Line_Number : Positive)
  is
  begin
     Put_Line
       (Standard_Error,
        File_Name & ": " & Block_Name & " at line" &
        Integer'Image (Line_Number));
  end Show_Line_Information;

  procedure Trace_Back is
    new HAC_Sys.PCode.Interpreter.Show_Trace_Back (Show_Line_Information);

begin
  --  Parse leading options up to the first non-option (the source file).
  for I in 1 .. Argument_Count loop
     declare
        arg : constant String := Argument (I);
     begin
        if arg'Length = 0 or else arg (arg'First) /= '-' then
           file_pos := I;
           exit;
        end if;
        declare
           opt : constant String := arg (arg'First + 1 .. arg'Last);
        begin
           if opt'Length >= 1 then
              case opt (opt'First) is
                 when 'c'    => compile_only := True;
                 when 'r'    => Process_Remarks (opt);
                 when 'I'    => Append_Path (opt (opt'First + 1 .. opt'Last));
                 when others => null;  --  Other options are ignored.
              end case;
           end if;
        end;
     end;
  end loop;

  if file_pos = 0 then
     Put_Line (Standard_Error, "Usage: hac [options] <source.adb> [args...]");
     Set_Exit_Status (Failure);
     return;
  end if;

  declare
     file           : constant String := Argument (file_pos);
     BD             : HAC_Sys.Builder.Build_Data;
     cat            : aliased HAC_CLI_Paths.File_Catalogue;
     source_stream  : HAC_Sys.Co_Defs.Source_Stream_Access;
     shebang_offset : Natural := 0;
     post_mortem    : HAC_Sys.PCode.Interpreter.Post_Mortem_Data;
  begin
     cat.Set_Main_File (file);
     if search_last > 0 then
        cat.Add_to_Source_Path (search_path (1 .. search_last));
     end if;
     cat.Source_Open (file, source_stream);
     cat.Skip_Shebang (file, shebang_offset);
     BD.Set_Remark_Set (remarks);
     BD.Set_Main_Source_Stream (source_stream, file, shebang_offset);
     BD.Set_File_Catalogue (cat'Unchecked_Access);
     BD.Build_Main;
     cat.Close (file);

     if not BD.Build_Successful then
        Put_Line (Standard_Error, "Errors found, build failed.");
        Set_Exit_Status (Failure);
        return;
     end if;

     if compile_only then
        return;
     end if;

     --  Argument_Shift = file_pos: the HAC program's Argument (1) maps to this
     --  process's Argument (file_pos + 1), i.e. the first argument after the
     --  source file (matching the native `hac` command behaviour).
     HAC_Sys.PCode.Interpreter.Interpret_on_Current_IO
       (BD, file_pos, file, post_mortem);

     if HAC_Sys.PCode.Interpreter.Is_Exception_Raised (post_mortem.Unhandled)
     then
        Put_Line
          (Standard_Error,
           "HAC VM: raised " &
           HAC_Sys.PCode.Interpreter.Image (post_mortem.Unhandled));
        Put_Line
          (Standard_Error,
           HAC_Sys.PCode.Interpreter.Message (post_mortem.Unhandled));
        Put_Line (Standard_Error, "Trace-back: approximate location");
        Trace_Back (post_mortem.Unhandled);
        Set_Exit_Status (Failure);
     end if;
  end;
end HAC_CLI_Main;
