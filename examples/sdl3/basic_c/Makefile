.DEFAULT_GOAL := all

include ../common.mk

all: basic_c.html

basic_c.html: basic_c_main.c | check-sdl3
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_COMMON_FLAGS) $(SDL3_CFLAGS) basic_c_main.c $(SDL3_LDFLAGS) -o $@

clean:
	rm -f basic_c.data basic_c.html basic_c.js basic_c.wasm
