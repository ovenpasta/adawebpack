--  Requires -sASYNCIFY at emcc link time for actual sleep.
--  Without it emscripten_thread_sleep busy-waits, blocking the browser.
with Ada.Calendar;  use Ada.Calendar;
with Test_Utils;

procedure Delay_Main is
   T1      : Time;
   T2      : Time;
   Elapsed : Duration;
begin
   T1 := Clock;
   delay 0.1;
   T2 := Clock;
   Elapsed := T2 - T1;

   --  50 ms lower bound: generous tolerance for timer resolution
   Test_Utils.Check ("delay >= 50ms", Elapsed >= 0.05);
   --  5 s upper bound: sanity check
   Test_Utils.Check ("delay < 5s",    Elapsed < 5.0);
end Delay_Main;
