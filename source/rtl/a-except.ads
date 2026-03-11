------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                       A D A . E X C E P T I O N S                        --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT.  In accordance with the copyright of that document, you can freely --
-- copy and modify this specification,  provided that if you redistribute a --
-- modified version,  any changes that you have made are clearly indicated. --
--                                                                          --
------------------------------------------------------------------------------
--
--  Version is for use when there are no handlers in the partition (i.e. either
--  of Restriction No_Exception_Handlers or No_Exception_Propagation is set).

--  This is the WASM version of this package.
--
--  Exception_Occurrence is deliberately omitted to work around a GNAT-LLVM
--  compiler bug (Assert_Failure sem_ch12.adb:18668) that corrupts the
--  Generic_Renamings table during generic instantiation when
--  Exception_Occurrence is declared.  No RTS source file uses it.

with System;

package Ada.Exceptions is
   pragma Preelaborate;
   --  In accordance with Ada 2005 AI-362

   type Exception_Id is private;
   pragma Preelaborable_Initialization (Exception_Id);

   Null_Id : constant Exception_Id;

   procedure Raise_Exception (E : Exception_Id; Message : String := "");
   pragma No_Return (Raise_Exception);
   --  Unconditionally call __gnat_last_chance_handler.
   --  Note that the exception is still raised even if E is the null exception
   --  id. This is a deliberate simplification for this profile (the use of
   --  Raise_Exception with a null id is very rare in any case, and this way
   --  we avoid introducing Raise_Exception_Always and we also avoid the if
   --  test in Raise_Exception).

private

   ------------------
   -- Exception_Id --
   ------------------

   type Exception_Id is access all System.Address;
   Null_Id : constant Exception_Id := null;

--   pragma Inline_Always (Raise_Exception);

end Ada.Exceptions;
