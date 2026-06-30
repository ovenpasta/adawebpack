//  Build helper: vet one HAC example for the web demo's sample picker.
//
//  Runs the .adb given as argv[2] through the *actual* browser module
//  (hac_web.js): a single in-memory source, no filesystem, no stdin, no argv -
//  exactly the sandbox the page runs samples in. Exits 0 only if the program
//  both finishes cleanly ("Program executed successfully.") and prints output, so
//  examples that need external files or are multi-file, crash, loop or produce
//  nothing fail here and get dropped automatically.
//
//  The sandbox alone cannot reject a program that *reads* something the page
//  cannot supply: console input returns EOF, Argument_Count is 0, Get_Env is
//  empty, so such a program still "runs" and prints a degenerate result (a bare
//  prompt, "0 arguments", an empty value). Those are exactly the "references to
//  inputs" we want gone, so a tiny capability check below drops a source that
//  names an unsupported HAT primitive. It is a capability test, not a name list:
//  it keys on what the program asks for, never on which file it is.

const fs = require("fs");
const path = require("path");
const createHacModule = require("./hac_web.js");

const file = process.argv[2];
const source = fs.readFileSync(file, "utf8");
const name = path.basename(file);   //  unit name must match the file name

//  Capability check: drop a sample that *reads* something the page cannot
//  supply, or writes a file, yet still runs cleanly - so the runtime gate would
//  keep its degenerate output: a new file (Create), file existence (Exists),
//  console input (Get/Get_Line/Get_Immediate), command line (Argument/
//  Argument_Count/Command_Name) or environment (Get_Env/Set_Env). Opening a
//  *pre-existing* file needs no entry: with no filesystem it raises, so the
//  runtime gate already drops it. Create is listed because HAC's in-process file
//  catalogue lets a program create and write its own file without raising, so a
//  file-writer would otherwise survive. Open/Close are deliberately absent -
//  they would only collide with the common enum literals of the same name. Strip
//  Ada line comments and string literals first so a primitive named only inside
//  a comment or a quoted message is not mistaken for a call. Whole-word,
//  case-insensitive (Ada folds case); "_" is a word char, so \bGet\b never
//  matches Get_Line, hence the longer forms are listed too.
const code = source
  .replace(/--[^\n]*/g, " ")          //  line comments
  .replace(/"(?:[^"]|"")*"/g, '""');  //  string literals
const UNSUPPORTED =
  /\b(Create|Exists|Get|Get_Line|Get_Immediate|Argument|Argument_Count|Command_Name|Get_Env|Set_Env)\b/i;
if (UNSUPPORTED.test(code)) process.exit(1);

const RULE = "------------------------------------";
const out = [];   //  stdout only (program output + the runner's banner)

(async () => {
  try {
    const mod = await createHacModule({
      print:    (t) => out.push(t),
      printErr: () => {},   //  ignore diagnostics; success is judged on stdout
    });
    mod.ccall("hac_compile_and_run", null, ["string", "string"], [source, name]);
  } catch (e) {
    process.exit(1);          //  wasm trap, compile-abort or load failure
  }

  const text = out.join("\n");

  //  Clean run only (a raised VM exception prints "HAC VM raised:" instead).
  if (!text.includes("Program executed successfully.")) process.exit(1);

  //  Keep only if the program itself printed something. Strip the runner's
  //  banner rules and success marker (Put without a newline can glue program
  //  text onto a rule, so work on substrings, not whole lines) and see if any
  //  non-blank text remains.
  const body = text.split(RULE).join("").replace("Program executed successfully.", "");
  process.exit(body.trim() !== "" ? 0 : 1);
})();
