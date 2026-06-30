#!/bin/sh
#
#  Run HAC's own regression suite against the WebAssembly build of HAC.
#
#  HAC ships a native test orchestrator (test/all_silent_tests) that shells
#  out to a `hac` command for every individual test: it builds each Ada source
#  as a p-code image and runs it, then checks the process exit code. The
#  orchestrator now reads that command from the `hac_command` environment
#  variable (same mechanism as its existing `hacbuild` flag), so we simply set
#  "node <hac_cli.js>" and every test is compiled and executed by HAC running
#  inside WebAssembly. No binary swapping is needed.
#
#  Steps:
#    1. Build the wasm CLI (hac_cli.js) via the Makefile.
#    2. Build the native orchestrator (all_silent_tests) with the host GNAT.
#    3. Run `hac_command="node <hac_cli.js>" ./all_silent_tests` from test/.
#       remarks_check also reads hac_command for its inner sub-compilations, so
#       those go through the wasm CLI too; no native `hac` binary is needed and
#       the whole run is routed through wasm.
#
#  Environment overrides:
#    EMCC       path to emcc            (default /usr/lib/emscripten/emcc)
#    EM_CACHE   emscripten cache dir    (default /tmp/emscripten-cache)
#    GPRBUILD   gprbuild command        (default "alr exec -- gprbuild")
#    SKIP_CLI_BUILD=1     reuse an existing hac_cli.js
#    SKIP_ORCH_BUILD=1    reuse an existing all_silent_tests
#
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)        # examples/hac_web
HAC_DIR=$(CDPATH= cd -- "$HERE/hac" && pwd)              # examples/hac_web/hac
TEST_DIR="$HAC_DIR/test"

EMCC=${EMCC:-/usr/lib/emscripten/emcc}
EM_CACHE=${EM_CACHE:-/tmp/emscripten-cache}
GPRBUILD=${GPRBUILD:-alr exec -- gprbuild}

#  HAC command that drives the suite and remarks_check's inner sub-compilations.
#  Default: the wasm CLI under node.  A caller may override `hac_command` in the
#  environment (set it to an empty string to force the native hac/ fallback).
HAC_CMD="${hac_command-node $HERE/hac_cli.js}"

#  1. Build the wasm CLI.
if [ "${SKIP_CLI_BUILD:-0}" != 1 ]; then
  echo ">>> Building wasm HAC CLI (hac_cli.js)..."
  make -C "$HERE" cli EMCC="$EMCC" EM_CACHE="$EM_CACHE" GPRBUILD="$GPRBUILD"
fi
test -f "$HERE/hac_cli.js" || { echo "!!! hac_cli.js not found"; exit 1; }

#  2. Build the native orchestrator.
if [ "${SKIP_ORCH_BUILD:-0}" != 1 ]; then
  echo ">>> Building native orchestrator (all_silent_tests)..."
  ( cd "$TEST_DIR" && $GPRBUILD -p -P hac_test.gpr all_silent_tests.adb )
fi
test -x "$TEST_DIR/all_silent_tests" || { echo "!!! all_silent_tests not built"; exit 1; }

#  3. Native `hac` for remarks_check's inner sub-compilations.  remarks_check
#     reads `hac_command`; when it points at a custom HAC (the wasm CLI by
#     default), the inner calls use that and no native binary is needed.  Build
#     native hac only when no such command is in play (HAC_CMD empty), so the
#     inner hac/ fallback still resolves -- legacy behaviour unchanged.
if [ -z "$HAC_CMD" ]; then
  NATIVE_HAC="$HAC_DIR/hac"
  if [ ! -x "$NATIVE_HAC" ] || head -1 "$NATIVE_HAC" 2>/dev/null | grep -q '^#!'; then
    echo ">>> Building native hac (needed by remarks_check)..."
    ( cd "$HAC_DIR" && $GPRBUILD -p -P hac.gpr )
  fi
fi

#  4. Run the suite, telling the orchestrator to drive the wasm CLI under node.
#     Setting hac_command also makes the orchestrator skip its own gprbuild step,
#     and remarks_check reads the same variable for its inner sub-compilations,
#     so every test (including those inner calls) runs through the wasm CLI.
echo ">>> Running all_silent_tests against the wasm HAC: [$HAC_CMD]"
echo
( cd "$TEST_DIR" && hac_command="$HAC_CMD" ./all_silent_tests )
