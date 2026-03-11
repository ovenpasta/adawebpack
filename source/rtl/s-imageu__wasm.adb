------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                       S Y S T E M . I M A G E _ U                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2025, Free Software Foundation, Inc.         --
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
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant with ghost proofs removed for compilation without
--  Ada.Numerics.Big_Numbers and System.Val_Spec dependencies.

package body System.Image_U is

   --  Ghost code, loop invariants and assertions in this unit are meant for
   --  analysis only, not for run-time checking, as it would be too costly
   --  otherwise. This is enforced by setting the assertion policy to Ignore.

   pragma Assertion_Policy (Ghost              => Ignore,
                            Loop_Invariant     => Ignore,
                            Assert             => Ignore,
                            Assert_And_Cut     => Ignore,
                            Subprogram_Variant => Ignore);

   --------------------
   -- Image_Unsigned --
   --------------------

   procedure Image_Unsigned
     (V : Uns;
      S : in out String;
      P : out Natural)
   is
   begin
      S (1) := ' ';
      P := 1;
      Set_Image_Unsigned (V, S, P);
   end Image_Unsigned;

   ------------------------
   -- Set_Image_Unsigned --
   ------------------------

   procedure Set_Image_Unsigned
     (V : Uns;
      S : in out String;
      P : in out Natural)
   is
      Nb_Digits : Natural := 0;
      Value     : Uns := V;

   --  Start of processing for Set_Image_Unsigned

   begin
      --  No check is done since, as documented in the specification, the
      --  caller guarantees that S is long enough to hold the result.

      --  First we compute the number of characters needed for representing
      --  the number.
      loop
         Value := Value / 10;
         Nb_Digits := Nb_Digits + 1;

         exit when Value = 0;
      end loop;

      Value := V;

      --  We now populate digits from the end of the string to the beginning
      for J in reverse 1 .. Nb_Digits loop
         S (P + J) := Character'Val (48 + (Value rem 10));
         Value := Value / 10;
      end loop;

      P := P + Nb_Digits;
   end Set_Image_Unsigned;

end System.Image_U;
