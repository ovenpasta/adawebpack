------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--               A D A . T E X T _ I O . I N T E G E R _ I O                --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT.  In accordance with the copyright of that document, you can freely --
-- copy and modify this specification,  provided that if you redistribute a --
-- modified version,  any changes that you have made are clearly indicated. --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant: stripped Integer_IO - only the string-based operations and
--  a console Put. No File_Type support, no Data_Error handling around files.
--  Used by Ada.Integer_Text_IO.

generic
   type Num is range <>;

package Ada.Text_IO.Integer_IO is

   Default_Width : Field       := Num'Width;
   Default_Base  : Number_Base := 10;

   procedure Put
     (To   : out String;
      Item : Num;
      Base : Number_Base := Default_Base);
   --  Image of Item in the given Base, right-justified in To. If the image
   --  is shorter than To, leading spaces are inserted. Layout_Error is
   --  raised if To is too small.

   procedure Put
     (Item  : Num;
      Width : Field       := Default_Width;
      Base  : Number_Base := Default_Base);
   --  Write image of Item to the console (System.IO), padded to at least
   --  Width characters with leading spaces.

   procedure Get
     (From : String;
      Item : out Num;
      Last : out Positive);
   --  Skip leading whitespace in From starting at From'First, scan an
   --  integer literal, set Item to its value and Last to the index of the
   --  last character consumed. Data_Error is raised if no valid integer is
   --  found.

end Ada.Text_IO.Integer_IO;
