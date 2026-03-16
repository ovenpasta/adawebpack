with Record_By_Value_Bindings;
with Test_Utils;

procedure Record_By_Value_Main is

   --  Test pass: Ada passes record to C; expected 7 + 4 = 11
   Call_Result : constant Integer :=
     Integer
       (Record_By_Value_Bindings.Record_By_Value_Call
          ((A => 7, B => 4)));

   --  Test return: C returns record to Ada; expected {A => 3, B => 5}
   --  then pass back to verify fields: 3 + 5 = 8
   Ret_Pair   : constant Record_By_Value_Bindings.Int_Pair :=
     Record_By_Value_Bindings.Record_By_Value_Return (3, 5);
   Ret_Result : constant Integer :=
     Integer (Record_By_Value_Bindings.Record_By_Value_Call (Ret_Pair));

begin
   Test_Utils.Check ("record_by_value pass", Call_Result = 11,
                     "got" & Integer'Image (Call_Result) & ", expected 11");
   Test_Utils.Check ("record_by_value return", Ret_Result = 8,
                     "got" & Integer'Image (Ret_Result) & ", expected 8");
end Record_By_Value_Main;
