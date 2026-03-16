# ABI Tests

Minimal wasm ABI repros collected in one directory.
All targets link with Emscripten (`emcc`) and use `rts-wasm-emcc`.

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
make debug_text_signature_main.html
make strings_fixed_main.html
```

## Targets

- `record_by_value_main` - wasm32 C ABI struct pass/return test
- `debug_text_signature_main` - ABI-shape probe for `SDL_RenderDebugText` call pattern
- `strings_fixed_main` - experimental; not part of `make all`

## record_by_value_main

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

## Expected result

All targets build and link cleanly with no
`wasm-ld: warning: function signature mismatch` output.

`strings_fixed_main` is not part of `make all` and may not build;
`Ada.Strings.Fixed` is not included in the wasm runtimes.
