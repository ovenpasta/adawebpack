.DEFAULT_GOAL := all

include ../common.mk

ADA_JS_LIBRARY = ../ada_runtime_support.js
ADA_PRE_JS = ../sdl3_ada_pre.js
ADA_MAIN = sdl3_ttf_main
FONT_ASSET = PlayfairDisplay-Regular.ttf
ADA_SOURCES = $(wildcard ./*.adb) $(wildcard ./*.ads)
BINDING_SOURCES = $(wildcard ../bindings/*.ads)
ADA_OBJECTS = \
	.objs/sdl3_ttf_app.o \
	.objs/$(ADA_MAIN).o \
	.objs/b__$(ADA_MAIN).o

all: ttf.html

.objs/.ada_built: $(ADA_SOURCES) $(BINDING_SOURCES) ttf.gpr | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(if $(LLVM_LIBRARY_PATH),LD_LIBRARY_PATH=$(LLVM_LIBRARY_PATH)) $(GPRBUILD) $(GPRBUILD_FLAGS) -c -b -p -P ttf.gpr $(ADA_MAIN).adb
	touch $@

ttf.html: $(ADA_JS_LIBRARY) $(ADA_PRE_JS) $(FONT_ASSET) .objs/.ada_built $(ADA_RUNTIME_LIB) $(SDL3_LIB) $(SDL3_TTF_LIB) | check-sdl3-ttf
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_COMMON_FLAGS) $(ADA_EMCC_FLAGS) -sINVOKE_RUN=0 $(SDL3_CFLAGS) $(SDL3_TTF_CFLAGS) --pre-js $(ADA_PRE_JS) --js-library $(ADA_JS_LIBRARY) --embed-file $(FONT_ASSET)@/$(FONT_ASSET) $(ADA_OBJECTS) $(ADA_RUNTIME_LIB) $(SDL3_LDFLAGS) $(SDL3_TTF_LDFLAGS) -o $@

clean:
	rm -rf .objs ttf.data ttf.html ttf.js ttf.wasm
