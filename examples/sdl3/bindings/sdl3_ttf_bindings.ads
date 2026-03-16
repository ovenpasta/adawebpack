with Interfaces.C;
with SDL3_Bindings;

package SDL3_TTF_Bindings is

   type TTF_Font is null record
     with Convention => C;

   type TTF_Font_Access is access all TTF_Font
     with Convention => C;

   function TTF_Init return SDL3_Bindings.C_Bool
     with Import => True,
          Convention => C,
          External_Name => "TTF_Init";

   function TTF_OpenFont
     (File    : SDL3_Bindings.Chars_Ptr;
      Pt_Size : Interfaces.C.C_float) return TTF_Font_Access
     with Import => True,
          Convention => C,
          External_Name => "TTF_OpenFont";

   function TTF_RenderText_Blended
     (Font   : TTF_Font_Access;
      Text   : SDL3_Bindings.Chars_Ptr;
      Length : Interfaces.C.size_t;
      Fg     : SDL3_Bindings.SDL_Color) return SDL3_Bindings.SDL_Surface_Access
     with Import => True,
          Convention => C,
          External_Name => "TTF_RenderText_Blended";

   procedure TTF_CloseFont (Font : TTF_Font_Access)
     with Import => True,
          Convention => C,
          External_Name => "TTF_CloseFont";

   procedure TTF_Quit
     with Import => True,
          Convention => C,
          External_Name => "TTF_Quit";

end SDL3_TTF_Bindings;
