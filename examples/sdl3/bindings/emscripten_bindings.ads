package Emscripten_Bindings is

   procedure Emscripten_Exit_With_Live_Runtime
     with Import => True,
          Convention => C,
          External_Name => "emscripten_exit_with_live_runtime",
          No_Return => True;

end Emscripten_Bindings;
