.DEFAULT_GOAL := all

include ../common.mk

ADA_JS_LIBRARY = ../ada_runtime_support.js
ADA_PRE_JS = ../sdl3_ada_pre.js
ADA_MAIN = sdl3_ada_main
BUILD_INFO = .objs/basic_build_info.ads
BUILD_INFO_GENERATOR = ./generate_basic_build_info.py
ADA_SOURCES = $(wildcard ./*.adb) $(wildcard ./*.ads)
BINDING_SOURCES = $(wildcard ../bindings/*.ads)
ADA_OBJECTS = \
	.objs/basic_app.o \
	.objs/$(ADA_MAIN).o \
	.objs/b__$(ADA_MAIN).o

all: basic.html

$(BUILD_INFO): Makefile ../common.mk $(BUILD_INFO_GENERATOR) | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(if $(LLVM_LIBRARY_PATH),LD_LIBRARY_PATH=$(LLVM_LIBRARY_PATH)) \
	LLVM_CONFIG_BIN="$(LLVM_CONFIG)" BUILD_INFO_OUT="$(BUILD_INFO)" python3 "$(BUILD_INFO_GENERATOR)"

.objs/.ada_built: $(ADA_SOURCES) $(BINDING_SOURCES) basic.gpr $(BUILD_INFO) | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(if $(LLVM_LIBRARY_PATH),LD_LIBRARY_PATH=$(LLVM_LIBRARY_PATH)) $(GPRBUILD) $(GPRBUILD_FLAGS) -c -b -p -P basic.gpr $(ADA_MAIN).adb
	touch $@

basic.html: $(ADA_JS_LIBRARY) $(ADA_PRE_JS) .objs/.ada_built $(ADA_RUNTIME_LIB) $(SDL3_LIB) | check-sdl3
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_COMMON_FLAGS) $(ADA_EMCC_FLAGS) -sINVOKE_RUN=0 $(SDL3_CFLAGS) --pre-js $(ADA_PRE_JS) --js-library $(ADA_JS_LIBRARY) $(ADA_OBJECTS) $(ADA_RUNTIME_LIB) $(SDL3_LDFLAGS) -o $@

clean:
	rm -rf .objs basic.data basic.html basic.js basic.wasm
