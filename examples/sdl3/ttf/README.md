# SDL3 TTF

Ada SDL3_ttf example that embeds `PlayfairDisplay-Regular.ttf`, renders one
text surface with `TTF_RenderText_Blended`, converts it to a texture, and
displays it in the browser.

Current status:

- the example builds successfully
- the page renders in the browser
- text rendering now uses `TTF_RenderText_Blended` directly from Ada
