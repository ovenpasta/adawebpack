#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

typedef struct AppState {
    SDL_Window *window;
    SDL_Renderer *renderer;
    unsigned int frame_count;
} AppState;

static Uint8 color_from_frame(unsigned int frame, unsigned int scale, Uint8 base)
{
    return (Uint8)(((frame * scale) + base) % 255U);
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
{
    AppState *state;
    (void)argc;
    (void)argv;

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    state = (AppState *)SDL_calloc(1, sizeof(*state));
    if (state == NULL) {
        SDL_Log("SDL_calloc failed: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer(
            "SDL3 Basic C",
            960,
            540,
            0,
            &state->window,
            &state->renderer)) {
        SDL_Log("SDL_CreateWindowAndRenderer failed: %s", SDL_GetError());
        SDL_free(state);
        return SDL_APP_FAILURE;
    }

    *appstate = state;
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
    AppState *state = (AppState *)appstate;
    const Uint8 red = color_from_frame(state->frame_count, 1U, 32U);
    const Uint8 green = color_from_frame(state->frame_count, 2U, 64U);
    const Uint8 blue = color_from_frame(state->frame_count, 4U, 96U);

    state->frame_count += 1U;

    if (!SDL_SetRenderDrawColor(state->renderer, red, green, blue, SDL_ALPHA_OPAQUE)) {
        SDL_Log("SDL_SetRenderDrawColor failed: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_RenderClear(state->renderer)) {
        SDL_Log("SDL_RenderClear failed: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_RenderPresent(state->renderer)) {
        SDL_Log("SDL_RenderPresent failed: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    (void)appstate;

    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }

    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    AppState *state = (AppState *)appstate;
    (void)result;

    if (state != NULL) {
        if (state->renderer != NULL) {
            SDL_DestroyRenderer(state->renderer);
        }

        if (state->window != NULL) {
            SDL_DestroyWindow(state->window);
        }

        SDL_free(state);
    }

    SDL_Quit();
}
