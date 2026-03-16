# SDL3

This directory contains the SDL3 browser example suite.

Current example directories:

- `basic` for the Ada SDL3 baseline
- `basic_c` for the matching C baseline
- `image` for the Ada SDL3_image example
- `ttf` for the Ada SDL3_ttf example
- `bindings` for the shared Ada import specs

## Prerequisites

- `emcc` and `emcmake` in `PATH` (if not on PATH, pass `EMCC=/usr/lib/emscripten/emcc` to make)
- `cmake`
- `ninja` or another CMake generator
- a built GNAT-LLVM toolchain under `../../../bin`
- a packaged Emscripten wasm Ada runtime under `../../../lib/gnat-llvm/wasm32/rts-wasm-emcc`

All commands below assume:

```sh
cd llvm-interface/adawebpack_src/examples/sdl3
```

## 1. Build the Emscripten Wasm Ada Runtime

The SDL examples require the `rts-wasm-emcc` runtime, which delegates all heap
allocation to Emscripten's dlmalloc so that Ada, SDL, and the C library share
a single allocator with no WASM function-table conflicts.

Run this from the top-level `llvm-interface` directory:

```sh
cd llvm-interface
make wasm-emcc
```

With a pinned LLVM 21 toolchain on Arch Linux:

```sh
cd llvm-interface
export PATH=/usr/lib/llvm21/bin:$PATH
make wasm-emcc LLVM_CONFIG=llvm-config-21 CLANG_LINK_LIB=':libclang-cpp.so.21.1'
```

The output is placed in `lib/gnat-llvm/wasm32/rts-wasm-emcc/`. The SDL
`common.mk` defaults `ADA_RTS` to this directory automatically.

## 2. Download and Build SDL3 for Emscripten

Download SDL3:

```sh
curl -L https://github.com/libsdl-org/SDL/releases/download/release-3.4.2/SDL3-3.4.2.tar.gz \
  -o SDL-release-3.4.2.tar.gz
tar -xf SDL-release-3.4.2.tar.gz
```

Configure, build, and install it:

```sh
emcmake cmake -S SDL-release-3.4.2 -B SDL-release-3.4.2-build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DCMAKE_INSTALL_PREFIX="$PWD/sdl3-prefix"
cmake --build SDL-release-3.4.2-build
cmake --install SDL-release-3.4.2-build
```

Expected outputs:

- `sdl3-prefix/include/SDL3`
- `sdl3-prefix/lib/libSDL3.a`
- `sdl3-prefix/lib/cmake/SDL3/SDL3Config.cmake`

## 3. Download and Build SDL3_image for Emscripten

This is needed by the `image` example.

Download SDL3_image:

```sh
curl -L https://github.com/libsdl-org/SDL_image/releases/download/release-3.4.0/SDL3_image-3.4.0.tar.gz \
  -o SDL3_image-3.4.0.tar.gz
tar -xf SDL3_image-3.4.0.tar.gz
```

Configure, build, and install it against the local SDL3 build:

```sh
EM_CACHE=/tmp/emscripten-cache \
emcmake cmake -S SDL3_image-3.4.0 -B SDL3_image-3.4.0-build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DSDLIMAGE_SAMPLES=OFF \
  -DSDLIMAGE_TESTS=OFF \
  -DSDL3_DIR="$PWD/SDL-release-3.4.2-build" \
  -DCMAKE_INSTALL_PREFIX="$PWD/sdl3-image-prefix"
EM_CACHE=/tmp/emscripten-cache cmake --build SDL3_image-3.4.0-build
cmake --install SDL3_image-3.4.0-build
```

Expected outputs:

- `sdl3-image-prefix/include/SDL3_image/SDL_image.h`
- `sdl3-image-prefix/lib/libSDL3_image.a`

## 4. Download and Build SDL3_ttf for Emscripten

This is needed by the `ttf` example.

Download SDL3_ttf:

```sh
curl -L https://github.com/libsdl-org/SDL_ttf/releases/download/release-3.2.2/SDL3_ttf-3.2.2.tar.gz \
  -o SDL3_ttf-3.2.2.tar.gz
tar -xf SDL3_ttf-3.2.2.tar.gz
```

Fetch the vendored third-party sources used by SDL3_ttf:

```sh
sh SDL3_ttf-3.2.2/external/download.sh --depth 1
```

Configure, build, and install it against the local SDL3 build:

```sh
EM_CACHE=/tmp/emscripten-cache \
emcmake cmake -S SDL3_ttf-3.2.2 -B SDL3_ttf-3.2.2-build \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DSDLTTF_VENDORED=ON \
  -DSDLTTF_HARFBUZZ=ON \
  -DSDLTTF_PLUTOSVG=OFF \
  -DSDLTTF_SAMPLES=OFF \
  -DSDLTTF_INSTALL=ON \
  -DSDL3_DIR="$PWD/SDL-release-3.4.2-build" \
  -DCMAKE_INSTALL_PREFIX="$PWD/sdl3-ttf-prefix"
EM_CACHE=/tmp/emscripten-cache cmake --build SDL3_ttf-3.2.2-build
cmake --install SDL3_ttf-3.2.2-build
```

Expected outputs:

- `sdl3-ttf-prefix/include/SDL3_ttf/SDL_ttf.h`
- `sdl3-ttf-prefix/lib/libSDL3_ttf.a`

## 5. Build the Examples

Build the currently wired examples:

```sh
make basic_c
make basic
make image
make ttf
```

Or build them all at once:

```sh
make
```

If `emcc` is not on `PATH` (e.g. on Arch Linux where it lives under
`/usr/lib/emscripten/`), pass it explicitly:

```sh
make EMCC=/usr/lib/emscripten/emcc GPRBUILD="alr exec -- gprbuild"
```

Generated outputs stay inside each example directory.

Current pages:

- `basic_c/basic_c.html`
- `basic/basic.html`
- `image/image.html`
- `ttf/ttf.html`

## 6. Run the Suite

Serve the suite root:

```sh
python -m http.server 8000
```

Then open:

- `http://localhost:8000/basic_c/basic_c.html`
- `http://localhost:8000/basic/basic.html`
- `http://localhost:8000/image/image.html`
- `http://localhost:8000/ttf/ttf.html`

## Notes

- The Ada examples use `gprbuild -c -b` and the final browser link is done
  with `emcc`.
- Shared Ada import specs live in `bindings/`.
- The SDL3_image and SDL3_ttf bindings were reduced from `gcc -fdump-ada-spec`
  output to just the imports currently used by the suite.
