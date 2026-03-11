------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--               ADA.NUMERICS.BIG_NUMBERS.BIG_INTEGERS_GHOST                --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant: provides trivial bodies for the non-imported generic
--  subprograms.  Everything is Ghost and erased at runtime.

pragma Assertion_Policy (Ghost => Ignore);

package body Ada.Numerics.Big_Numbers.Big_Integers_Ghost with
   SPARK_Mode => Off
is

   package body Signed_Conversions is

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
         pragma Unreferenced (Arg);
      begin
         return (null record);
      end To_Big_Integer;

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
         pragma Unreferenced (Arg);
      begin
         return Int'First;
      end From_Big_Integer;

   end Signed_Conversions;

   package body Unsigned_Conversions is

      function To_Big_Integer (Arg : Int) return Valid_Big_Integer is
         pragma Unreferenced (Arg);
      begin
         return (null record);
      end To_Big_Integer;

      function From_Big_Integer (Arg : Valid_Big_Integer) return Int is
         pragma Unreferenced (Arg);
      begin
         return Int'First;
      end From_Big_Integer;

   end Unsigned_Conversions;

end Ada.Numerics.Big_Numbers.Big_Integers_Ghost;
