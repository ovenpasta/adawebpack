with SDL3_Bindings;
with System;

package Basic_App is

   procedure Run;

   function SDL_App_Init
     (Appstate : System.Address;
      Argc     : SDL3_Bindings.Sint;
      Argv     : System.Address) return SDL3_Bindings.SDL_App_Result
     with Convention => C,
          Export => True,
          External_Name => "SDL_AppInit";

   function SDL_App_Iterate
     (Appstate : System.Address) return SDL3_Bindings.SDL_App_Result
     with Convention => C,
          Export => True,
          External_Name => "SDL_AppIterate";

   function SDL_App_Event
     (Appstate : System.Address;
      Event    : access SDL3_Bindings.SDL_Event) return SDL3_Bindings.SDL_App_Result
     with Convention => C,
          Export => True,
          External_Name => "SDL_AppEvent";

   procedure SDL_App_Quit
     (Appstate : System.Address;
      Result   : SDL3_Bindings.SDL_App_Result)
     with Convention => C,
          Export => True,
          External_Name => "SDL_AppQuit";

end Basic_App;
