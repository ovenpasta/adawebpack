--  Builds an in-memory source stream for HAC from an Ada source text held
--  in a String, so the HAC builder never needs the file system.

with HAC_Sys.Co_Defs;

package Mem_Source is

   function New_String_Stream
     (Text : String) return HAC_Sys.Co_Defs.Source_Stream_Access;

end Mem_Source;
