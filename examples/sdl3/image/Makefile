.DEFAULT_GOAL := all

include ../common.mk

ADA_JS_LIBRARY = ../ada_runtime_support.js
ADA_PRE_JS = ../sdl3_ada_pre.js
ADA_MAIN = sdl3_image_main
IMAGE_ASSET = ada-strong-2022-256-color.png
ADA_SOURCES = $(wildcard ./*.adb) $(wildcard ./*.ads)
BINDING_SOURCES = $(wildcard ../bindings/*.ads)
ADA_OBJECTS = \
	.objs/sdl3_image_app.o \
	.objs/$(ADA_MAIN).o \
	.objs/b__$(ADA_MAIN).o

all: image.html

.objs/.ada_built: $(ADA_SOURCES) $(BINDING_SOURCES) image.gpr | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(if $(LLVM_LIBRARY_PATH),LD_LIBRARY_PATH=$(LLVM_LIBRARY_PATH)) $(GPRBUILD) $(GPRBUILD_FLAGS) -c -b -p -P image.gpr $(ADA_MAIN).adb
	touch $@

image.html: $(ADA_JS_LIBRARY) $(ADA_PRE_JS) $(IMAGE_ASSET) .objs/.ada_built $(ADA_RUNTIME_LIB) $(SDL3_LIB) $(SDL3_IMAGE_LIB) | check-sdl3-image
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_COMMON_FLAGS) $(ADA_EMCC_FLAGS) -sINVOKE_RUN=0 $(SDL3_CFLAGS) $(SDL3_IMAGE_CFLAGS) --pre-js $(ADA_PRE_JS) --js-library $(ADA_JS_LIBRARY) --embed-file $(IMAGE_ASSET)@/$(IMAGE_ASSET) $(ADA_OBJECTS) $(ADA_RUNTIME_LIB) $(SDL3_LDFLAGS) $(SDL3_IMAGE_LDFLAGS) -o $@

clean:
	rm -rf .objs image.data image.html image.js image.wasm
