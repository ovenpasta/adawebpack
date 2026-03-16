SDL3_ROOT := $(abspath ..)
LLVM_INTERFACE_DIR := $(abspath ../../../..)
LLVM_BIN_DIR := $(LLVM_INTERFACE_DIR)/bin

EMCC ?= emcc
EM_CACHE ?= /tmp/emscripten-cache
GPRBUILD ?= gprbuild
LLVM_GCC ?= $(LLVM_BIN_DIR)/llvm-gcc
GNATBIND ?= $(LLVM_BIN_DIR)/llvm-gnatbind
LLVM_LIBRARY_PATH ?=
ADA_RTS ?= $(LLVM_INTERFACE_DIR)/lib/gnat-llvm/wasm32/rts-wasm-emcc
GPRBUILD_FLAGS ?= --target=llvm --RTS=$(ADA_RTS)

SDL3_PREFIX ?= $(SDL3_ROOT)/sdl3-prefix
SDL3_INCLUDE_DIR ?= $(SDL3_PREFIX)/include
SDL3_LIB ?= $(SDL3_PREFIX)/lib/libSDL3.a
SDL3_IMAGE_PREFIX ?= $(SDL3_ROOT)/sdl3-image-prefix
SDL3_IMAGE_INCLUDE_DIR ?= $(SDL3_IMAGE_PREFIX)/include
SDL3_IMAGE_LIB ?= $(SDL3_IMAGE_PREFIX)/lib/libSDL3_image.a
SDL3_TTF_PREFIX ?= $(SDL3_ROOT)/sdl3-ttf-prefix
SDL3_TTF_INCLUDE_DIR ?= $(SDL3_TTF_PREFIX)/include
SDL3_TTF_LIB ?= $(SDL3_TTF_PREFIX)/lib/libSDL3_ttf.a

EMCC_COMMON_FLAGS ?= -O2 -sALLOW_MEMORY_GROWTH=1
ADA_EMCC_FLAGS ?= -sSTACK_SIZE=8388608
SDL3_CFLAGS = -I$(SDL3_INCLUDE_DIR)
SDL3_LDFLAGS = $(SDL3_LIB)
SDL3_IMAGE_CFLAGS = -I$(SDL3_IMAGE_INCLUDE_DIR)
SDL3_IMAGE_LDFLAGS = $(SDL3_IMAGE_LIB)
SDL3_TTF_CFLAGS = -I$(SDL3_TTF_INCLUDE_DIR)
SDL3_TTF_LDFLAGS = $(SDL3_TTF_LIB)
ADA_RUNTIME_LIB = $(ADA_RTS)/adalib/libgnat.a

check-sdl3:
	@test -n "$(SDL3_PREFIX)" || { echo "Set SDL3_PREFIX to an SDL3 web install"; exit 1; }
	@test -d "$(SDL3_INCLUDE_DIR)/SDL3" || { echo "Missing SDL3 headers under $(SDL3_INCLUDE_DIR)"; exit 1; }
	@test -f "$(SDL3_LIB)" || { echo "Missing SDL3 library $(SDL3_LIB)"; exit 1; }

check-sdl3-image: check-sdl3
	@test -n "$(SDL3_IMAGE_PREFIX)" || { echo "Set SDL3_IMAGE_PREFIX to an SDL3_image web install"; exit 1; }
	@test -d "$(SDL3_IMAGE_INCLUDE_DIR)/SDL3_image" || { echo "Missing SDL3_image headers under $(SDL3_IMAGE_INCLUDE_DIR)"; exit 1; }
	@test -f "$(SDL3_IMAGE_LIB)" || { echo "Missing SDL3_image library $(SDL3_IMAGE_LIB)"; exit 1; }

check-sdl3-ttf: check-sdl3
	@test -n "$(SDL3_TTF_PREFIX)" || { echo "Set SDL3_TTF_PREFIX to an SDL3_ttf web install"; exit 1; }
	@test -d "$(SDL3_TTF_INCLUDE_DIR)/SDL3_ttf" || { echo "Missing SDL3_ttf headers under $(SDL3_TTF_INCLUDE_DIR)"; exit 1; }
	@test -f "$(SDL3_TTF_LIB)" || { echo "Missing SDL3_ttf library $(SDL3_TTF_LIB)"; exit 1; }

check-ada-tools:
	@test -x "$(LLVM_GCC)" || { echo "Missing Ada compiler driver at $(LLVM_GCC)"; exit 1; }
	@test -x "$(GNATBIND)" || { echo "Missing GNAT binder at $(GNATBIND)"; exit 1; }
	@test -f "$(ADA_RUNTIME_LIB)" || { echo "Missing Ada runtime library $(ADA_RUNTIME_LIB)"; exit 1; }
