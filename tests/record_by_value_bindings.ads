with Interfaces.C;

package Record_By_Value_Bindings is

   subtype Sint is Interfaces.C.int;

   type Int_Pair is record
      A : aliased Sint;
      B : aliased Sint;
   end record
   with Convention => C_Pass_By_Copy;

   function Record_By_Value_Call (Value : Int_Pair) return Sint
     with Import => True,
          Convention => C,
          External_Name => "record_by_value_call";

   function Record_By_Value_Return (A, B : Sint) return Int_Pair
     with Import => True,
          Convention => C,
          External_Name => "record_by_value_return";

end Record_By_Value_Bindings;
