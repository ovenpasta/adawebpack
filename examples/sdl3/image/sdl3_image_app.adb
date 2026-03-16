with Emscripten_Bindings;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with SDL3_Bindings;
with SDL3_Image_Bindings;
with System;

package body SDL3_Image_App is

   use type Interfaces.C.C_float;
   use type Interfaces.C.Extensions.bool;
   use type Interfaces.C.int;
   use type Interfaces.C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;
   use type SDL3_Bindings.SDL_Renderer_Access;
   use type SDL3_Bindings.SDL_Texture_Access;
   use type SDL3_Bindings.SDL_Window_Access;

   Image_Path : constant String := "/ada-strong-2022-256-color.png";

   Window         : aliased SDL3_Bindings.SDL_Window_Access := null;
   Renderer       : aliased SDL3_Bindings.SDL_Renderer_Access := null;
   Texture        : SDL3_Bindings.SDL_Texture_Access := null;
   Texture_Width  : aliased Interfaces.C.C_float := 0.0;
   Texture_Height : aliased Interfaces.C.C_float := 0.0;
   Frame_Count    : Interfaces.Unsigned_32 := 0;
   Quit_Requested : Boolean := False;
   Initialized    : Boolean := False;

   function Error_Message return String;
   function Is_True (Value : SDL3_Bindings.C_Bool) return Boolean;
   function Pulse
     (Frame     : Interfaces.Unsigned_32;
      Period    : Interfaces.Unsigned_32;
      Minimum   : Interfaces.C.C_float;
      Amplitude : Interfaces.C.C_float) return Interfaces.C.C_float;

   procedure Fail_Init (Success : out Boolean; Message : String);
   procedure Initialize (Success : out Boolean);
   procedure Log (Message : String);
   procedure Shutdown;

   function Pulse
     (Frame     : Interfaces.Unsigned_32;
      Period    : Interfaces.Unsigned_32;
      Minimum   : Interfaces.C.C_float;
      Amplitude : Interfaces.C.C_float) return Interfaces.C.C_float
   is
      Step  : constant Interfaces.Unsigned_32 := Frame mod Period;
      Half  : constant Interfaces.Unsigned_32 := Period / 2;
      Wave  : Interfaces.Unsigned_32;
   begin
      if Step < Half then
         Wave := Step;
      else
         Wave := Period - Step;
      end if;

      return Minimum +
        (Interfaces.C.C_float (Wave) * Amplitude) / Interfaces.C.C_float (Half);
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

   ---------------
   -- Fail_Init --
   ---------------

   procedure Fail_Init (Success : out Boolean; Message : String) is
   begin
      Log (Message & ": " & Error_Message);
      Shutdown;
      Success := False;
   end Fail_Init;

   procedure Initialize (Success : out Boolean) is
   begin
      Success := False;

      if not Is_True (SDL3_Bindings.SDL_Init (SDL3_Bindings.SDL_Init_Video)) then
         Fail_Init (Success, "SDL_Init failed");
         return;
      end if;

      declare
         Title : Interfaces.C.Strings.Chars_Ptr :=
           Interfaces.C.Strings.New_String ("SDL3 Image");
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

      declare
         Path : Interfaces.C.Strings.Chars_Ptr :=
           Interfaces.C.Strings.New_String (Image_Path);
         Loaded : SDL3_Bindings.SDL_Texture_Access;
      begin
         Loaded := SDL3_Image_Bindings.IMG_LoadTexture (Renderer, Path);
         Interfaces.C.Strings.Free (Path);
         Texture := Loaded;

         if Texture = null then
            Fail_Init (Success, "IMG_LoadTexture failed");
            return;
         end if;
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
      Width_Scale : constant Interfaces.C.C_float :=
        Pulse (Frame_Count, 240, 0.98, 0.06);
      Height_Scale : constant Interfaces.C.C_float :=
        Pulse (Frame_Count + 60, 240, 0.98, 0.06);
      Drift_Y : constant Interfaces.C.C_float :=
        Pulse (Frame_Count + 30, 180, -6.0, 12.0);
      Dest_Width : constant Interfaces.C.C_float := Texture_Width * Width_Scale;
      Dest_Height : constant Interfaces.C.C_float := Texture_Height * Height_Scale;
      Dest  : aliased SDL3_Bindings.SDL_FRect :=
        (X => (960.0 - Dest_Width) / 2.0,
         Y => ((540.0 - Dest_Height) / 2.0) + Drift_Y,
         W => Dest_Width,
         H => Dest_Height);
   begin
      pragma Unreferenced (Appstate);

      if not Initialized then
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if Quit_Requested then
         return SDL3_Bindings.SDL_App_Success;
      end if;

      Frame_Count := Frame_Count + 1;

      if not Is_True
        (SDL3_Bindings.SDL_SetRenderDrawColor
           (Renderer,
            16#F2#,
            16#EA#,
            16#DD#,
            SDL3_Bindings.SDL_Alpha_Opaque))
      then
         Log ("SDL_SetRenderDrawColor failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True (SDL3_Bindings.SDL_RenderClear (Renderer)) then
         Log ("SDL_RenderClear failed: " & Error_Message);
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

end SDL3_Image_App;
