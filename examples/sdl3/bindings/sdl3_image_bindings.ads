with SDL3_Bindings;

package SDL3_Image_Bindings is

   function IMG_LoadTexture
     (Renderer : SDL3_Bindings.SDL_Renderer_Access;
      File     : SDL3_Bindings.Chars_Ptr) return SDL3_Bindings.SDL_Texture_Access
     with Import => True,
          Convention => C,
          External_Name => "IMG_LoadTexture";

end SDL3_Image_Bindings;
