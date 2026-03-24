with Basic_Build_Info;
with Emscripten_Bindings;
with GNAT.Compiler_Version;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with SDL3_Bindings;
with System;

package body Basic_App is

   use type Interfaces.C.Extensions.bool;
   use type Interfaces.C.int;
   use type Interfaces.C.Strings.chars_ptr;
   use type Interfaces.Unsigned_32;
   use type SDL3_Bindings.SDL_Window_Access;
   use type SDL3_Bindings.SDL_Renderer_Access;

   Window     : aliased SDL3_Bindings.SDL_Window_Access := null;
   Renderer   : aliased SDL3_Bindings.SDL_Renderer_Access := null;
   Frame_Count : Interfaces.Unsigned_32 := 0;
   Quit_Requested : Boolean := False;
   Initialized : Boolean := False;

   function Color_From_Frame
     (Frame : Interfaces.Unsigned_32;
      Scale : Interfaces.Unsigned_32;
      Base  : Interfaces.Unsigned_32) return SDL3_Bindings.Uint8;
   function Image_No_Space (Value : Interfaces.C.int) return String;
   function Pulse_Color
     (Frame     : Interfaces.Unsigned_32;
      Period    : Interfaces.Unsigned_32;
      Minimum   : SDL3_Bindings.Uint8;
      Amplitude : SDL3_Bindings.Uint8) return SDL3_Bindings.Uint8;

   function Is_True (Value : SDL3_Bindings.C_Bool) return Boolean is
     (Value /= Interfaces.C.Extensions.bool'Val (0));

   package Compiler_Version is new GNAT.Compiler_Version;

   function Error_Message return String;

   procedure Log (Message : String);
   function Render_Debug_Line
     (Y    : Interfaces.C.C_float;
      Text : Interfaces.C.Strings.Chars_Ptr) return Boolean;
   function Render_Basic_Overlay return Boolean;
   procedure Fail_Init (Success : out Boolean; Message : String);
   procedure Initialize (Success : out Boolean);
   procedure Shutdown;

   ----------------------
   -- Color_From_Frame --
   ----------------------

   function Color_From_Frame
     (Frame : Interfaces.Unsigned_32;
      Scale : Interfaces.Unsigned_32;
      Base  : Interfaces.Unsigned_32) return SDL3_Bindings.Uint8
   is
      Value : constant Interfaces.Unsigned_32 :=
        ((Frame * Scale) + Base) mod 255;
   begin
      return SDL3_Bindings.Uint8 (Value);
   end Color_From_Frame;

   -------------------
   -- Image_No_Space --
   -------------------

   function Image_No_Space (Value : Interfaces.C.int) return String is
      Image : constant String := Interfaces.C.int'Image (Value);
      First : Positive := Image'First;
   begin
      while First < Image'Last and then Image (First) = ' ' loop
         First := First + 1;
      end loop;

      return Image (First .. Image'Last);
   end Image_No_Space;

   function Pulse_Color
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
   end Pulse_Color;

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message return String is
      Message : constant SDL3_Bindings.Chars_Ptr := SDL3_Bindings.SDL_GetError;
   begin
      if Message = Interfaces.C.Strings.Null_Ptr then
         return "unknown SDL error";
      end if;

      return Interfaces.C.Strings.Value (Message);
   end Error_Message;

   ---------
   -- Log --
   ---------

   procedure Log (Message : String) is
      Text : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String (Message);
      Ignore : SDL3_Bindings.Sint;
   begin
      Ignore := SDL3_Bindings.Puts (Text);
      Interfaces.C.Strings.Free (Text);
   end Log;

   -----------------------
   -- Render_Debug_Line --
   -----------------------

   function Render_Debug_Line
     (Y    : Interfaces.C.C_float;
      Text : Interfaces.C.Strings.Chars_Ptr) return Boolean
   is
      Ok : constant Boolean :=
        Is_True
          (SDL3_Bindings.SDL_RenderDebugText
             (Renderer,
              36.0,
              Y,
              Text));
   begin
      return Ok;
   end Render_Debug_Line;

   --------------------------
   -- Render_Basic_Overlay --
   --------------------------

   function Render_Basic_Overlay return Boolean is
      V     : constant SDL3_Bindings.Sint := SDL3_Bindings.SDL_GetVersion;
      Major : constant Interfaces.C.int   := Interfaces.C.int (V) / 1_000_000;
      Minor : constant Interfaces.C.int   := (Interfaces.C.int (V) / 1_000) mod 1_000;
      Patch : constant Interfaces.C.int   := Interfaces.C.int (V) mod 1_000;
      SDL_Str   : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String
          ("SDL " & Image_No_Space (Major) & "."
                  & Image_No_Space (Minor) & "."
                  & Image_No_Space (Patch));
      GNAT_Str  : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String
          (Compiler_Version.Version & " via GNAT-LLVM");
      LLVM_Str  : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String (Basic_Build_Info.LLVM_Line);
      Title_Str : Interfaces.C.Strings.Chars_Ptr :=
        Interfaces.C.Strings.New_String ("SDL debug text overlay");
      Result : Boolean;
   begin
      Result :=
        Is_True (SDL3_Bindings.SDL_SetRenderDrawColor
          (Renderer, 16#F6#, 16#F2#, 16#E8#, SDL3_Bindings.SDL_Alpha_Opaque))
        and then Render_Debug_Line (40.0, SDL_Str)
        and then Render_Debug_Line (62.0, GNAT_Str)
        and then Render_Debug_Line (84.0, LLVM_Str)
        and then Render_Debug_Line (106.0, Title_Str);
      Interfaces.C.Strings.Free (SDL_Str);
      Interfaces.C.Strings.Free (GNAT_Str);
      Interfaces.C.Strings.Free (LLVM_Str);
      Interfaces.C.Strings.Free (Title_Str);
      return Result;
   end Render_Basic_Overlay;

   ---------------
   -- Fail_Init --
   ---------------

   procedure Fail_Init (Success : out Boolean; Message : String) is
   begin
      Log (Message & ": " & Error_Message);
      Shutdown;
      Success := False;
   end Fail_Init;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Success : out Boolean) is
   begin
      Success := False;

      if not Is_True (SDL3_Bindings.SDL_Init (SDL3_Bindings.SDL_Init_Video)) then
         Fail_Init (Success, "SDL_Init failed");
         return;
      end if;

      declare
         Title : Interfaces.C.Strings.Chars_Ptr :=
           Interfaces.C.Strings.New_String ("SDL3 Basic");
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

      Frame_Count := 0;
      Quit_Requested := False;
      Initialized := True;
      Success := True;
   end Initialize;

   ---------------------
   -- SDL_App_Iterate --
   ---------------------

   function SDL_App_Iterate (Appstate : System.Address) return SDL3_Bindings.SDL_App_Result is
      Slow_Frame : constant Interfaces.Unsigned_32 := Frame_Count / 10;
      Red   : SDL3_Bindings.Uint8;
      Green : SDL3_Bindings.Uint8;
      Blue  : SDL3_Bindings.Uint8;
   begin
      pragma Unreferenced (Appstate);

      if not Initialized then
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if Quit_Requested then
         return SDL3_Bindings.SDL_App_Success;
      end if;

      Red := Pulse_Color (Slow_Frame, 300, 34, 26);
      Green := Pulse_Color (Slow_Frame + 90, 300, 52, 24);
      Blue := Pulse_Color (Slow_Frame + 180, 300, 82, 28);

      Frame_Count := Frame_Count + 1;

      if not Is_True
        (SDL3_Bindings.SDL_SetRenderDrawColor
           (Renderer,
            Red,
            Green,
            Blue,
            SDL3_Bindings.SDL_Alpha_Opaque))
      then
         Log ("SDL_SetRenderDrawColor failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True (SDL3_Bindings.SDL_RenderClear (Renderer)) then
         Log ("SDL_RenderClear failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Render_Basic_Overlay then
         Log ("SDL_RenderDebugText failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;

      if not Is_True (SDL3_Bindings.SDL_RenderPresent (Renderer)) then
         Log ("SDL_RenderPresent failed: " & Error_Message);
         return SDL3_Bindings.SDL_App_Failure;
      end if;
      return SDL3_Bindings.SDL_App_Continue;
   end SDL_App_Iterate;

   ------------------
   -- SDL_App_Init --
   ------------------

   function SDL_App_Init
     (Appstate : System.Address;
      Argc     : SDL3_Bindings.Sint;
      Argv     : System.Address) return SDL3_Bindings.SDL_App_Result
   is
      Success : Boolean;
   begin
      pragma Unreferenced (Argc, Argv);
      pragma Unreferenced (Appstate);

      Initialize (Success);

      if Success then
         return SDL3_Bindings.SDL_App_Continue;
      end if;

      return SDL3_Bindings.SDL_App_Failure;
   end SDL_App_Init;

   -------------------
   -- SDL_App_Event --
   -------------------

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

   ------------------
   -- SDL_App_Quit --
   ------------------

   procedure SDL_App_Quit
     (Appstate : System.Address;
      Result   : SDL3_Bindings.SDL_App_Result)
   is
   begin
      pragma Unreferenced (Appstate, Result);
      Shutdown;
   end SDL_App_Quit;

   ---------
   -- Run --
   ---------

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

   --------------
   -- Shutdown --
   --------------

   procedure Shutdown is
   begin
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

end Basic_App;
