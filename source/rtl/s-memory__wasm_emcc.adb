------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                         S Y S T E M . M E M O R Y                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 2001-2025, Free Software Foundation, Inc.         --
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

--  Emscripten delegating implementation for LLVM/WASM
--  Ada delegates all heap allocation to Emscripten's built-in allocator
--  (dlmalloc) via the standard C malloc/free/realloc symbols.  This ensures
--  Ada and SDL (or any other C library) share a single heap with no function-
--  table index conflicts.

pragma Restrictions (No_Elaboration_Code);

package body System.Memory is

   function Ext_Malloc (Size : size_t) return System.Address
     with Import, Convention => C, External_Name => "malloc";

   procedure Ext_Free (Ptr : System.Address)
     with Import, Convention => C, External_Name => "free";

   function Ext_Realloc (Ptr : System.Address; Size : size_t)
     return System.Address
     with Import, Convention => C, External_Name => "realloc";

   -----------
   -- Alloc --
   -----------

   function Alloc (Size : size_t) return System.Address is
   begin
      if Size = 0 then
         return Ext_Malloc (1);
      end if;
      return Ext_Malloc (Size);
   end Alloc;

   ----------
   -- Free --
   ----------

   procedure Free (Ptr : System.Address) is
   begin
      Ext_Free (Ptr);
   end Free;

   -------------
   -- Realloc --
   -------------

   function Realloc
     (Ptr  : System.Address;
      Size : size_t) return System.Address
   is
   begin
      if Size = 0 then
         Ext_Free (Ptr);
         return System.Null_Address;
      end if;
      return Ext_Realloc (Ptr, Size);
   end Realloc;

end System.Memory;
