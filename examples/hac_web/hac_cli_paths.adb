--  See hac_cli_paths.ads. The search order mirrors HAC_Pkg.Path_Management
--  (src/apps/hac_pkg.adb), which itself follows GNAT's RTL search rules.

with Ada.Directories;

package body HAC_CLI_Paths is

   procedure Set_Main_File (cat : in out File_Catalogue; name : String) is
   begin
      cat.main_file_name := HAT.To_VString (name);
   end Set_Main_File;

   overriding function Exists
     (cat : File_Catalogue; name : String) return Boolean is
   begin
      return Full_Source_Name (cat, name) /= "";
   end Exists;

   overriding function Full_Source_Name
     (cat : File_Catalogue; name : String) return String
   is
      use Ada.Directories;
   begin
      --  0) The file name as such exists (relative to the current directory).
      if HAC_Sys.Files.Default.File_Catalogue (cat).Exists (name) then
         return name;
      end if;
      --  1) The directory containing the main unit's source file.
      if HAT.Length (cat.main_file_name) > 0 then
         declare
            fn : constant String :=
              Containing_Directory (HAT.To_String (cat.main_file_name)) &
              HAT.Directory_Separator & name;
         begin
            if Exists (fn) and then Kind (fn) = Ordinary_File then
               return fn;
            end if;
         exception
            when others => null;  --  Continue searching elsewhere.
         end;
      end if;
      --  2) Directories from -I switches and "--!hac_add_to_path" directives.
      declare
         fn : constant String :=
           HAT.Search_File (name, HAT.To_String (cat.extra_path));
      begin
         if fn /= "" then
            return fn;
         end if;
      end;
      --  3) Directories in the ADA_INCLUDE_PATH environment variable.
      declare
         fn : constant String :=
           HAT.Search_File (name, HAT.To_String (HAT.Get_Env ("ADA_INCLUDE_PATH")));
      begin
         if fn /= "" then
            return fn;
         end if;
      end;
      return "";
   end Full_Source_Name;

   overriding function Is_Open
     (cat : File_Catalogue; name : String) return Boolean is
   begin
      return HAC_Sys.Files.Default.File_Catalogue (cat).Is_Open
               (Full_Source_Name (cat, name));
   end Is_Open;

   overriding procedure Source_Open
     (cat    : in out File_Catalogue;
      name   : in     String;
      stream :    out HAC_Sys.Files.Root_Stream_Class_Access)
   is
      ffn : constant String := Full_Source_Name (cat, name);
   begin
      if ffn = "" then
         raise Ada.Directories.Name_Error;
      else
         HAC_Sys.Files.Default.File_Catalogue (cat).Source_Open (ffn, stream);
      end if;
   end Source_Open;

   overriding procedure Skip_Shebang
     (cat            : in out File_Catalogue;
      name           : in     String;
      shebang_offset :    out Natural) is
   begin
      HAC_Sys.Files.Default.File_Catalogue (cat).Skip_Shebang
        (Full_Source_Name (cat, name), shebang_offset);
   end Skip_Shebang;

   overriding procedure Close (cat : in out File_Catalogue; name : String) is
   begin
      HAC_Sys.Files.Default.File_Catalogue (cat).Close
        (Full_Source_Name (cat, name));
   end Close;

   overriding procedure Add_to_Source_Path
     (cat : in out File_Catalogue; new_dir : String)
   is
      use HAT;
   begin
      cat.extra_path := cat.extra_path & ';' & new_dir;
   end Add_to_Source_Path;

end HAC_CLI_Paths;
