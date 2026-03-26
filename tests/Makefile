.DEFAULT_GOAL := all

LLVM_INTERFACE_DIR := $(abspath ../..)
LLVM_BIN_DIR := $(LLVM_INTERFACE_DIR)/bin

EMCC ?= emcc
EM_CACHE ?= /tmp/emscripten-cache
GPRBUILD ?= gprbuild
ADA_RTS ?= $(LLVM_INTERFACE_DIR)/lib/gnat-llvm/wasm32/rts-wasm-emcc
ADA_RUNTIME_LIB = $(ADA_RTS)/adalib/libgnat.a
GPRBUILD_FLAGS ?= --target=llvm --RTS=$(ADA_RTS)

TARGETS := record_by_value_main debug_text_signature_main interfaces_c_strings_main \
           containers_main calendar_main strings_fixed_main
ASYNCIFY_TARGETS := delay_main

all: $(TARGETS:%=%.html) $(ASYNCIFY_TARGETS:%=%.html)

check-ada-tools:
	@test -x "$(LLVM_BIN_DIR)/llvm-gcc" || { echo "Missing Ada compiler driver at $(LLVM_BIN_DIR)/llvm-gcc"; exit 1; }
	@test -x "$(LLVM_BIN_DIR)/llvm-gnatbind" || { echo "Missing GNAT binder at $(LLVM_BIN_DIR)/llvm-gnatbind"; exit 1; }
	@test -f "$(ADA_RUNTIME_LIB)" || { echo "Missing Ada runtime library $(ADA_RUNTIME_LIB)"; exit 1; }

.objs/%.built: tests.gpr $(wildcard *.adb) $(wildcard *.ads) | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(GPRBUILD) $(GPRBUILD_FLAGS) $(GPR_SCENARIO_FLAGS) -c -b -p -P tests.gpr $*.adb
	touch $@

.objs/record_by_value.o: record_by_value.c
	mkdir -p .objs
	EM_CACHE=$(EM_CACHE) $(EMCC) -O2 -sALLOW_MEMORY_GROWTH=1 -c $< -o $@

.objs/debug_text_signature.o: debug_text_signature.c
	mkdir -p .objs
	EM_CACHE=$(EM_CACHE) $(EMCC) -O2 -sALLOW_MEMORY_GROWTH=1 -c $< -o $@

.objs/interfaces_c_strings_check.o: interfaces_c_strings_check.c
	mkdir -p .objs
	EM_CACHE=$(EM_CACHE) $(EMCC) -O2 -sALLOW_MEMORY_GROWTH=1 -c $< -o $@

record_by_value_main.html: EXTRA_OBJS = .objs/record_by_value.o
record_by_value_main.html: .objs/record_by_value.o

debug_text_signature_main.html: EXTRA_OBJS = .objs/debug_text_signature.o
debug_text_signature_main.html: .objs/debug_text_signature.o

interfaces_c_strings_main.html: EXTRA_OBJS = .objs/interfaces_c_strings_check.o
interfaces_c_strings_main.html: .objs/interfaces_c_strings_check.o

.objs/strings_fixed_main.built: GPR_SCENARIO_FLAGS = -XUSE_GNATP=false

$(TARGETS:%=%.html): %.html: .objs/%.built $(ADA_RUNTIME_LIB)
	EM_CACHE=$(EM_CACHE) $(EMCC) -O2 -sALLOW_MEMORY_GROWTH=1 .objs/$*.o .objs/b__$*.o .objs/test_utils.o $(EXTRA_OBJS) $(ADA_RUNTIME_LIB) -o $@

$(ASYNCIFY_TARGETS:%=%.html): %.html: .objs/%.built $(ADA_RUNTIME_LIB)
	EM_CACHE=$(EM_CACHE) $(EMCC) -O2 -sALLOW_MEMORY_GROWTH=1 -sASYNCIFY \
	  .objs/$*.o .objs/b__$*.o .objs/test_utils.o $(ADA_RUNTIME_LIB) -o $@

clean:
	rm -rf .objs \
		$(TARGETS:%=%.html) $(TARGETS:%=%.js) $(TARGETS:%=%.wasm) \
		$(ASYNCIFY_TARGETS:%=%.html) $(ASYNCIFY_TARGETS:%=%.js) $(ASYNCIFY_TARGETS:%=%.wasm)
