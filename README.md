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
   `wasm-backend`.
   ```
   git clone --branch=wasm-backend https://github.com/ovenpasta/gnat-llvm
   ```

   This repository now expects a GCC 15-compatible GNAT-LLVM tree with the
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

 * Clone [GCC](https://github.com/gcc-mirror/gcc) sources. Use a GCC 15 release branch or tag.
   ```
   git clone --single-branch --branch=releases/gcc-15 https://github.com/gcc-mirror/gcc gnat-llvm/llvm-interface/gcc
   git -C gnat-llvm/llvm-interface/gcc checkout releases/gcc-15.2.0
   git -C gnat-llvm/llvm-interface/gcc apply ../patches/gcc-15-repinfo-accessors.patch
   ```

   This is a small `Repinfo` accessor patch required by the current
   `gnat-llvm` branch when building against upstream GCC 15 sources.

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
   git clone --branch=gcc-15-wasm-rts https://github.com/ovenpasta/adawebpack.git adawebpack_src
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

   On Arch Linux, some LLVM/Clang packages require the monolithic
   `clang-cpp` library:

   ```
   cd gnat-llvm/llvm-interface
   make build CLANG_LINK_LIB=clang-cpp
   cd -
   ```

   If the built tools cannot locate LLVM shared libraries at runtime, pass
   `LD_LIBRARY_PATH` when invoking `make`:

   ```
   cd gnat-llvm/llvm-interface
   LD_LIBRARY_PATH=/usr/lib make build
   cd -
   ```

 * Use `make wasm` to build the WebAssembly runtime package
   ```
   cd gnat-llvm/llvm-interface
   make wasm
   cd -
   ```

   On Arch Linux:

   ```
   cd gnat-llvm/llvm-interface
   make wasm CLANG_LINK_LIB=clang-cpp
   cd -
   ```

   If the built tools cannot locate LLVM shared libraries at runtime, pass
   `LD_LIBRARY_PATH` when invoking `make`:

   ```
   cd gnat-llvm/llvm-interface
   LD_LIBRARY_PATH=/usr/lib make wasm
   cd -
   ```

 * When `make` finishes, you will find the toolchain in
   `gnat-llvm/llvm-interface/bin` and the packaged WASM runtime in
   `gnat-llvm/llvm-interface/lib/gnat-llvm/wasm32/rts-wasm`.

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

## License

Web API bindings is licensed under BSD3 license.

GNAT Runtime Library is licensed under GPL3 license with GCC Runtime Library Exception.
