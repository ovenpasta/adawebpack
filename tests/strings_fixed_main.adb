with Ada.Strings;
with Ada.Strings.Fixed;

procedure Strings_Fixed_Main is
   Value : constant String :=
     Ada.Strings.Fixed.Trim ("  wasm32  ", Ada.Strings.Both);
begin
   if Value /= "wasm32" then
      raise Program_Error;
   end if;
end Strings_Fixed_Main;
