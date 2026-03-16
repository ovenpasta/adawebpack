# SDL3 Bindings

Shared Ada binding specs for the SDL3 example suite.

Current reusable units:

- `sdl3_bindings.ads`
- `emscripten_bindings.ads`
- `sdl3_image_bindings.ads`
- `sdl3_ttf_bindings.ads`

The SDL3_image binding was derived from `gcc -fdump-ada-spec` output and then
reduced to the single `IMG_LoadTexture` import used by the example suite.
