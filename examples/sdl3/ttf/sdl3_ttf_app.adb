with Emscripten_Bindings;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with SDL3_Bindings;
with SDL3_TTF_Bindings;
with System;

package body SDL3_TTF_App is

   use type Interfaces.C.C_float;
   use type Interfaces.C.Extensions.bool;
   use type Interfaces.C.int;
   use type Interfaces.C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;
   use type SDL3_Bindings.SDL_Renderer_Access;
   use type SDL3_Bindings.SDL_Surface_Access;
   use type SDL3_Bindings.SDL_Texture_Access;
   use type SDL3_Bindings.SDL_Window_Access;
   use type SDL3_TTF_Bindings.TTF_Font_Access;

   Font_Path : constant String := "/PlayfairDisplay-Regular.ttf";
   Font_Size : constant Interfaces.C.C_float := 56.0;

   Window          : aliased SDL3_Bindings.SDL_Window_Access := null;
   Renderer        : aliased SDL3_Bindings.SDL_Renderer_Access := null;
   Texture         : SDL3_Bindings.SDL_Texture_Access := null;
   Texture_Width   : aliased Interfaces.C.C_float := 0.0;
   Texture_Height  : aliased Interfaces.C.C_float := 0.0;
   Frame_Count     : Interfaces.Unsigned_32 := 0;
   Quit_Requested  : Boolean := False;
   Initialized     : Boolean := False;
   TTF_Initialized : Boolean := False;

   function Error_Message return String;
   function Is_True (Value : SDL3_Bindings.C_Bool) return Boolean;
   function Pulse
     (Frame     : Interfaces.Unsigned_32;
      Period    : Interfaces.Unsigned_32;
      Minimum   : SDL3_Bindings.Uint8;
      Amplitude : SDL3_Bindings.Uint8) return SDL3_Bindings.Uint8;

   procedure Fail_Init (Success : out Boolean; Message : String);
   procedure Initialize (Success : out Boolean);
   procedure Log (Message : String);
   function Render_Text_Layer
     (Offset_X : Interfaces.C.C_float;
      Offset_Y : Interfaces.C.C_float;
      Red      : SDL3_Bindings.Uint8;
      Green    : SDL3_Bindings.Uint8;
      Blue     : SDL3_Bindings.Uint8;
      Alpha    : SDL3_Bindings.Uint8;
      Dest     : access constant SDL3_Bindings.SDL_FRect) return Boolean;
   procedure Shutdown;

   function Pulse
     (Frame     : Interfaces.Unsigned_32;
      Period    : Interfaces.Unsigned_32;
      Minimum   : SDL3_Bindings.Uint8;
      Amplitude : SDL3_Bindings.Uint8) return SDL3_Bindings.Uint8
   is
      Step  : constant Interfaces.Unsigned_32 := Frame mod Period;
      Half  : constant Interfaces.Unsigned_32 := Period / 2;
      Wave  : Interfaces.Unsigned_32;
      Value : Interfaces.Unsigned_32;
   begin
      if Step < Half then
         Wave := Step;
      else
         Wave := Period - Step;
      end if;

      Value :=
        Interfaces.Unsigned_32 (Minimum) +
        (Wave * Interfaces.Unsigned_32 (Amplitude)) / Half;
      return SDL3_Bindings.Uint8 (Value);
   end Pulse;

   function Error_Message return String is
      Message : constant SDL3_Bindings.Chars_Ptr := SDL3_Bindings.SDL_GetError;
   begin
      if Message = Interfaces.C.Strings.Null_Ptr then
         return "unknown SDL error";
      end if;

      return Interfaces.C.Strings.Value (Message);
   end Error_Message;

   function Is_True (Value : SDL3_Bindings.C_Bool) return Boolean is
     (Value /= Interfaces.C.Extensions.bool'Val (0));

   procedure Log (Message : String) is
      Text : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String (Message);
      Ignore : SDL3_Bindings.Sint;
   begin
      Ignore := SDL3_Bindings.Puts (Text);
      Interfaces.C.Strings.Free (Text);
   end Log;

   procedure Fail_Init (Success : out Boolean; Message : String) is
   begin
      Log (Message & ": " & Error_Message);
      Shutdown;
      Success := False;
   end Fail_Init;

   function Render_Text_Layer
     (Offset_X : Interfaces.C.C_float;
      Offset_Y : Interfaces.C.C_float;
      Red      : SDL3_Bindings.Uint8;
      Green    : SDL3_Bindings.Uint8;
      Blue     : SDL3_Bindings.Uint8;
      Alpha    : SDL3_Bindings.Uint8;
      Dest     : access constant SDL3_Bindings.SDL_FRect) return Boolean
   is
      Shifted : aliased SDL3_Bindings.SDL_FRect :=
        (X => Dest.X + Offset_X,
         Y => Dest.Y + Offset_Y,
         W => Dest.W,
         H => Dest.H);
   begin
      if not Is_True
        (SDL3_Bindings.SDL_SetTextureColorMod (Texture, Red, Green, Blue))
      then
         Log ("SDL_SetTextureColorMod failed: " & Error_Message);
         return False;
      end if;

      if not Is_True
        (SDL3_Bindings.SDL_SetTextureAlphaMod (Texture, Alpha))
      then
         Log ("SDL_SetTextureAlphaMod failed: " & Error_Message);
         return False;
      end if;

      if not Is_True
        (SDL3_Bindings.SDL_RenderTexture
           (Renderer => Renderer,
            Texture  => Texture,
            Src_Rect => null,
            Dst_Rect => Shifted'Access))
      then
         Log ("SDL_RenderTexture failed: " & Error_Message);
         return False;
      end if;

      return True;
   end Render_Text_Layer;

   procedure Initialize (Success : out Boolean) is
   begin
      Success := False;

      if not Is_True (SDL3_Bindings.SDL_Init (SDL3_Bindings.SDL_Init_Video)) then
         Fail_Init (Success, "SDL_Init failed");
         return;
      end if;

      declare
         Title : Interfaces.C.Strings.Chars_Ptr :=
           Interfaces.C.Strings.New_String ("SDL3 TTF");
         Created : Boolean;
      begin
         Created :=
           Is_True
             (SDL3_Bindings.SDL_CreateWindowAndRenderer
                (Title        => Title,
                 Width        => 960,
                 Height       => 540,
                 Window_Flags => 0,
                 Window       => Window'Access,
                 Renderer     => Renderer'Access));
         Interfaces.C.Strings.Free (Title);

         if not Created then
            Fail_Init (Success, "SDL_CreateWindowAndRenderer failed");
            return;
         end if;
      end;

      if not Is_True (SDL3_TTF_Bindings.TTF_Init) then
         Fail_Init (Success, "TTF_Init failed");
         return;
      end if;
      TTF_Initialized := True;

      declare
         Path : Interfaces.C.Strings.Chars_Ptr :=
           Interfaces.C.Strings.New_String (Font_Path);
         Font : SDL3_TTF_Bindings.TTF_Font_Access;
      begin
         Font := SDL3_TTF_Bindings.TTF_OpenFont (Path, Font_Size);
         Interfaces.C.Strings.Free (Path);

         if Font = null then
            Fail_Init (Success, "TTF_OpenFont failed");
            return;
         end if;

         declare
            Text    : Interfaces.C.Strings.Chars_Ptr :=
              Interfaces.C.Strings.New_String ("Playfair Display from Ada");
            Surface : SDL3_Bindings.SDL_Surface_Access;
            Color   : constant SDL3_Bindings.SDL_Color :=
              (R => 16#1A#,
               G => 16#24#,
               B => 16#2D#,
               A => SDL3_Bindings.SDL_Alpha_Opaque);
         begin
            Surface :=
              SDL3_TTF_Bindings.TTF_RenderText_Blended
                (Font   => Font,
                 Text   => Text,
                 Length => 0,
                 Fg     => Color);
            Interfaces.C.Strings.Free (Text);
            SDL3_TTF_Bindings.TTF_CloseFont (Font);

            if Surface = null then
               Fail_Init (Success, "TTF_RenderText_Blended failed");
               return;
            end if;

            Texture := SDL3_Bindings.SDL_CreateTextureFromSurface (Renderer, Surface);
            SDL3_Bindings.SDL_DestroySurface (Surface);

            if Texture = null then
               Fail_Init (Success, "SDL_CreateTextureFromSurface failed");
               return;
            end if;
         end;
      end;

      if not Is_True
        (SDL3_Bindings.SDL_GetTextureSize
           (Texture,
            Texture_Width'Access,
            Texture_Height'Access))
      then
         Fail_Init (Success, "SDL_GetTextureSize failed");
         return;
      end if;

      Frame_Count := 0;
      Quit_Requested := False;
      Initialized := True;
      Success := True;
   end Initialize;

   function SDL_App_Iterate (Appstate : System.Address) return SDL3_Bindings.SDL_App_Result is
      Dest  : aliased SDL3_Bindings.SDL_FRect :=
        (X => 110.0,
         Y => 205.0,
         W => Texture_Width,
         H => Texture_Height);
      Float_Frame : constant Interfaces.C.C_float :=
        Interfaces.C.C_float (Frame_Count mod 180);
      Drift : constant Interfaces.C.C_float :=
        (if Float_Frame < 90.0
         then Float_Frame / 45.0
         else (180.0 - Float_Frame) / 45.0);
      Shadow_Alpha : constant SDL3_Bindings.Uint8 :=
        Pulse (Frame_Count, 180, 52, 18);
      Highlight_Alpha : constant SDL3_Bindings.Uint8 :=
        Pulse (Frame_Count + 45, 180, 34, 12);
   begin
      pragma Unreferenced (Appstate);

      if not Initialized then
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if Quit_Requested then
         return SDL3_Bindings.SDL_App_Success;
      end if;

      Frame_Count := Frame_Count + 1;
      Dest.Y := Dest.Y - 4.0 + Drift;

      if not Is_True
        (SDL3_Bindings.SDL_SetRenderDrawColor
           (Renderer,
            16#F3#,
            16#ED#,
            16#E3#,
            SDL3_Bindings.SDL_Alpha_Opaque))
      then
         Log ("SDL_SetRenderDrawColor failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True (SDL3_Bindings.SDL_RenderClear (Renderer)) then
         Log ("SDL_RenderClear failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Render_Text_Layer (3.0, 5.0, 16#35#, 16#2B#, 16#24#, Shadow_Alpha, Dest'Access)
      then
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Render_Text_Layer (-1.0, -2.0, 16#D7#, 16#C2#, 16#A7#, Highlight_Alpha, Dest'Access)
      then
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True
        (SDL3_Bindings.SDL_SetTextureColorMod (Texture, 16#20#, 16#1A#, 16#18#))
      then
         Log ("SDL_SetTextureColorMod failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True
        (SDL3_Bindings.SDL_SetTextureAlphaMod
           (Texture, SDL3_Bindings.SDL_Alpha_Opaque))
      then
         Log ("SDL_SetTextureAlphaMod failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True
        (SDL3_Bindings.SDL_RenderTexture
           (Renderer => Renderer,
            Texture  => Texture,
            Src_Rect => null,
            Dst_Rect => Dest'Access))
      then
         Log ("SDL_RenderTexture failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True (SDL3_Bindings.SDL_RenderPresent (Renderer)) then
         Log ("SDL_RenderPresent failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      return SDL3_Bindings.SDL_App_Continue;
   end SDL_App_Iterate;

   function SDL_App_Init
     (Appstate : System.Address;
      Argc     : SDL3_Bindings.Sint;
      Argv     : System.Address) return SDL3_Bindings.SDL_App_Result
   is
      Success : Boolean;
   begin
      pragma Unreferenced (Appstate, Argc, Argv);

      Initialize (Success);

      if Success then
         return SDL3_Bindings.SDL_App_Continue;
      end if;

      return SDL3_Bindings.SDL_App_Failure;
   end SDL_App_Init;

   function SDL_App_Event
     (Appstate : System.Address;
      Event    : access SDL3_Bindings.SDL_Event) return SDL3_Bindings.SDL_App_Result
   is
   begin
      pragma Unreferenced (Appstate);

      if Event /= null and then Event.Event_Type = SDL3_Bindings.SDL_Event_Quit then
         Quit_Requested := True;
         return SDL3_Bindings.SDL_App_Success;
      end if;

      return SDL3_Bindings.SDL_App_Continue;
   end SDL_App_Event;

   procedure SDL_App_Quit
     (Appstate : System.Address;
      Result   : SDL3_Bindings.SDL_App_Result)
   is
   begin
      pragma Unreferenced (Appstate, Result);
      Shutdown;
   end SDL_App_Quit;

   procedure Run is
      Result : SDL3_Bindings.Sint;
   begin
      Result :=
        SDL3_Bindings.SDL_EnterAppMainCallbacks
          (Argc     => 0,
           Argv     => System.Null_Address,
           Appinit  => SDL_App_Init'Access,
           Appiter  => SDL_App_Iterate'Access,
           Appevent => SDL_App_Event'Access,
           Appquit  => SDL_App_Quit'Access);

      if Result = 0 then
         Emscripten_Bindings.Emscripten_Exit_With_Live_Runtime;
      end if;
   end Run;

   procedure Shutdown is
   begin
      if Texture /= null then
         SDL3_Bindings.SDL_DestroyTexture (Texture);
         Texture := null;
      end if;

      if TTF_Initialized then
         SDL3_TTF_Bindings.TTF_Quit;
         TTF_Initialized := False;
      end if;

      if Renderer /= null then
         SDL3_Bindings.SDL_DestroyRenderer (Renderer);
         Renderer := null;
      end if;

      if Window /= null then
         SDL3_Bindings.SDL_DestroyWindow (Window);
         Window := null;
      end if;

      if Initialized then
         SDL3_Bindings.SDL_Quit;
         Initialized := False;
      end if;
   end Shutdown;

end SDL3_TTF_App;
