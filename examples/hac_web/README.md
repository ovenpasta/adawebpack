# HAC in WebAssembly

[HAC](https://github.com/zertovitch/hac) ("HAC Ada Compiler", by Gautier de
Montmollin) is a small Ada-subset compiler plus p-code virtual machine, written
in pure Ada. This example compiles HAC *itself* to WebAssembly with GNAT-LLVM
and the EH-enabled Emscripten runtime (`rts-wasm-emcc-eh`), so an Ada compiler
runs in the browser and under Node: it parses Ada source, builds a p-code
image, and executes it. HAC is used **unmodified** - native WebAssembly
exception handling lets its ordinary exception-based control flow run as-is.

There are two build artifacts, sharing the same wasm HAC core:

| Artifact      | Built by    | Purpose                                            |
|---------------|-------------|----------------------------------------------------|
| `hac_web.js`  | `make`      | Interactive browser demo (in-memory, no files).    |
| `hac_cli.js`  | `make cli`  | Command-line tool, a drop-in for the native `hac`. |

## Getting the HAC sources

HAC runs *unmodified*. Built against the EH-enabled Emscripten runtime
(`rts-wasm-emcc-eh`), its ordinary exception-based control flow - `End_Error`
to signal end-of-source, `Exception_Message` in handlers - works as-is, so no
HAC source edits are needed. Clone upstream HAC into a `hac/` subdirectory of
this example:

```sh
git clone https://github.com/zertovitch/hac hac
```

`hac/` is ignored by this repo, so it stays a plain upstream checkout.

To run HAC's *own regression suite* through the wasm CLI (see below), apply the
one small test-harness patch shipped here - it only routes the test driver to a
configurable `hac` command and is not needed to build or use the compiler:

```sh
git -C hac apply ../patches/hac-test-harness.patch
```

## Browser demo (`hac_web.js` + `index.html`)

Type an Ada program into the page, click Run, and HAC compiles and runs it
entirely in the browser. No filesystem is involved: the source text is fed to
HAC through an in-memory stream (`Mem_Source`), and `HAC_Runner.Compile_And_Run`
is exported to JavaScript as `hac_compile_and_run` (called from `index.html`).
`hac_web.adb` is an elaboration-only main; the real entry point is the exported
function.

HAC names the main unit after its (virtual) file name, GNAT-style, so the page
has a file-name box (default `main.adb`) whose value is passed to the exported
function alongside the source. The unit declared in the editor must match it:
`main.adb` expects `procedure Main` (or `package Main`, etc.); change the box to
`hello.adb` to run `procedure Hello`. A mismatch is reported by HAC as a
unit-name error.

Build and serve (the EH runtime must exist first - build it once in
`llvm-interface` with `make wasm-emcc-eh`):

```sh
make EMCC=/usr/lib/emscripten/emcc GPRBUILD="alr exec -- gprbuild"
python3 -m http.server
# open http://localhost:8000/index.html
```

With the `gnat_llvm` Alire toolchain instead (emcc on PATH): `alr build`
builds both `hac_web.js` and `hac_cli.js`, cloning HAC into `hac/` first if
needed.

## Command-line tool (`hac_cli.js`)

`hac_cli.js` is HAC's own command-line tool (`hac/src/apps/hac.adb`), built
unmodified. Linked with `-sNODERAWFS=1`, it gets transparent access to the real
Node filesystem, argv, the working directory and the process exit code, so it
behaves like the native `hac` binary:

```sh
make cli EMCC=/usr/lib/emscripten/emcc GPRBUILD="alr exec -- gprbuild"
node hac_cli.js path/to/program.adb [program args...]
node hac_cli.js            # usage and options
```

## Running HAC's own regression suite inside wasm

HAC ships a native test orchestrator (`hac/test/all_silent_tests`) that
shells out to a `hac` command for every one of its ~133 tests, building and
running each as a p-code image and checking the exit code. We reuse it
unchanged in spirit: the orchestrator now reads the command to invoke from the
`hac_command` environment variable (the same mechanism as its existing
`hacbuild` flag). Set it to `node <abs path>/hac_cli.js` and every test is
compiled and executed by HAC running inside WebAssembly. No binary swapping is
needed; the native `hac` stays in place.

```sh
./run_wasm_tests.sh
# Environment overrides: EMCC, EM_CACHE, GPRBUILD, SKIP_CLI_BUILD, SKIP_ORCH_BUILD
```

The script builds `hac_cli.js`, builds the native orchestrator, and runs
`hac_command="node .../hac_cli.js" ./all_silent_tests`. Result: 133/133, the
same as the native baseline.

The `remarks_check` test is itself an Ada program (run by the wasm HAC) that
shells out to a `hac` command for a few sub-compilations. It reads the same
`hac_command` variable as the orchestrator (defaulting to `../hac` when unset),
so under this script those inner calls also run through the wasm CLI. The entire
run, including remarks_check's sub-compilations, is routed through wasm; no
native `hac` binary is involved.

## How it was made to work

The interesting parts that make this work:

1. **Native WebAssembly exception handling.** This is what lets HAC run
   unmodified. Earlier, under `No_Exception_Propagation`, HAC needed source
   workarounds - a value-based end-of-file flag instead of raising `End_Error`
   in the scanner, and handlers stripped of their choice parameter and
   `Exception_Message`. On the EH runtime (`rts-wasm-emcc-eh`) those are
   unnecessary: HAC's exceptions propagate across frames for real, so upstream
   sources build and run as-is.

2. **GNAT-LLVM codegen fix** (`gnatllvm-arrays.adb`, `Get_Indexed_LValue`): the
   native-array GEP path passed raw array indices straight to the GEP. On wasm32
   a 64-bit index type produced an i64 load address that failed wasm-opt
   validation. Each index is now converted to pointer width via `To_Size_Type`
   first, mirroring the nonnative path. Upstream never hit this because all their
   targets have 64-bit pointers.

3. **`system__wasm_emcc.ads`**: `Command_Line_Args` and `Exit_Status_Supported`
   set to `True`, so the binder-generated main accepts argc/argv and returns an
   exit status (needed for the CLI and the self-checking AoC tests).

4. **`hac_command` knob** (the only HAC patch, shipped as
   `patches/hac-test-harness.patch`): `all_silent_tests.adb` and
   `remarks_check.adb` read `hac_command` to pick the HAC command, defaulting to
   the original relative `../hac` path when unset, so the native suite is
   unaffected. This routes the regression suite (and remarks_check's inner
   sub-compilations) through the wasm CLI.

## Files

- `hac_web.adb`, `hac_runner.ad[sb]`, `mem_source.ad[sb]`, `index.html`
  - the interactive browser demo.
- `hac_cli.gpr` (HAC's own CLI), `hac_web.gpr`, `hac_common.gpr`,
  `alire.toml`, `Makefile` - build wiring.
- `run_wasm_tests.sh` - drive HAC's regression suite against the wasm build.
- `patches/hac-test-harness.patch` - the lone HAC patch (test driver only).
