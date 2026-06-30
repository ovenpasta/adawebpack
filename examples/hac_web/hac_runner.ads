--  Library-level entry point exported to JavaScript. Takes an Ada source
--  text and a (virtual) file name, both handed over from the browser as C
--  strings, compiles the source with HAC and runs it on the HAC VM. The file
--  name gives HAC the main unit name (GNAT naming convention), so the page's
--  file-name box must match the unit in the source (default main.adb / Main).
--  All program output goes to the console, which the Emscripten runtime
--  forwards to the host page.

with Interfaces.C.Strings;

package HAC_Runner is

   procedure Compile_And_Run
     (Source    : Interfaces.C.Strings.chars_ptr;
      File_Name : Interfaces.C.Strings.chars_ptr);
   pragma Export (C, Compile_And_Run, "hac_compile_and_run");

end HAC_Runner;
