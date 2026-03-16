package Test_Utils is

   procedure Pass (Name : String);
   --  Print "<Name>: PASS" to stdout.

   procedure Fail (Name : String; Reason : String := "");
   --  Print "<Name>: FAIL [<Reason>]" to stdout.

   procedure Check
     (Name      : String;
      Condition : Boolean;
      Reason    : String := "");
   --  Print PASS if Condition, FAIL otherwise.

end Test_Utils;
