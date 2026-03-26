# WASM Tests

Tests for the WASM runtimes. All targets link with Emscripten (`emcc`) and
use `rts-wasm-emcc`.

## Build

Build all:

```sh
cd llvm-interface/adawebpack_src/tests
PATH=/path/to/llvm-interface/bin:$PATH \
  make EMCC=/usr/lib/emscripten/emcc
```

If `gprbuild` is not on `PATH`, pass it via `GPRBUILD`:

```sh
PATH=/path/to/llvm-interface/bin:$PATH \
  make EMCC=/usr/lib/emscripten/emcc GPRBUILD="alr exec -- gprbuild"
```

Build one:

```sh
make record_by_value_main.html
make containers_main.html
make delay_main.html
```

## Targets

### ABI tests

- `record_by_value_main` - wasm32 C ABI struct pass/return test
- `debug_text_signature_main` - ABI-shape probe for `SDL_RenderDebugText` call pattern
- `interfaces_c_strings_main` - `Interfaces.C.Strings` bindings test
- `strings_fixed_main` - experimental; not part of `make all`

### Runtime feature tests (rts-wasm-emcc)

- `containers_main` - `Ada.Containers.Vectors`, `Doubly_Linked_Lists`, `Ordered_Maps`
- `calendar_main` - `Ada.Calendar.Clock`, `Year`, monotonic time checks
- `delay_main` - `delay` statement timing (requires `-sASYNCIFY` at link time)

## Test descriptions

### record_by_value_main

Tests both directions of the wasm32 C ABI struct fix.

**Pass direction** (Ada passes `C_Pass_By_Copy` record to C):

Ada previously lowered the record parameter as expanded fields:
```
record_by_value_call: (i32, i32) -> i32   (wrong)
```
The wasm32 C ABI passes structs by pointer:
```
record_by_value_call: (i32) -> i32        (correct)
```
Fixed in `Get_Param_Kind`: `Foreign_By_Ref` (pointer) is now used for
foreign-convention record parameters on wasm32 instead of `In_Value`.

**Return direction** (C returns record to Ada):

No fix needed. LLVM's wasm32 backend maps `{i32, i32}` return type to
wasm multivalue return, which matches what Clang generates for the same
C struct. The test exercises this path to confirm it stays correct.

### containers_main

Instantiates three container packages inside a procedure body (which exercises
the GNAT-LLVM trampoline-suppression fix for wasm32) and exercises each one:

- `Ada.Containers.Vectors (Natural, Integer)`: Append, Length, Element, Delete_Last
- `Ada.Containers.Doubly_Linked_Lists (Integer)`: Append, Prepend, Length, First/Last
- `Ada.Containers.Ordered_Maps (Integer, Integer)`: Insert, Contains, Element, Delete


### calendar_main

Checks `Ada.Calendar` (rts-wasm-emcc only):

- `Clock` returns a year in the range 2020..2100
- Two consecutive `Clock` calls are monotonic
- The elapsed Duration is non-negative

### delay_main

Measures `delay 0.1` using `Ada.Calendar.Clock`:

- Elapsed time is at least 50 ms (generous tolerance for timer resolution)
- Elapsed time is under 5 s (sanity bound)

Linked with `-sASYNCIFY` so that `nanosleep` yields to the browser event loop
rather than busy-waiting. Without `-sASYNCIFY` the test still passes (busy-wait
returns quickly), but the browser tab is blocked for 100 ms.

## Expected result

All targets build and link cleanly.

Serve the directory with `python3 -m http.server` and open in a browser.
Each test prints one line per check:

```
check-name: PASS
```

(or `FAIL (reason)` if a check fails).

`strings_fixed_main` is not part of `make all` and may not build;
`Ada.Strings.Fixed` is not included in the wasm runtimes.
