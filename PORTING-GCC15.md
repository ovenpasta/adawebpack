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

The WASM runtime is now emitted as a packaged runtime root:

```text
lib/gnat-llvm/wasm32/rts-wasm/
  target.atp
  ada_source_path
  ada_object_path
  adainclude/
  adalib/
```

This is the runtime consumed by:

```bash
--RTS=/path/to/lib/gnat-llvm/wasm32/rts-wasm
```

## Build Commands

From `gnat-llvm/llvm-interface`:

```bash
make wasm
```

On Arch Linux:

```bash
make wasm CLANG_LINK_LIB=clang-cpp
```

If LLVM shared libraries are not found at runtime:

```bash
LD_LIBRARY_PATH=/usr/lib make wasm
```

## Example Builds

```bash
PATH=$PWD/bin:$PATH \
  make -C adawebpack_src build_examples \
    GPRBUILD_FLAGS="--target=llvm --RTS=$PWD/lib/gnat-llvm/wasm32/rts-wasm"
```

The currently verified examples are:

- `call_ada`
- `toggle_hidden`
- `webgl_basic`
