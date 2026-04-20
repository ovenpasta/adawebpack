------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                          A D A . T E X T _ I O                           --
--                                                                          --
--                                 S p e c                                  --
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

--  Note: this package is not compliant with the one defined in the Ada
--  Reference Manual. It is a stripped-down version for the WASM runtime:
--  console-only, no file handles, no full formatted numeric I/O. The Field
--  and Number_Base types are exported so that the child generic packages
--  Ada.Text_IO.Integer_IO and Ada.Text_IO.Float_IO can be instantiated
--  (e.g. via Ada.Integer_Text_IO, Ada.Float_Text_IO) for string-based
--  Put/Get without dragging in the full file I/O machinery.

package Ada.Text_IO is

   subtype Field       is Integer range 0 .. Integer'Last;
   subtype Number_Base is Integer range 2 .. 16;

   procedure Get (C : out Character);
   --  Read a character from the console. On WASM this currently returns
   --  ASCII.NUL (the browser does not provide blocking console input).

   procedure Put (Item : Character);
   --  Write a character to the console.

   procedure Put (Item : String);
   --  Write a string to the console.

   procedure Put_Line (Item : String);
   --  Write a string followed by a line terminator to the console.

   procedure New_Line (Spacing : Positive := 1);
   --  Write Spacing line terminators to the console.

end Ada.Text_IO;
