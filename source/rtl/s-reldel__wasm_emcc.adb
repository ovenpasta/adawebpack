------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--                S Y S T E M . R E L A T I V E _ D E L A Y S               --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--  WASM32 / Emscripten variant.                                            --
--                                                                          --
--  Delegates to System.OS_Primitives.Timed_Delay which calls nanosleep.   --
--  With -sASYNCIFY at emcc link time, nanosleep yields to the browser      --
--  event loop; without it, it busy-waits (blocks the browser thread).     --
--                                                                          --
------------------------------------------------------------------------------

with System.OS_Primitives;

package body System.Relative_Delays is

   procedure Delay_For (D : Duration) is
   begin
      System.OS_Primitives.Timed_Delay (D, System.OS_Primitives.Relative);
   end Delay_For;

end System.Relative_Delays;
