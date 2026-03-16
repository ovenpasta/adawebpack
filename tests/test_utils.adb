with Interfaces;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

package body Test_Utils is

   procedure Gnat_Put_Exception
     (Address : System.Address;
      Size    : Interfaces.Unsigned_32;
      Line    : Interfaces.Unsigned_32)
     with Export, Convention => C, Link_Name => "__gnat_put_exception";

   procedure Gnat_Put_Exception
     (Address : System.Address;
      Size    : Interfaces.Unsigned_32;
      Line    : Interfaces.Unsigned_32) is null;

   function Puts (S : Interfaces.C.Strings.chars_ptr) return Interfaces.C.int
     with Import, Convention => C, External_Name => "puts";

   procedure Print (S : String) is
      CS     : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (S);
      Ignore : Interfaces.C.int;
   begin
      Ignore := Puts (CS);
      Interfaces.C.Strings.Free (CS);
   end Print;

   procedure Pass (Name : String) is
   begin
      Print (Name & ": PASS");
   end Pass;

   procedure Fail (Name : String; Reason : String := "") is
   begin
      if Reason = "" then
         Print (Name & ": FAIL");
      else
         Print (Name & ": FAIL (" & Reason & ")");
      end if;
   end Fail;

   procedure Check
     (Name      : String;
      Condition : Boolean;
      Reason    : String := "")
   is
   begin
      if Condition then
         Pass (Name);
      else
         Fail (Name, Reason);
      end if;
   end Check;

end Test_Utils;
