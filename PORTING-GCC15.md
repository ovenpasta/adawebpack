# AdaWebPack GCC 15 Porting Notes

This document covers the runtime-side GCC 15 porting work that belongs in the
`adawebpack` repository.

## Why This Port Is Needed

GCC 15 replaced `System.Finalization_Masters` (`s-finmas`) with
`System.Finalization_Primitives` (`s-finpri`).

The AdaWebPack WASM runtime was written against the GCC 14 finalization API, so
the runtime build had to be updated for:

- `s-finpri`
- the new `s-stposu` design
- dummy OS locks via `s-oslock__dummy.ads`

The compiler side still expects one small upstream GCC 15 patch for
`Repinfo`; see `gnat-llvm/llvm-interface/patches/gcc-15-repinfo-accessors.patch`.

## Runtime Files

### New runtime files

- `source/rtl/s-finpri__wasm.adb`
- `source/rtl/s-imagei__wasm.adb`
- `source/rtl/s-imageu__wasm.adb`
- `source/rtl/a-nbnbig.adb`
- `source/rtl/a-nbnbig.ads`

### Modified runtime files

- `source/rtl/Makefile.target`
- `source/rtl/s-stposu__wasm.adb`
- `source/rtl/a-except.adb`
- `source/rtl/a-except.ads`
- `gnat/adawebpack_config.gpr`

## Main Runtime Changes

### Finalization

- `s-finmas.ads` / `s-finmas__wasm.adb` are gone
- `s-finpri.ads` is used instead
- `s-finpri__wasm.adb` provides a WASM-specific body with no-op locking and no
  exception propagation support

### Storage pools and subpools

- `s-stposu__wasm.adb` was rewritten against the GCC 15 version
- old `Finalization_Masters` logic was removed
- exception-handling code paths were dropped for the WASM runtime

### Exception support

- `a-except.ads` / `a-except.adb` were simplified
- `Exception_Occurrence` support was removed from the local WASM runtime
- this avoids extra compiler failures and matches the limited exception support
  on WASM

### Ghost generic workaround

The current GNAT-LLVM compiler still trips on some ghost generic instantiations
in the GCC 15 runtime sources. The local runtime therefore:

- removes `a-nbnbig.*` from normal use
- replaces `s-imagei.adb` and `s-imageu.adb` with WASM-local versions that
  remove ghost proof dependencies

### Runtime package layout

The WASM runtime is emitted as a packaged runtime root consumed via
`--RTS=`. See `gnat-llvm/llvm-interface/SEPARATE-RUNTIMES.md` for the
full layout and `--RTS` usage. Build commands are in `BUILD-WASM.md`.
Example build instructions are in `README.md` and `examples/sdl3/README.md`.

## Why rts-wasm-emcc exists

When linking Ada with Emscripten-built libraries (SDL3 etc.), the original
`rts-wasm` runtime (TLSF allocator) caused `RuntimeError: function signature
mismatch` crashes at runtime. The root cause: Ada's TLSF exports `malloc`,
`free`, and `realloc` as WASM functions, shifting the indices of other
libraries' hardcoded allocator-hook entries in the WASM function table.
SDL's internal hint hash-table also got heap blocks freed by `SDL_Init`
reallocated by Ada's `New_String` calls inside `SDL_AppInit`, corrupting
live SDL structs (heap aliasing between two independent allocators).

`rts-wasm-emcc` was created to fix both symptoms: Ada's `System.Memory`
delegates to Emscripten's `malloc`/`free`/`realloc` via C imports instead
of exporting its own. Ada does not add any entries to the WASM function
table for allocation, and all code shares a single heap with no aliasing.
