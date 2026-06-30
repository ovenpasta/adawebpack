.DEFAULT_GOAL := all

LLVM_INTERFACE_DIR := $(abspath ../../..)
LLVM_BIN_DIR := $(LLVM_INTERFACE_DIR)/bin

EMCC ?= emcc
EM_CACHE ?= /tmp/emscripten-cache
GPRBUILD ?= gprbuild
#  EH-enabled emcc runtime: full Ada exception propagation via back-end ZCX
#  + the WebAssembly exception-handling proposal. emcc must be linked with
#  -fwasm-exceptions so the wasm EH personality / unwind tables are kept.
ADA_RTS ?= $(LLVM_INTERFACE_DIR)/lib/gnat-llvm/wasm32/rts-wasm-emcc-eh
ADA_RUNTIME_LIB = $(ADA_RTS)/adalib/libgnat.a
GPRBUILD_FLAGS ?= --target=llvm --RTS=$(ADA_RTS)
EMCC_FLAGS ?= -O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=8388608 \
  -sEXIT_RUNTIME=0 \
  -sMODULARIZE=1 -sEXPORT_NAME=createHacModule \
  -sEXPORTED_FUNCTIONS=_main,_hac_compile_and_run,_malloc,_free \
  -sEXPORTED_RUNTIME_METHODS=ccall,cwrap

#  Flags for the command-line build (hac_cli.js): NODERAWFS gives the wasm
#  program transparent access to the real Node filesystem, argv and exit code,
#  so it acts as a drop-in for the native `hac` binary.
EMCC_CLI_FLAGS ?= -O2 -fwasm-exceptions -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=16777216 \
  -sNODERAWFS=1 -sEXIT_RUNTIME=1

MAIN = hac_web

DIST ?= dist

#  Public URL of the deployed site (e.g. https://hac.example.com or
#  https://example.com/hac/). When set, `deploy` rewrites og:image /
#  twitter:image to absolute URLs and injects <meta og:url> /
#  <link rel="canonical">. Telegram (and several other crawlers) skip
#  link previews when og:image is a relative path. Trailing slash optional.
DEPLOY_URL ?=

all: $(MAIN).js samples.js hac_icon.png

cli: hac_cli.js

#  Assemble the publishable site into $(DIST)/. Each asset is copied to a
#  content-hashed filename (name.<hash>.ext) and every reference is rewritten to
#  match, so a redeploy that changes a file changes its URL and the browser
#  refetches just that file. Unlike a "?v=..." query string this survives being
#  opened from disk (file://), where the suffix is a real filename, not a query.
#  The local index.html keeps plain names (so it too works from disk); only the
#  deployed copy carries hashes. The wasm name is hardcoded once inside $(MAIN).js,
#  so that reference is rewritten to the hashed wasm before the JS itself is
#  hashed. When DEPLOY_URL is set, og:image / twitter:image are rewritten to
#  absolute URLs and og:url / canonical are injected (relative og:image breaks
#  link previews on Telegram and several other crawlers). Depends on the cheap
#  stamping targets only; incremental make rebuilds the wasm solely when an .adb
#  changed, never just to redeploy an HTML/icon tweak.
deploy: index.html hac_icon.png
	rm -rf $(DIST)
	mkdir -p $(DIST)
	@set -e; \
	wh=$$(sha256sum $(MAIN).wasm | cut -c1-12); \
	sh=$$(sha256sum samples.js   | cut -c1-12); \
	ih=$$(sha256sum hac_icon.png | cut -c1-12); \
	cp $(MAIN).wasm $(DIST)/$(MAIN)-$$wh.wasm; \
	cp samples.js   $(DIST)/samples-$$sh.js; \
	cp hac_icon.png $(DIST)/hac_icon-$$ih.png; \
	sed "s/$(MAIN)\.wasm/$(MAIN)-$$wh.wasm/g" $(MAIN).js > $(DIST)/.js.tmp; \
	jh=$$(sha256sum $(DIST)/.js.tmp | cut -c1-12); \
	mv $(DIST)/.js.tmp $(DIST)/$(MAIN)-$$jh.js; \
	url='$(DEPLOY_URL)'; url=$${url%/}; \
	if [ -n "$$url" ]; then ipfx="$$url/"; else ipfx=""; fi; \
	sed -e "s/$(MAIN)\.js/$(MAIN)-$$jh.js/g" \
	    -e "s/samples\.js/samples-$$sh.js/g" \
	    -e "s|src=\"hac_icon\.png\"|src=\"hac_icon-$$ih.png\"|g" \
	    -e "s|href=\"hac_icon\.png\"|href=\"hac_icon-$$ih.png\"|g" \
	    -e "s|content=\"hac_icon\.png\"|content=\"$$ipfx""hac_icon-$$ih.png\"|g" \
	    index.html > $(DIST)/index.html; \
	if [ -n "$$url" ]; then \
	  sed -i "s|<meta property=\"og:type\"|<meta property=\"og:url\" content=\"$$url/\">\\n<link rel=\"canonical\" href=\"$$url/\">\\n<meta property=\"og:type\"|" $(DIST)/index.html; \
	  echo "Deployed to $(DIST)/ with absolute URLs ($$url/): $(MAIN)-$$jh.js, $(MAIN)-$$wh.wasm, samples-$$sh.js, hac_icon-$$ih.png, index.html"; \
	else \
	  echo "Deployed to $(DIST)/ (relative URLs; pass DEPLOY_URL=https://... for social link previews): $(MAIN)-$$jh.js, $(MAIN)-$$wh.wasm, samples-$$sh.js, hac_icon-$$ih.png, index.html"; \
	fi

check-ada-tools:
	@test -x "$(LLVM_BIN_DIR)/llvm-gcc" || { echo "Missing Ada compiler driver at $(LLVM_BIN_DIR)/llvm-gcc"; exit 1; }
	@test -x "$(LLVM_BIN_DIR)/llvm-gnatbind" || { echo "Missing GNAT binder at $(LLVM_BIN_DIR)/llvm-gnatbind"; exit 1; }
	@test -f "$(ADA_RUNTIME_LIB)" || { echo "Missing Ada runtime library $(ADA_RUNTIME_LIB)"; exit 1; }

.objs/.built: hac_web.gpr $(wildcard *.adb) | check-ada-tools
	mkdir -p .objs
	PATH=$(LLVM_BIN_DIR):$$PATH $(GPRBUILD) $(GPRBUILD_FLAGS) -c -b -p -P hac_web.gpr $(MAIN).adb
	touch $@

$(MAIN).js: .objs/.built $(ADA_RUNTIME_LIB)
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_FLAGS) .objs/*.o $(ADA_RUNTIME_LIB) -o $@

#  Browser-tab favicon, header logo and social-card image, all from the HAC
#  icon shipped in the fork (hac/obj/hac_icon.ico is a tracked source file).
#  Frame 0 is the 64x64 image; scale up to 256 so it clears the social-card
#  minimum size while staying a single square asset.
hac_icon.png: hac/obj/hac_icon.ico
	magick "$<[0]" -resize 256x256 $@

#  The example programs the page offers in its picker: a frozen, curated list of
#  HAC fork exm/ sources. HAC's exm/ also ships test fixtures and programs that
#  need files, console input or command-line arguments, which do not belong in
#  the demo, so the set is hand-picked here rather than computed. To add or drop
#  a sample, edit SAMPLES (names are the exm/ basenames, without .adb).
SAMPLES = \
  ackermann anti_primes binomials bwt days_1901 doors draw_sphere einmaleins \
  hello hofstadter mandelbrot maze_gen merge_sort native permutations series \
  shell_sort strings_demo timing triangles_overlap

#  Bundle those sources into a JS asset. Each .adb is JSON-encoded (jq) for safe
#  embedding under its own file name; a trailing comma is valid in a JS array.
samples.js: $(addprefix hac/exm/,$(addsuffix .adb,$(SAMPLES)))
	@echo "globalThis.HAC_SAMPLES = [" > $@
	@for s in $(SAMPLES); do \
	  printf '  {"name": %s, "code": %s},\n' \
	    "$$(printf '%s.adb' "$$s" | jq -Rs .)" "$$(jq -Rs . < hac/exm/$$s.adb)" >> $@; \
	done
	@echo "];" >> $@

.objs_cli/.built: hac_cli.gpr hac_cli_main.adb | check-ada-tools
	mkdir -p .objs_cli
	PATH=$(LLVM_BIN_DIR):$$PATH $(GPRBUILD) $(GPRBUILD_FLAGS) -c -b -p -P hac_cli.gpr hac_cli_main.adb
	touch $@

hac_cli.js: .objs_cli/.built $(ADA_RUNTIME_LIB)
	EM_CACHE=$(EM_CACHE) $(EMCC) $(EMCC_CLI_FLAGS) .objs_cli/*.o $(ADA_RUNTIME_LIB) -o $@

clean:
	rm -rf .objs .objs_cli $(MAIN).js $(MAIN).wasm $(MAIN).html \
	  samples.js hac_icon.png hac_cli.js hac_cli.wasm $(DIST)
