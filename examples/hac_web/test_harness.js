// Node harness: load the HAC wasm factory, then call the exported
// hac_compile_and_run twice with two different Ada sources to check that the
// in-process VM is re-usable across runs.

const createHacModule = require("./hac_web.js");

const src1 =
  "with HAT; use HAT;\n" +
  "procedure Demo is\n" +
  "begin\n" +
  "  Put_Line (\"First run: hello from HAC in wasm\");\n" +
  "end Demo;\n";

const src2 =
  "with HAT; use HAT;\n" +
  "procedure Demo is\n" +
  "  T : Integer := 0;\n" +
  "begin\n" +
  "  for I in 1 .. 5 loop T := T + I; end loop;\n" +
  "  Put_Line (\"Second run: sum 1..5 =\" & Integer'Image (T));\n" +
  "end Demo;\n";

(async () => {
  const Module = await createHacModule({
    print: (t) => console.log(t),
    printErr: (t) => console.log("[err] " + t),
  });
  //  The entry takes (source, file_name); the file name must match the unit
  //  in the source (GNAT naming), so "procedure Demo" -> "demo.adb".
  console.log("=== call 1 ===");
  Module.ccall("hac_compile_and_run", null, ["string", "string"],
               [src1, "demo.adb"]);
  console.log("=== call 2 ===");
  Module.ccall("hac_compile_and_run", null, ["string", "string"],
               [src2, "demo.adb"]);
  console.log("=== done ===");
})();
