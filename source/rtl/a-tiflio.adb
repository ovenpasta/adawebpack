------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                 A D A . T E X T _ I O . F L O A T _ I O                  --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2026, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant: delegates to System.Img_Real and System.Val_LFlt. Routing
--  Get through Long_Float avoids the per-precision scanner packages
--  (System.Val_Flt for Float, System.Val_LLF for Long_Long_Float), which are
--  not part of the WASM RTS. Precision of Get is therefore Long_Float.

with Ada.IO_Exceptions;
with System.IO;
with System.Img_Real;
with System.Val_LFlt;

package body Ada.Text_IO.Float_IO is

   Buffer_Size : constant := 5200;
   --  System.Img_Util.Max_Real_Image_Length sized for Long_Long_Float'Last
   --  with Aft = Field'Last and Exp = 0. Oversized here is harmless.

   procedure Format
     (Item : Num;
      Fore : Natural;
      Aft  : Natural;
      Exp  : Natural;
      Buf  : out String;
      Last : out Natural);
   --  Fill Buf (Buf'First .. Last) with the formatted image. Buf must be
   --  indexed starting at 1.

   ------------
   -- Format --
   ------------

   procedure Format
     (Item : Num;
      Fore : Natural;
      Aft  : Natural;
      Exp  : Natural;
      Buf  : out String;
      Last : out Natural)
   is
      P : Natural := 0;
   begin
      Buf := (others => ' ');
      System.Img_Real.Set_Image_Real
        (V    => Long_Long_Float (Item),
         S    => Buf,
         P    => P,
         Fore => Fore,
         Aft  => Aft,
         Exp  => Exp);
      Last := P;
   end Format;

   ---------
   -- Put --
   ---------

   procedure Put
     (To   : out String;
      Item : Num;
      Aft  : Field := Default_Aft;
      Exp  : Field := Default_Exp)
   is
      Buf  : String (1 .. Buffer_Size);
      Last : Natural;
   begin
      Format (Item, Fore => 1, Aft => Aft, Exp => Exp, Buf => Buf,
              Last => Last);

      declare
         Img  : constant String := Buf (1 .. Last);
         Fill : Integer;
      begin
         if Img'Length > To'Length then
            raise Ada.IO_Exceptions.Layout_Error;
         end if;

         Fill := To'Length - Img'Length;
         for J in 0 .. Fill - 1 loop
            To (To'First + J) := ' ';
         end loop;
         for J in 0 .. Img'Length - 1 loop
            To (To'First + Fill + J) := Img (Img'First + J);
         end loop;
      end;
   end Put;

   procedure Put
     (Item : Num;
      Fore : Field := Default_Fore;
      Aft  : Field := Default_Aft;
      Exp  : Field := Default_Exp)
   is
      Buf  : String (1 .. Buffer_Size);
      Last : Natural;
   begin
      Format (Item, Fore => Fore, Aft => Aft, Exp => Exp, Buf => Buf,
              Last => Last);
      System.IO.Put (Buf (1 .. Last));
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get
     (From : String;
      Item : out Num;
      Last : out Positive)
   is
      P     : Integer := From'First;
      Stop  : constant Integer := From'Last;
      Start : Integer;
   begin
      --  Skip leading blanks and tabs.
      while P <= Stop
        and then (From (P) = ' ' or else From (P) = ASCII.HT)
      loop
         P := P + 1;
      end loop;

      if P > Stop then
         raise Ada.IO_Exceptions.Data_Error;
      end if;

      Start := P;

      if From (P) = '+' or else From (P) = '-' then
         P := P + 1;
      end if;

      --  Scan digits / dot / exponent. Accept any of the characters that
      --  can appear in a valid real literal; Num'Value will do the final
      --  validation.
      while P <= Stop
        and then (From (P) in '0' .. '9'
                  or else From (P) = '.'
                  or else From (P) = 'e'
                  or else From (P) = 'E'
                  or else From (P) = '+'
                  or else From (P) = '-'
                  or else From (P) = '#'
                  or else From (P) in 'A' .. 'F'
                  or else From (P) in 'a' .. 'f'
                  or else From (P) = '_')
      loop
         P := P + 1;
      end loop;

      if P = Start then
         raise Ada.IO_Exceptions.Data_Error;
      end if;

      Last := P - 1;

      declare
         Img : constant String := From (Start .. Last);
      begin
         Item := Num (System.Val_LFlt.Value_Long_Float (Img));
      exception
         when Constraint_Error =>
            raise Ada.IO_Exceptions.Data_Error;
      end;
   end Get;

end Ada.Text_IO.Float_IO;
