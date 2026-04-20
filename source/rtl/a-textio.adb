------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                          A D A . T E X T _ I O                           --
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
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant: stripped Text_IO that forwards to System.IO. System.IO on
--  WASM writes to __gnat_put_char / __gnat_put_string, which Emscripten maps
--  to stdout / the browser console.

with System.IO;

package body Ada.Text_IO is

   ---------
   -- Get --
   ---------

   procedure Get (C : out Character) is
   begin
      --  The browser has no blocking console read and we do not want to
      --  introduce a new required WASM import just for this stripped Text_IO.
      --  Return NUL; user code that needs real console input can wire its
      --  own import separately.
      C := ASCII.NUL;
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (Item : Character) is
   begin
      System.IO.Put (Item);
   end Put;

   procedure Put (Item : String) is
   begin
      System.IO.Put (Item);
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : String) is
   begin
      System.IO.Put_Line (Item);
   end Put_Line;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (Spacing : Positive := 1) is
   begin
      System.IO.New_Line (Spacing);
   end New_Line;

end Ada.Text_IO;
