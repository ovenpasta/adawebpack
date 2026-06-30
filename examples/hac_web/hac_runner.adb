with Ada.Text_IO;

with HAC_Sys.Builder;
with HAC_Sys.Co_Defs;
with HAC_Sys.PCode.Interpreter;

with Mem_Source;

package body HAC_Runner is

   use HAC_Sys.Builder;
   use HAC_Sys.PCode.Interpreter;

   procedure Compile_And_Run
     (Source    : Interfaces.C.Strings.chars_ptr;
      File_Name : Interfaces.C.Strings.chars_ptr)
   is
      Source_Text : constant String := Interfaces.C.Strings.Value (Source);
      Name        : constant String := Interfaces.C.Strings.Value (File_Name);

      Source_Stream : constant HAC_Sys.Co_Defs.Source_Stream_Access :=
        Mem_Source.New_String_Stream (Source_Text);

      BD : Build_Data;
      PM : Post_Mortem_Data;

      procedure Show_Line_Information
        (File_Name   : String;
         Block_Name  : String;
         Line_Number : Positive)
      is
      begin
         Ada.Text_IO.Put_Line
           (File_Name & ": " & Block_Name & " at line" &
            Integer'Image (Line_Number));
      end Show_Line_Information;

      procedure Trace_Back is new Show_Trace_Back (Show_Line_Information);
   begin
      Set_Main_Source_Stream (BD, Source_Stream, Name);
      Build_Main (BD);

      if Build_Successful (BD) then
         Ada.Text_IO.Put_Line ("------------------------------------");
         Interpret_on_Current_IO (BD, 0, "", PM);
         Ada.Text_IO.Put_Line ("------------------------------------");
         if Is_Exception_Raised (PM.Unhandled) then
            Ada.Text_IO.Put_Line ("HAC VM raised: " & Image (PM.Unhandled));
            Ada.Text_IO.Put_Line (Message (PM.Unhandled));
            Ada.Text_IO.Put_Line ("Trace-back: approximate location");
            Trace_Back (PM.Unhandled);
         else
            Ada.Text_IO.Put_Line ("Program executed successfully.");
         end if;
      else
         Ada.Text_IO.Put_Line ("Compilation FAILED.");
      end if;
   end Compile_And_Run;

end HAC_Runner;
