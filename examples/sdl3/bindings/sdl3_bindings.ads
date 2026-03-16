with Interfaces;
with Interfaces.C;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with System;

package SDL3_Bindings is

   subtype Sint is Interfaces.C.int;
   subtype Uint32 is Interfaces.Unsigned_32;
   subtype Uint64 is Interfaces.Unsigned_64;
   subtype Uint8 is Interfaces.Unsigned_8;
   subtype C_Bool is Interfaces.C.Extensions.bool;
   subtype C_Float is Interfaces.C.C_float;
   subtype Chars_Ptr is Interfaces.C.Strings.chars_ptr;
   subtype Address is System.Address;

   type SDL_App_Result is
     (SDL_App_Continue,
      SDL_App_Success,
      SDL_App_Failure)
     with Convention => C;

   SDL_Init_Video  : constant Uint32 := 16#00000020#;
   SDL_Event_Quit  : constant Uint32 := 16#00000100#;
   SDL_Alpha_Opaque : constant Uint8 := 16#FF#;

   type SDL_Window is null record
     with Convention => C;

   type SDL_Renderer is null record
     with Convention => C;

   type SDL_Texture is null record
     with Convention => C;

   type SDL_Surface is null record
     with Convention => C;

   type SDL_Window_Access is access all SDL_Window
     with Convention => C;

   type SDL_Renderer_Access is access all SDL_Renderer
     with Convention => C;

   type SDL_Texture_Access is access all SDL_Texture
     with Convention => C;

   type SDL_Surface_Access is access all SDL_Surface
     with Convention => C;

   type SDL_FRect is record
      X : aliased C_Float;
      Y : aliased C_Float;
      W : aliased C_Float;
      H : aliased C_Float;
   end record
   with Convention => C_Pass_By_Copy;

   type SDL_Color is record
      R : aliased Uint8;
      G : aliased Uint8;
      B : aliased Uint8;
      A : aliased Uint8;
   end record
   with Convention => C_Pass_By_Copy;

   type Event_Padding is array (Natural range 0 .. 123) of aliased Uint8
     with Convention => C;

   type SDL_Event is record
      Event_Type : aliased Uint32;
      Padding    : Event_Padding;
   end record
   with Convention => C_Pass_By_Copy;

   type SDL_App_Init_Func is access function
     (Appstate : Address;
      Argc     : Sint;
      Argv     : Address) return SDL_App_Result
     with Convention => C;

   type SDL_App_Iterate_Func is access function
     (Appstate : Address) return SDL_App_Result
     with Convention => C;

   type SDL_App_Event_Func is access function
     (Appstate : Address;
      Event    : access SDL_Event) return SDL_App_Result
     with Convention => C;

   type SDL_App_Quit_Func is access procedure
     (Appstate : Address;
      Result   : SDL_App_Result)
     with Convention => C;

   function SDL_Init (Flags : Uint32) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_Init";

   procedure SDL_Quit
     with Import => True,
          Convention => C,
          External_Name => "SDL_Quit";

   function SDL_CreateWindowAndRenderer
     (Title        : Chars_Ptr;
      Width        : Sint;
      Height       : Sint;
      Window_Flags : Uint64;
      Window       : access SDL_Window_Access;
      Renderer     : access SDL_Renderer_Access) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_CreateWindowAndRenderer";

   function SDL_SetRenderDrawColor
     (Renderer : SDL_Renderer_Access;
      R        : Uint8;
      G        : Uint8;
      B        : Uint8;
      A        : Uint8) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_SetRenderDrawColor";

   function SDL_RenderClear (Renderer : SDL_Renderer_Access) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_RenderClear";

   function SDL_RenderPresent (Renderer : SDL_Renderer_Access) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_RenderPresent";

   function SDL_GetVersion return Sint
     with Import => True,
          Convention => C,
          External_Name => "SDL_GetVersion";

   function SDL_RenderDebugText
     (Renderer : SDL_Renderer_Access;
      X        : C_Float;
      Y        : C_Float;
      Text     : Chars_Ptr) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_RenderDebugText";

   function SDL_GetTextureSize
     (Texture : SDL_Texture_Access;
      W       : access C_Float;
      H       : access C_Float) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_GetTextureSize";

   function SDL_SetTextureColorMod
     (Texture : SDL_Texture_Access;
      R       : Uint8;
      G       : Uint8;
      B       : Uint8) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_SetTextureColorMod";

   function SDL_SetTextureAlphaMod
     (Texture : SDL_Texture_Access;
      Alpha   : Uint8) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_SetTextureAlphaMod";

   function SDL_RenderTexture
     (Renderer : SDL_Renderer_Access;
      Texture  : SDL_Texture_Access;
      Src_Rect : access constant SDL_FRect;
      Dst_Rect : access constant SDL_FRect) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_RenderTexture";

   function SDL_CreateTextureFromSurface
     (Renderer : SDL_Renderer_Access;
      Surface  : SDL_Surface_Access) return SDL_Texture_Access
     with Import => True,
          Convention => C,
          External_Name => "SDL_CreateTextureFromSurface";

   function SDL_PollEvent (Event : access SDL_Event) return C_Bool
     with Import => True,
          Convention => C,
          External_Name => "SDL_PollEvent";

   procedure SDL_DestroyRenderer (Renderer : SDL_Renderer_Access)
     with Import => True,
          Convention => C,
          External_Name => "SDL_DestroyRenderer";

   procedure SDL_DestroyTexture (Texture : SDL_Texture_Access)
     with Import => True,
          Convention => C,
          External_Name => "SDL_DestroyTexture";

   procedure SDL_DestroySurface (Surface : SDL_Surface_Access)
     with Import => True,
          Convention => C,
          External_Name => "SDL_DestroySurface";

   procedure SDL_DestroyWindow (Window : SDL_Window_Access)
     with Import => True,
          Convention => C,
          External_Name => "SDL_DestroyWindow";

   function SDL_GetError return Chars_Ptr
     with Import => True,
          Convention => C,
          External_Name => "SDL_GetError";

   function SDL_EnterAppMainCallbacks
     (Argc     : Sint;
      Argv     : Address;
      Appinit  : SDL_App_Init_Func;
      Appiter  : SDL_App_Iterate_Func;
      Appevent : SDL_App_Event_Func;
      Appquit  : SDL_App_Quit_Func) return Sint
     with Import => True,
          Convention => C,
          External_Name => "SDL_EnterAppMainCallbacks";

   function Puts (Text : Chars_Ptr) return Sint
     with Import => True,
          Convention => C,
          External_Name => "puts";

end SDL3_Bindings;
