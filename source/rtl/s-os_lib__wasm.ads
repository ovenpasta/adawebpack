------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                         S Y S T E M . O S _ L I B                        --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--  WASM32 stub - provides only what Ada.Calendar needs:                    --
--    OS_Time type and To_Ada conversion.                                    --
--                                                                          --
------------------------------------------------------------------------------

package System.OS_Lib is
   pragma Preelaborate;

   type OS_Time is private;
   --  Represents a Unix-style time stamp (seconds since 1970-01-01).
   --  Used by Ada.Calendar.UTC_Time_Offset via __gnat_localtime_tzoff.

   Invalid_Time : constant OS_Time;

   function To_Ada (Time : Long_Long_Integer) return OS_Time;
   pragma Inline (To_Ada);

   function Errno return Integer;
   pragma Import (C, Errno, "__get_errno");

   function Errno_Message
     (Err     : Integer := Errno;
      Default : String  := "") return String;
   --  Used by System.File_IO in the emcc RTS.

private
   type OS_Time is range -(2 ** 63) .. +(2 ** 63 - 1);
   Invalid_Time : constant OS_Time := -1;
end System.OS_Lib;
