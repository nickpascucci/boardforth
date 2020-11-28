/* -*- fill-column: 80; -*- */

/*
Copyright (c) 2020 Nick Pascucci

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE.
*/

#include <SDL2/SDL.h>
#include <string.h>

#include "pforth/csrc/pf_all.h"

SDL_Window *gWindow = NULL;
SDL_Renderer *gRenderer = NULL;
SDL_Texture *gTexture = NULL;

Uint32 *pixels;
SDL_mutex *pixels_mutex;

SDL_atomic_t quit;
SDL_sem *frame_ready_sem;

#define WIDTH 800
#define HEIGHT 600

const char *ui_start() {
  if (gWindow != NULL) {
    return 0;
  }

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    return SDL_GetError();
  }

  gWindow =
      SDL_CreateWindow("BoardForth", SDL_WINDOWPOS_CENTERED,
                       SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
  if (gWindow == NULL) {
    return SDL_GetError();
  }

  gRenderer = SDL_CreateRenderer(gWindow, -1, 0);
  if (gRenderer == NULL) {
    return SDL_GetError();
  }

  gTexture = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_ARGB8888,
                               SDL_TEXTUREACCESS_STATIC, WIDTH, HEIGHT);
  if (gTexture == NULL) {
    return SDL_GetError();
  }

  pixels = (Uint32 *)malloc(WIDTH * HEIGHT * sizeof(Uint32));
  if (pixels == NULL) {
    return 1;
  }

  pixels_mutex = SDL_CreateMutex();
  if (pixels_mutex == NULL) {
    return 1;
  }

  SDL_SetRenderTarget(gRenderer, gTexture);
  SDL_SetRenderDrawColor(gRenderer, 0x00, 0x00, 0x00, 0x00);
  SDL_RenderClear(gRenderer);

  SDL_SetRenderTarget(gRenderer, NULL);
  SDL_RenderCopy(gRenderer, gTexture, NULL, NULL);
  SDL_RenderPresent(gRenderer);

  return 0;
}

void teardown(void) {
  if (gTexture != NULL) {
    SDL_DestroyTexture(gTexture);
    gTexture = NULL;
  }
  if (gRenderer != NULL) {
    SDL_DestroyRenderer(gRenderer);
    gRenderer = NULL;
  }
  if (gWindow != NULL) {
    SDL_DestroyWindow(gWindow);
    gWindow = NULL;
  }
  if (pixels != NULL) {
    free(pixels);
    pixels = NULL;
  }
}

static cell_t pixel_addr(void) { return pixels; }

static cell_t height(void) { return HEIGHT; }

static cell_t width(void) { return WIDTH; }

static cell_t pixel_size(void) { return sizeof(Uint32); }

static void request_render(void) {
  printf("Requesting render. \n");
  SDL_SemPost(frame_ready_sem);
}

static void lock_pixels(void) {
  printf("Locking pixel buffer... ");
  if (SDL_LockMutex(pixels_mutex) == 0) {
    printf("Locked.\n");
    return;
  } else {
    /* Something strange happened. */
    exit(1);
  }
}

static void unlock_pixels(void) {
  printf("UN-locking pixel buffer.\n");
  SDL_UnlockMutex(pixels_mutex);
}

static void render(void) {
  lock_pixels();

  printf("Rendering!\n");

  SDL_UpdateTexture(gTexture, NULL, pixels, WIDTH * sizeof(Uint32));
  SDL_RenderClear(gRenderer);
  SDL_RenderCopy(gRenderer, gTexture, NULL, NULL);
  SDL_RenderPresent(gRenderer);

  printf("Render done\n");

  unlock_pixels();
}

/*
 * pForth function table. The functions here are bound to names in the Forth
 * dictionary below.
 */
CFunc0 CustomFunctionTable[] = {
    (CFunc0)pixel_addr,
    (CFunc0)height,
    (CFunc0)width,
    (CFunc0)pixel_size,
    (CFunc0)request_render,
    (CFunc0)lock_pixels,
    (CFunc0)unlock_pixels,
};

Err CompileCustomFunctions(void) {
  Err err;
  int i = 0;

  /* Compile Forth words that call custom functions.
   * Make sure order of functions matches that in CustomFunctionTable.
   * Parameters are: Name in UPPER CASE, Function Index, Mode, NumParams
   */
  err = CreateGlueToC("DISP.PIXBUF", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.HEIGHT", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.WIDTH", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.PIXSIZE", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.RENDER", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.LOCK", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.UNLOCK", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  return 0;
}

static int run_forth(void *ptr) {
  int ret;
  pfSetQuiet(FALSE);
  ret = (int)pfDoForth("pforth.dic", NULL, FALSE);
  SDL_AtomicSet(&quit, 1);
  return ret;
}

#ifdef PF_NO_MAIN
int main(int argc, char **argv) {
  SDL_Thread *forth_thread;

  SDL_AtomicSet(&quit, 0);
  frame_ready_sem = SDL_CreateSemaphore(0);

  if (0 != ui_start()) {
    return 1;
  }

  forth_thread = SDL_CreateThread(run_forth, "pForth", (void *)NULL);

  if (NULL == forth_thread) {
    printf("SDL_CreateThread failed: %s\n", SDL_GetError());
    exit(1);
  }

  while (1) {
    SDL_Event event;

    SDL_Delay(50);

    if (SDL_SemTryWait(frame_ready_sem) == 0) {
      render();
    }

    /* Respond to Forth quitting. */
    if (SDL_AtomicGet(&quit)) {
      teardown();
      exit(0);
    }

    while (SDL_PollEvent(&event) != 0) {
      /* Respond to window system quit event. */
      if (event.type == SDL_QUIT) {
        teardown();
        return 0;
      }
    }
  }
  return 0;
}
#endif
