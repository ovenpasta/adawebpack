# SDL3 Image

Ada SDL3_image example that embeds `ada-strong-2022-256-color.png` into the
Emscripten filesystem and renders it with `IMG_LoadTexture`.

Build from the suite root with:

```sh
make image
```

Then serve `../` over HTTP and open:

```text
http://localhost:8000/image/image.html
```
