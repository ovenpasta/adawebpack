------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                         S Y S T E M . O S _ L I B                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--  WASM32 stub.  Provides what Ada.Calendar needs:                         --
--    - To_Ada conversion                                                    --
--    - __gnat_invalid_tzoff C variable                                      --
--    - __gnat_localtime_tzoff C function (used by UTC_Time_Offset)          --
--                                                                          --
--  struct tm layout for wasm32 / Emscripten musl:                          --
--    9 x int (4 bytes each), then long tm_gmtoff (4 bytes), then ptr.      --
--                                                                          --
------------------------------------------------------------------------------

with Interfaces.C;         use type Interfaces.C.size_t;
with Interfaces.C.Strings;

package body System.OS_Lib is

   function To_Ada (Time : Long_Long_Integer) return OS_Time is
   begin
      return OS_Time (Time);
   end To_Ada;

   function C_Strerror (Errnum : Interfaces.C.int)
     return Interfaces.C.Strings.chars_ptr;
   pragma Import (C, C_Strerror, "strerror");

   function C_Strlen (S : Interfaces.C.Strings.chars_ptr)
     return Interfaces.C.size_t;
   pragma Import (C, C_Strlen, "strlen");

   function Errno_Message
     (Err     : Integer := Errno;
      Default : String  := "") return String
   is
      Ptr : constant Interfaces.C.Strings.chars_ptr :=
        C_Strerror (Interfaces.C.int (Err));
   begin
      if Interfaces.C.Strings."=" (Ptr, Interfaces.C.Strings.Null_Ptr)
        or else C_Strlen (Ptr) = 0
      then
         if Default = "" then
            return "errno =" & Integer'Image (Err);
         else
            return Default;
         end if;
      end if;

      return Interfaces.C.Strings.Value (Ptr);
   end Errno_Message;

   --  C struct tm for wasm32/Emscripten (all fields 4 bytes)

   type C_tm is record
      tm_sec    : Interfaces.C.int;
      tm_min    : Interfaces.C.int;
      tm_hour   : Interfaces.C.int;
      tm_mday   : Interfaces.C.int;
      tm_mon    : Interfaces.C.int;
      tm_year   : Interfaces.C.int;
      tm_wday   : Interfaces.C.int;
      tm_yday   : Interfaces.C.int;
      tm_isdst  : Interfaces.C.int;
      tm_gmtoff : Interfaces.C.long;  --  UTC offset in seconds
      tm_zone   : System.Address;     --  timezone name (unused)
   end record
     with Convention => C;

   procedure C_Localtime_R
     (timer  : access OS_Time;
      result : access C_tm);
   pragma Import (C, C_Localtime_R, "localtime_r");
   --  Fills *result in place; return value (pointer copy) is discarded.

   --  Sentinel for "timezone offset unknown".
   --  Value 259273 = 3 days + 73 seconds; can never be a real UTC offset.

   Invalid_Tzoff : constant Interfaces.C.long := 259273;
   pragma Export (C, Invalid_Tzoff, "__gnat_invalid_tzoff");

   --  Called by Ada.Calendar.UTC_Time_Offset via pragma Import (C, ...).
   --  timer       : pointer to Unix time as OS_Time (int64)
   --  is_historic : ignored (localtime_r handles both historic and current)
   --  off         : receives the UTC offset in seconds

   procedure Localtime_Tzoff
     (Timer       : access OS_Time;
      Is_Historic : access Interfaces.C.int;
      Off         : access Interfaces.C.long);
   pragma Export (C, Localtime_Tzoff, "__gnat_localtime_tzoff");

   procedure Localtime_Tzoff
     (Timer       : access OS_Time;
      Is_Historic : access Interfaces.C.int;
      Off         : access Interfaces.C.long)
   is
      pragma Unreferenced (Is_Historic);
      TM : aliased C_tm;
   begin
      C_Localtime_R (Timer, TM'Access);
      Off.all := TM.tm_gmtoff;
   end Localtime_Tzoff;

end System.OS_Lib;
