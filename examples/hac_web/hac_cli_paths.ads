--  Search-path-aware file catalogue for the wasm HAC CLI driver.
--
--  HAC's native command-line tool provides this behaviour in the
--  Path_Management package nested in src/apps/hac_pkg.adb, but the surrounding
--  HAC_Pkg body imports Ada.Exceptions.Exception_Message, which cannot compile
--  under the wasm runtime's pragma Restrictions (No_Exception_Propagation).
--  This is a standalone copy of just the path-management catalogue so the
--  driver can resolve with'd units reached through -I switches and
--  "--!hac_add_to_path" directives (both exercised by the Advent of Code
--  regression tests) without pulling in the incompatible parts of HAC_Pkg.

with HAC_Sys.Files,
     HAC_Sys.Files.Default;

with HAT;

package HAC_CLI_Paths is

   type File_Catalogue is
     limited new HAC_Sys.Files.Default.File_Catalogue with
   record
      extra_path     : HAT.VString;  --  -I dirs and --!hac_add_to_path dirs
      main_file_name : HAT.VString;  --  the main source file on the command line
   end record;

   procedure Set_Main_File (cat : in out File_Catalogue; name : String);

   overriding function Exists
     (cat : File_Catalogue; name : String) return Boolean;

   overriding function Full_Source_Name
     (cat : File_Catalogue; name : String) return String;

   overriding function Is_Open
     (cat : File_Catalogue; name : String) return Boolean;

   overriding procedure Source_Open
     (cat    : in out File_Catalogue;
      name   : in     String;
      stream :    out HAC_Sys.Files.Root_Stream_Class_Access);

   overriding procedure Skip_Shebang
     (cat            : in out File_Catalogue;
      name           : in     String;
      shebang_offset :    out Natural);

   overriding procedure Close (cat : in out File_Catalogue; name : String);

   overriding procedure Add_to_Source_Path
     (cat : in out File_Catalogue; new_dir : String);

end HAC_CLI_Paths;
