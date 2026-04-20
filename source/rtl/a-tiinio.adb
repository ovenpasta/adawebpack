------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--               A D A . T E X T _ I O . I N T E G E R _ I O                --
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

--  WASM variant: uses Num'Image/Num'Value; no File_IO, no Integer_Aux.

with Ada.IO_Exceptions;
with System.IO;

package body Ada.Text_IO.Integer_IO is

   Digits_Str : constant String := "0123456789ABCDEF";

   procedure Image_Base
     (Item : Num;
      Base : Number_Base;
      Buf  : out String;
      First : out Natural);
   --  Fill Buf (First .. Buf'Last) with the image of Item in Base. Buf must
   --  be sized by the caller to hold any value of Num. First is set to the
   --  index of the first character of the image.

   ----------------
   -- Image_Base --
   ----------------

   procedure Image_Base
     (Item  : Num;
      Base  : Number_Base;
      Buf   : out String;
      First : out Natural)
   is
      P        : Natural := Buf'Last + 1;
      V        : Num := Item;
      Negative : constant Boolean := Item < 0;
      D        : Natural;
   begin
      Buf := (others => ' ');

      if Negative then
         --  Handle Num'First by peeling off one digit before negating, so
         --  that the absolute value fits in Num. V remains <= 0 throughout.
         D := Natural (abs (V rem Num (Base)));
         V := V / Num (Base);
         P := P - 1;
         Buf (P) := Digits_Str (D + 1);
         if V /= 0 then
            V := -V;
         end if;
      end if;

      loop
         P := P - 1;
         D := Natural (V rem Num (Base));
         Buf (P) := Digits_Str (D + 1);
         V := V / Num (Base);
         exit when V = 0;
      end loop;

      if Negative then
         P := P - 1;
         Buf (P) := '-';
      end if;

      First := P;
   end Image_Base;

   ---------
   -- Put --
   ---------

   procedure Put
     (To   : out String;
      Item : Num;
      Base : Number_Base := Default_Base)
   is
      --  A signed integer in base 2 takes at most Num'Size + 1 chars (digits
      --  plus sign). 80 is comfortably larger than Num'Size on WASM (64).
      Buf   : String (1 .. 80);
      First : Natural;
   begin
      Image_Base (Item, Base, Buf, First);
      declare
         Img  : constant String := Buf (First .. Buf'Last);
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
     (Item  : Num;
      Width : Field       := Default_Width;
      Base  : Number_Base := Default_Base)
   is
      Buf   : String (1 .. 80);
      First : Natural;
   begin
      Image_Base (Item, Base, Buf, First);
      declare
         Img : constant String := Buf (First .. Buf'Last);
      begin
         for J in 1 .. Width - Img'Length loop
            System.IO.Put (' ');
         end loop;
         System.IO.Put (Img);
      end;
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

      if P > Stop or else From (P) not in '0' .. '9' then
         raise Ada.IO_Exceptions.Data_Error;
      end if;

      while P <= Stop and then From (P) in '0' .. '9' loop
         P := P + 1;
      end loop;

      --  Optional base: digits '#' based-digits '#'.
      if P <= Stop and then From (P) = '#' then
         P := P + 1;
         while P <= Stop
           and then (From (P) in '0' .. '9'
                     or else From (P) in 'A' .. 'F'
                     or else From (P) in 'a' .. 'f')
         loop
            P := P + 1;
         end loop;
         if P > Stop or else From (P) /= '#' then
            raise Ada.IO_Exceptions.Data_Error;
         end if;
         P := P + 1;
      end if;

      Last := P - 1;

      declare
         Img : constant String := From (Start .. Last);
      begin
         Item := Num'Value (Img);
      exception
         when Constraint_Error =>
            raise Ada.IO_Exceptions.Data_Error;
      end;
   end Get;

end Ada.Text_IO.Integer_IO;
