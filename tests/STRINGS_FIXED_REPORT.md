# Ada.Strings.Fixed on wasm32

**Status: RESOLVED.** `Ada.Strings.Fixed` compiles and links in both
`rts-wasm` and `rts-wasm-emcc`. `strings_fixed_main` is now part of `make all`.
The frontend crash described below no longer reproduces on GCC 16 / LLVM 21.

---

## Historical investigation (no longer relevant)

`Ada.Strings.Fixed` was previously not usable from the `rts-wasm` flow when
compiled by `llvm-gcc` for `wasm32`.

This is not a general GNAT issue and not a general GNAT-LLVM issue:

- native GNAT compiles the relevant units
- native `llvm-gcc` compiles the relevant units
- the failure appears specifically with `llvm-gcc --target=wasm32`

The failure first appeared while trying to add `Ada.Strings.Fixed`,
`Ada.Strings.Search`, and `Ada.Strings.Maps` to `rts-wasm`.

## Current Runtime State

`Ada.Strings.Fixed`, `Ada.Strings.Search`, and `Ada.Strings.Maps` are
currently intentionally left out of `rts-wasm`.

They were added experimentally to
`adawebpack_src/source/rtl/Makefile.target` during investigation, but that
change has been reverted for now because the `wasm32` compile path is still
failing.

Observed compile results for the runtime units under the real runtime compile
flags (`-gnatpg -nostdinc -I../adainclude`):

- `a-strmap.adb`: compiles on wasm
- `a-strsea.adb`: crashes frontend on wasm
- `a-strfix.adb`: crashes frontend on wasm

The crash is:

```text
Assert_Failure sem_ch12.adb:18668
```

with reported source locations:

- `a-strsea.adb` path: `gcc/gcc/ada/libgnat/a-except.ads:57`
- `a-strfix.adb` path: `gcc/gcc/ada/libgnat/s-stoele.ads:104`

Those reported lines are not the true root cause. They are where semantic
analysis notices corrupted generic-renaming state.

## What Was Ruled Out

The issue is not:

- a broken upstream `libgnat` source file
- a normal GNAT frontend bug on native target
- a general `llvm-gcc` frontend bug on native target
- a generic failure of all `Ada.Strings.Fixed` references
- a generic failure of all `String` result contracts
- a generic failure of all `Ada.*` runtime descendants with contracts

Verified:

- native GNAT 15.2.1 compiles `a-strmap.adb`, `a-strsea.adb`, `a-strfix.adb`
  with `-gnatpg`
- native `llvm-gcc` compiles the same units with `-gnatpg`
- a minimal `with Ada.Strings.Fixed;` program compiles for `wasm32`
- a minimal package with `String`-returning functions and `'Result` contracts
  compiles for `wasm32`
- a minimal `Ada.*` package with `Head`-like contracts also compiles for
  `wasm32`

## User-Side Reduction

The most useful reduction is on direct user calls under:

```text
llvm-gcc --target=wasm32 -c -gnatp ...
```

These calls compile:

- `Ada.Strings.Fixed.Count`
- `Ada.Strings.Fixed.Find_Token`
- `Ada.Strings.Fixed.Translate` with `Character_Mapping`
- `Ada.Strings.Fixed.Replace_Slice`

These calls crash the frontend:

- `Ada.Strings.Fixed.Insert`
- `Ada.Strings.Fixed.Overwrite`
- `Ada.Strings.Fixed.Delete`
- `Ada.Strings.Fixed.Trim`
- `Ada.Strings.Fixed.Head`
- `Ada.Strings.Fixed.Tail`

This means the first public failing boundary inside
`gcc/gcc/ada/libgnat/a-strfix.ads` is `Insert`.

`Replace_Slice` still works, `Insert` is the first declaration that reproduces
the crash.

## Semantic Clue

The assert comes from:

`gcc/gcc/ada/sem_ch12.adb:18668`

inside `Instance_Context.Save_And_Reset`, while saving the
`Generic_Renamings` table. The assertion means semantic analysis reached a
state where an entry in that table is invalid before the last slot.

That indicates:

- a semantic-analysis corruption issue
- specific to the `wasm32` path used by `llvm-gcc`
- exposed by the declaration set in `Ada.Strings.Fixed`

## Best Current Interpretation

This is a `wasm32`-specific compiler issue exposed by the real
`Ada.Strings.Fixed` public specification and runtime build flow.

It is not explained by one simple source construct in isolation. Small probes
that mimic:

- `String` results
- `'Result` contracts
- `Contract_Cases`
- `Ada.*` runtime package structure

do not reproduce the crash by themselves.

The trigger depends on the cumulative semantic state built up while analyzing
the actual `Ada.Strings.Fixed` declarations, with the first fatal point at
`Insert`.

## Recommended Next Step

The shortest remaining reduction is:

1. Copy the public part of `a-strfix.ads` into a temporary test spec.
2. Keep only declarations up to `Insert`.
3. Trim backward until the smallest reproducing subset remains.

That should isolate the exact declaration combination that corrupts
`Generic_Renamings` on `wasm32`.

## Relevant Files

- `adawebpack_src/examples/tests/README.md`
- `adawebpack_src/examples/tests/strings_fixed_main.adb`
- `adawebpack_src/source/rtl/Makefile.target`
- `gcc/gcc/ada/libgnat/a-strfix.ads`
- `gcc/gcc/ada/libgnat/a-strsea.adb`
- `gcc/gcc/ada/sem_ch12.adb:18668`
