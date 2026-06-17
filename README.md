[![Build binaries](https://github.com/godunko/adawebpack/actions/workflows/build.yml/badge.svg)](https://github.com/godunko/adawebpack/actions/workflows/build.yml)

# AdaWebPack
AdaWebPack provides the WebAssembly runtime and Web API bindings used with the
generic GNAT-LLVM compiler.

## How to install

Prebuild packages are available on [Release page](https://github.com/godunko/adawebpack/releases).

You will also need `wasm-ld`, the Web asssembly linker. You will find this:

 * on Fedora Linux through the `lld` package;
 * on Ubuntu through the `lld-16` package;
 * on other Linux systems look for a similarly-named package.

## How to build

 * Setup GNAT using [Alire](https://alire.ada.dev/).

 * Clone [GNAT-LLVM](https://github.com/ovenpasta/gnat-llvm). Use branch
   `gcc-16`.
   ```
   git clone --branch=gcc-16 https://github.com/ovenpasta/gnat-llvm
   ```

   This repository now expects a GCC 16-compatible GNAT-LLVM tree with the
   required target-conditional WebAssembly compiler support already present in
   the checked-out branch. No `patch -p1 < adawebpack_src/patches/*.patch`
   step is needed.

 * Clone [llvm-bindings](https://github.com/AdaCore/llvm-bindings) into the
   `gnat-llvm` checkout.
   ```
   git clone https://github.com/AdaCore/llvm-bindings gnat-llvm/llvm-bindings
   ```

 * Clone [bb-runtimes](https://github.com/ovenpasta/bb-runtimes). Use the
   GCC 15 branch `gnat-fsf-15`.
   ```
   git clone -b gnat-fsf-15 https://github.com/ovenpasta/bb-runtimes gnat-llvm/llvm-interface/bb-runtimes
   ```

 * Clone GCC sources and apply the GNAT-LLVM GCC 16 patch.
   ```
   git clone https://github.com/gcc-mirror/gcc.git gnat-llvm/llvm-interface/gcc
   git -C gnat-llvm/llvm-interface/gcc apply ../patches/gcc-16-repinfo-accessors.patch
   ```

   This is a small `Repinfo` accessor patch required by the current
   `gnat-llvm` branch when building against upstream GCC 16 sources.

 * Setup GNAT-LLVM development environment, see details in
   [GNAT-LLVM README](https://github.com/ovenpasta/gnat-llvm). Note, you need to use
   externally build LLVM with enabled 'lld' project and 'WebAssembly' target,
   so, if you build it your-self, `cmake` command line should contain among other switches:

   ```
   cmake ... -DLLVM_ENABLE_PROJECTS='...;clang;lld' -DLLVM_TARGETS_TO_BUILD="...;WebAssembly"
   ```

   On Ubuntu it is possible to install prebuilt LLVM/Clang packages. However,
   alternatives need to be updated using the provided script:

   ```
   sudo utilities/update-alternatives-clang.sh 21 100
   ```

   Or install an [LLVM 21 binary release](https://github.com/llvm/llvm-project/releases)
   (`llvm-21`, `lld-21` and `clang-21` are required).

 * Checkout AdaWebPack repository into `gnat-llvm/llvm-interface` as
   `adawebpack_src` and replace the tracked `Makefile.target` stub with the
   AdaWebPack runtime fragment.

   ```
   cd gnat-llvm/llvm-interface
   git clone --branch=gcc-16-wasm-rts https://github.com/ovenpasta/adawebpack.git adawebpack_src
   mv Makefile.target Makefile.target.orig
   ln -s adawebpack_src/source/rtl/Makefile.target Makefile.target
   cd -
   ```

 * Create a link to RTS source code
   ```
   cd gnat-llvm/llvm-interface
   ln -s bb-runtimes/gnat_rts_sources/include/rts-sources/
   cd -
   ```

 * Create a link to GNAT source code (or copy it)
   ```
   cd gnat-llvm/llvm-interface
   ln -s gcc/gcc/ada gnat_src
   cd -
   ```

 * Build the GNAT-LLVM compiler.
   ```
   cd gnat-llvm/llvm-interface
   make build
   cd -
   ```

   By default, GNAT-LLVM links against `clangBasic`, so a plain:

   ```
   cd gnat-llvm/llvm-interface
   make build
   cd -
   ```

   uses the default `clang` / `llvm-config` toolchain on your `PATH`.

   If that default Clang install exposes the monolithic unversioned
   `clang-cpp` library instead of split Clang libraries, use:

   ```
   cd gnat-llvm/llvm-interface
   make build CLANG_LINK_LIB=clang-cpp
   cd -
   ```

   On Arch Linux, use the versioned LLVM 21 tools explicitly when you want to
   pin the build to LLVM 21:

   ```
   cd gnat-llvm/llvm-interface
   export PATH=/usr/lib/llvm21/bin:$PATH
   make build LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
   cd -
   ```

   This was verified from a fresh copy of the tree after installing
   `llvm-config-21` and the matching LLVM 21 toolchain.

   If the built tools cannot locate LLVM shared libraries at runtime, pass
   `LD_LIBRARY_PATH` when invoking `make`:

   ```
   cd gnat-llvm/llvm-interface
   LD_LIBRARY_PATH=/usr/lib make build
   cd -
   ```

   If you build with an Alire-provided GNAT toolchain, `default.cgpr` may
   retain toolchain paths from an earlier configuration. Remove it before
   rebuilding if you need the build to re-detect the active toolchain:

   ```
   cd gnat-llvm/llvm-interface
   rm -f default.cgpr
   cd -
   ```

   On some Linux distributions, the Alire-selected linker fails while linking
   against the LLVM/Clang static libraries. Use `lld` explicitly instead of
   replacing `ld` with a symlink:

   ```
   cd gnat-llvm/llvm-interface
   make build CXXFLAGS=-fuse-ld=lld
   cd -
   ```

 * Build the WebAssembly runtime packages.

   There are two runtime variants:

   **`rts-wasm`** - Ada's built-in TLSF allocator. Ada owns `malloc`/`free`/
   `realloc`. Use for standalone WASM targets without Emscripten.

   **`rts-wasm-emcc`** - Delegates to Emscripten's dlmalloc. Ada, SDL, and the
   C library all share one allocator with no WASM function-table conflicts.
   Required for SDL3 and other Emscripten-linked examples.

   ```
   cd gnat-llvm/llvm-interface
   make wasm       # -> lib/gnat-llvm/wasm32/rts-wasm/
   make wasm-emcc  # -> lib/gnat-llvm/wasm32/rts-wasm-emcc/
   cd -
   ```

   If your default Clang install uses the monolithic `clang-cpp` library:

   ```
   make wasm CLANG_LINK_LIB=clang-cpp
   make wasm-emcc CLANG_LINK_LIB=clang-cpp
   ```

   On Arch Linux with pinned LLVM 21:

   ```
   cd gnat-llvm/llvm-interface
   export PATH=/usr/lib/llvm21/bin:$PATH
   make wasm LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
   make wasm-emcc LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
   cd -
   ```

   If the built tools cannot locate LLVM shared libraries at runtime:

   ```
   LD_LIBRARY_PATH=/usr/lib make wasm
   LD_LIBRARY_PATH=/usr/lib make wasm-emcc
   ```

   Alire linker workaround (if needed):

   ```
   make wasm CXXFLAGS=-fuse-ld=lld
   make wasm-emcc CXXFLAGS=-fuse-ld=lld
   ```

 * When `make` finishes, you will find the toolchain in
   `gnat-llvm/llvm-interface/bin` and the packaged WASM runtime in
   `gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm`.

 * Current verified Arch result:
   - a fresh out-of-tree build of `make build` succeeded with
     `LLVM_CONFIG=llvm-config-21` and `CLANG_LINK_LIB=':libclang-cpp.so.21.1'`
   - a fresh out-of-tree build of `make wasm` also succeeded with the same
     LLVM 21 selection plus `WASM_C_ALLOCATOR_EXPORTS=no`
   - `Ada.Strings.Fixed` is intentionally not packaged in `rts-wasm` for now
     because its current `wasm32` compile path in `llvm-gcc` still hits a
     frontend assertion; see
     `examples/tests/STRINGS_FIXED_REPORT.md`
     for the current reduction and findings

 * Add the compiler tools to your `PATH`.
   ```
   cd gnat-llvm/llvm-interface
   export PATH=$PWD/bin:$PATH
   cd -
   ```

 * Build the examples against the packaged runtime:
   ```
   cd gnat-llvm/llvm-interface
   PATH=$PWD/bin:$PATH \
     make -C adawebpack_src build_examples \
       GPRBUILD_FLAGS="--target=llvm --RTS=$PWD/lib/gnat-llvm/wasm32/rts-wasm"
   cd -
   ```
   You will most likely need to run the examples through an HTTP server;
   otherwise, the browser will report a security error and/or refuse to load the page.
   An easy way to obtain an HTTP server is by via Python 3 with `python3 -m http.server`.

 * Additional runtime-side GCC 15 details are documented in
   [PORTING-GCC15.md](PORTING-GCC15.md).

## Runtime variant comparison

The two WASM runtimes share a common source base but differ in several
user-visible features:

| Feature | rts-wasm | rts-wasm-emcc |
|---------|----------|---------------|
| Allocator | Ada-owned TLSF (exports `malloc`/`free`/`realloc`) | Emscripten dlmalloc (Ada calls Emscripten's allocator) |
| `Duration` size | 32-bit | 64-bit (nanosecond precision) |
| `Ada.Calendar` | not available | available |
| `System.OS_Primitives.Clock` | not available | available (`clock_gettime`) |
| `delay` / `delay until` | not available | available (see note below) |
| Requires Emscripten (`emcc`) | no | yes |

### 32-bit Duration in rts-wasm

`rts-wasm` uses a 32-bit `Duration` type with a maximum range of roughly
+/-497 days. `Ada.Calendar` requires 64-bit Duration internally (the
calendar body uses `Unchecked_Conversion` between `Duration` and a 64-bit
integer, which fails if they differ in size). This is why `Ada.Calendar`
is not included in `rts-wasm`.

If your application uses `delay` statements or `Ada.Calendar`, use
`rts-wasm-emcc`.

### Timed delay and Emscripten Asyncify

In `rts-wasm-emcc`, `delay` and `delay until` call Emscripten's `nanosleep`.
Without Asyncify, Emscripten's `nanosleep` busy-waits for the requested
duration - the WASM module spins on the browser's main thread, making the
page unresponsive for the full duration of the delay.

To get proper timed delays that yield to the browser event loop, link with
the Asyncify transformation:

```
emcc ... -sASYNCIFY
```

Asyncify rewrites the WASM binary to allow suspending and resuming execution.
Per Emscripten's documentation, the overhead is typically around 50% in
binary size when optimized (`-O3`). Applications that do not use `delay`
can omit `-sASYNCIFY`.

## Runtime library features

The Ada standard library units below are packaged in both `rts-wasm` and
`rts-wasm-emcc` and are available without `--RTS=` tweaks. Where the two
runtimes diverge - notably for file-based Text I/O - the per-runtime
behaviour is called out in the relevant subsection.

### Text I/O

The two runtimes ship two different `Ada.Text_IO` surfaces. The integer and
float Text_IO packages described below are the same in both.

#### `rts-wasm` - stripped, console-only

`Ada.Text_IO` is shipped as a stripped, ZFP-style variant:

- `Put`, `Put_Line`, `New_Line`, `Put (Character)` write to the JS/Emscripten
  console through `System.IO` (`__gnat_put_char` / `__gnat_put_string`).
- `Get (Character)` is present for source compatibility but returns
  `ASCII.NUL`. There is no blocking console read in the browser; wire a JS
  shim if real input is needed.
- No `File_Type`, no `Open` / `Create`, no file I/O. The standalone TLSF
  runtime has no libc and no virtual filesystem to back file objects.

#### `rts-wasm-emcc` - full upstream `Ada.Text_IO` over Emscripten libc

The Emscripten variant ships the full upstream `Ada.Text_IO`:

- `Create`, `Open`, `Close`, `Reset`, `Delete`, `Mode`, `Name`, `Form`.
- `Put_Line (File, ...)`, `Get_Line (File, ...)`, `Put (File, ...)`, `Get
  (File, ...)`, `New_Line (File)`, `Skip_Line (File)`, etc.
- `Standard_Input` / `Standard_Output` / `Standard_Error` and the
  `Current_Input` / `Current_Output` / `Current_Error` set.

Files are backed by Emscripten's libc on top of MEMFS by default. To
populate the virtual filesystem with real assets at link time, pass
`--preload-file <host-path>` or `--embed-file <host-path>` to the final
`emcc` link command. To persist between runs in the browser, mount IDBFS
from JS before the Ada main runs. MEMFS contents are otherwise ephemeral
and disappear when the WASM module is torn down.

Behind the scenes the Emscripten runtime brings in upstream
`System.File_IO`, `Interfaces.C_Streams`, `System.File_Control_Block`, and
the standard `Get_Line` subunit. A small Emscripten-only C shim
(`text_io_emcc_shim.c`) supplies the `__gnat_*` constants/wrappers that
upstream normally pulls from `gcc/ada/sysdep.c` and `gcc/ada/cstreams.c`.

What is *not* included even in `rts-wasm-emcc`:

- `Ada.Streams.Stream_IO` (uses the same `s-fileio` backbone, but not
  packaged here yet).
- `Ada.Wide_Text_IO`, `Ada.Wide_Wide_Text_IO`,
  `Ada.Text_IO.Editing` / `Unbounded_IO` / `Enumeration_IO`.
- `Ada.Directories`.

#### Integer / Float Text I/O (both runtimes)

`Ada.Integer_Text_IO` and `Ada.Float_Text_IO` are packaged as stripped
generic instantiations:

- String-based `Put (To, Item, ...)` and `Get (From, Item, Last)` are
  available for both integer and floating-point types.
- Console `Put (Item, ...)` writes through `System.IO`.
- `Ada.Integer_Text_IO` uses a hand-rolled base converter so it does not
  depend on `System.Val_Int` / `System.Val_LLI` scanner variants beyond
  what the RTS already ships.
- `Ada.Float_Text_IO.Put` goes through `System.Img_Real.Set_Image_Real`
  (same as upstream). `Get` routes through `System.Val_LFlt`
  (`Value_Long_Float`), i.e. the scanner precision is `Long_Float`
  regardless of the actual `Num` type - this keeps the runtime from
  needing the per-precision scanner packages (`s-valflt`, `s-valllf`,
  `s-powten_*`).
- The user-facing generic packages `Ada.Text_IO.Integer_IO` and
  `Ada.Text_IO.Float_IO` are also exposed so you can instantiate them on
  your own scalar types.

Typical pattern:

```ada
with Ada.Text_IO;
with Ada.Float_Text_IO;
package FIO renames Ada.Float_Text_IO;
Buf : String (1 .. 64);
V   : Float := 3.14159;
FIO.Put (Buf, V, Aft => 3, Exp => 0);
Ada.Text_IO.Put_Line (Buf);
```

### Containers

Both definite and indefinite container variants are packaged:

- Definite: `Ada.Containers.Vectors`, `Doubly_Linked_Lists`, `Hashed_Maps`,
  `Hashed_Sets`, `Ordered_Maps`, `Ordered_Sets`, `Multiway_Trees`.
- Indefinite: `Indefinite_Vectors`, `Indefinite_Doubly_Linked_Lists`,
  `Indefinite_Hashed_Maps`, `Indefinite_Hashed_Sets`,
  `Indefinite_Ordered_Maps`, `Indefinite_Ordered_Sets`,
  `Indefinite_Holders`, `Indefinite_Multiway_Trees`.

The container bodies are the upstream sources, used unchanged.

### Strings

- `Ada.Strings.Hash` is available, so container instantiations like
  `Indefinite_Hashed_Maps (Key_Type => String, ...)` work without a
  user-supplied hash function.
- `Ada.Strings.Fixed` is intentionally not packaged in `rts-wasm` yet - its
  `wasm32` compile path still hits a frontend assertion; see
  `examples/tests/STRINGS_FIXED_REPORT.md`.

## Usage with Docker

It could be handy to use docker.
* Find latest build on our [Fedora COPR](https://copr.fedorainfracloud.org/coprs/reznik/adawebpack/) repository.
* Build a container image (make sure to replace `curl` argument with latest RPM URL)
  ```
  docker build --tag wgprbuild - <<EOF
  FROM registry.fedoraproject.org/fedora-minimal:40
  RUN microdnf --assumeyes install \
    gprbuild \
    clang16 \
    llvm16 \
    lld \
    libgnat \
    ca-certificates && \
  curl -O \
  https://download.copr.fedorainfracloud.org/results/reznik/adawebpack/fedora-40-x86_64/07674186-adawebpack/adawebpack-24.0.0-git.fc40.x86_64.rpm && \
  rpm -i adawebpack*.rpm && \
  rm -f adawebpack*.rpm && \
  /usr/share/adawebpack/update-alternatives-clang.sh 16 99 && \
  microdnf clean all
  EOF
  ```
* Write a `bash` wrapper script to replace `gprbuild` like this:
  ```bash
  #!/bin/bash
  exec docker run --rm --tmpfs /tmp/ --user $UID --volume $HOME:$HOME --workdir $PWD wgprbuild gprbuild "$@"
  ```


## Unsupported features

 - nested subprograms are not supported

 - exceptions support is limited to local exceptions propagation and last
   chance handler

 - tasks and protected objects are not supported

 - file-based `Ada.Text_IO` (`Open`, `Create`, `File_Type`, etc.) is
   available only in `rts-wasm-emcc` over Emscripten's MEMFS/NODEFS/IDBFS;
   `rts-wasm` ships only the stripped, console-only variant. See the "Text
   I/O" subsection for details.

## License

Web API bindings is licensed under BSD3 license.

GNAT Runtime Library is licensed under GPL3 license with GCC Runtime Library Exception.
