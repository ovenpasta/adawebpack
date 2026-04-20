------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                 A D A . T E X T _ I O . F L O A T _ I O                  --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT.  In accordance with the copyright of that document, you can freely --
-- copy and modify this specification,  provided that if you redistribute a --
-- modified version,  any changes that you have made are clearly indicated. --
--                                                                          --
------------------------------------------------------------------------------

--  WASM variant: stripped Float_IO - only the string-based operations and
--  a console Put. No File_Type support. Used by Ada.Float_Text_IO.

generic
   type Num is digits <>;

package Ada.Text_IO.Float_IO is

   Default_Fore : Field := 2;
   Default_Aft  : Field := Num'Digits - 1;
   Default_Exp  : Field := 3;

   procedure Put
     (To   : out String;
      Item : Num;
      Aft  : Field := Default_Aft;
      Exp  : Field := Default_Exp);
   --  Image of Item with Aft digits after the decimal point and Exp digits
   --  in the exponent (or no exponent if Exp = 0). The image is placed in
   --  To, padded with leading spaces if shorter than To. Layout_Error is
   --  raised if the image does not fit in To.

   procedure Put
     (Item : Num;
      Fore : Field := Default_Fore;
      Aft  : Field := Default_Aft;
      Exp  : Field := Default_Exp);
   --  Write image of Item to the console (System.IO).

   procedure Get
     (From : String;
      Item : out Num;
      Last : out Positive);
   --  Scan a real literal from From starting at From'First, set Item to its
   --  value and Last to the index of the last character consumed.
   --  Data_Error is raised if no valid literal is found.

end Ada.Text_IO.Float_IO;
