with Ada.Calendar;  use Ada.Calendar;
with Test_Utils;

procedure Calendar_Main is
   T1      : Time;
   T2      : Time;
   Elapsed : Duration;
begin
   T1 := Clock;
   T2 := Clock;
   Elapsed := T2 - T1;

   Test_Utils.Check
     ("cal year ok",
      Year (T1) in 2020 .. 2100,
      "year = " & Integer'Image (Year (T1)));
   Test_Utils.Check ("cal monotonic",    T2 >= T1);
   Test_Utils.Check ("cal elapsed >= 0", Elapsed >= 0.0);
end Calendar_Main;
