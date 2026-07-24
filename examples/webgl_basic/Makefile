LLVM_INTERFACE_DIR := $(abspath ../../..)

GPRBUILD ?= gprbuild
#  Standalone (no Emscripten) EH runtime: full Ada exception propagation
#  via native WebAssembly exception handling.
ADA_RTS ?= $(LLVM_INTERFACE_DIR)/lib/gnat-llvm/wasm32/rts-wasm-eh
GPRBUILD_FLAGS ?= --target=llvm --RTS=$(ADA_RTS)

all: adawebpack.mjs
	$(GPRBUILD) $(GPRBUILD_FLAGS) -p -P test.gpr

adawebpack.mjs:
	ln -s ../../source/adawebpack.mjs

clean:
	rm -rf .objs main.wasm adawebpack.mjs
