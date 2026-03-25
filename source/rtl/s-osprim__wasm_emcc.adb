------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--                  S Y S T E M . O S _ P R I M I T I V E S                 --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--  WASM32 / Emscripten variant.                                            --
--                                                                          --
--  Clock uses clock_gettime (CLOCK_REALTIME) from Emscripten libc.         --
--  Timed_Delay is a no-op: WASM is single-threaded, cannot block.          --
--                                                                          --
------------------------------------------------------------------------------

with System.CRTL;
with System.C_Time;
with System.OS_Constants;

package body System.OS_Primitives is

   subtype int is System.CRTL.int;

   -----------
   -- Clock --
   -----------

   function Clock return Duration is
      TS     : aliased C_Time.timespec;
      Result : int;

      type clockid_t is new int;
      CLOCK_REALTIME : constant clockid_t :=
         System.OS_Constants.CLOCK_REALTIME;

      function clock_gettime
        (clock_id : clockid_t;
         tp       : access C_Time.timespec) return int;
      pragma Import (C, clock_gettime, "clock_gettime");

   begin
      Result := clock_gettime (CLOCK_REALTIME, TS'Unchecked_Access);
      pragma Assert (Result = 0);
      return C_Time.To_Duration (TS);
   end Clock;

   -----------------
   -- Timed_Delay --
   -----------------

   procedure Timed_Delay
     (Time : Duration;
      Mode : Integer)
   is
      pragma Unreferenced (Time, Mode);
   begin
      null;
   end Timed_Delay;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      null;
   end Initialize;

end System.OS_Primitives;
