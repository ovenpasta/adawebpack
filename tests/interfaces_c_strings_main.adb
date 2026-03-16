--  Focused test for Interfaces.C.Strings.New_String on wasm32.
--
--  Verifies that Ada strings converted via New_String arrive at a C function
--  as valid null-terminated char * values with the correct length:
--
--    1. a compile-time string literal
--    2. a dynamically constructed string (Integer'Image concatenation)
--    3. repeated calls to check for memory / lifetime issues

with Interfaces.C;        use Interfaces.C;
with Interfaces.C.Strings;
with Test_Utils;

procedure Interfaces_C_Strings_Main is

   function Check_C (Text : Interfaces.C.Strings.chars_ptr)
     return Interfaces.C.int
     with Import, Convention => C,
          External_Name => "interfaces_c_strings_check";

   --  Test 1: static string literal
   S1 : Interfaces.C.Strings.chars_ptr :=
     Interfaces.C.Strings.New_String ("hello");
   L1 : Interfaces.C.int;

   --  Test 2: dynamically built string using Integer'Image
   N      : constant Integer := 42;
   S2_Ada : constant String  := "value=" & Integer'Image (N);
   S2     : Interfaces.C.Strings.chars_ptr :=
     Interfaces.C.Strings.New_String (S2_Ada);
   L2 : Interfaces.C.int;

   --  Test 3: empty string edge case
   S3 : Interfaces.C.Strings.chars_ptr :=
     Interfaces.C.Strings.New_String ("");
   L3 : Interfaces.C.int;

   --  Test 4: repeated New_String / Free to check for heap corruption
   Tmp : Interfaces.C.Strings.chars_ptr;

begin
   --  Test 1
   L1 := Check_C (S1);
   Interfaces.C.Strings.Free (S1);
   Test_Utils.Check ("c_strings static",  L1 = 5,
                     "expected 5, got" & Interfaces.C.int'Image (L1));

   --  Test 2: "value= 42" - Integer'Image includes a leading space
   L2 := Check_C (S2);
   Interfaces.C.Strings.Free (S2);
   Test_Utils.Check ("c_strings dynamic", L2 = int (S2_Ada'Length),
                     "expected" & Integer'Image (S2_Ada'Length)
                     & ", got" & Interfaces.C.int'Image (L2));

   --  Test 3
   L3 := Check_C (S3);
   Interfaces.C.Strings.Free (S3);
   Test_Utils.Check ("c_strings empty",   L3 = 0,
                     "expected 0, got" & Interfaces.C.int'Image (L3));

   --  Test 4: ten rounds of allocate -> pass -> free
   declare
      All_Ok : Boolean := True;
   begin
      for I in 1 .. 10 loop
         declare
            Label : constant String := "round" & Integer'Image (I);
         begin
            Tmp := Interfaces.C.Strings.New_String (Label);
            if Check_C (Tmp) /= int (Label'Length) then
               All_Ok := False;
            end if;
            Interfaces.C.Strings.Free (Tmp);
         end;
      end loop;
      Test_Utils.Check ("c_strings loop", All_Ok);
   end;

end Interfaces_C_Strings_Main;
