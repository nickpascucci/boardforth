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
char *wName = NULL;

/* draw */

/* void */
/* pixel(Uint32 *dst, int x, int y, int color) */
/* { */
/* 	if(x >= 0 && x < WIDTH - PAD * 2 && y >= 0 && y < HEIGHT - PAD * 2) */
/* 		dst[(y + PAD) * WIDTH + (x + PAD)] = color; */
/* } */

/* void */
/* line(Uint32 *dst, int ax, int ay, int bx, int by, int color) */
/* { */
/* 	int dx = abs(bx - ax), sx = ax < bx ? 1 : -1; */
/* 	int dy = -abs(by - ay), sy = ay < by ? 1 : -1; */
/* 	int err = dx + dy, e2; */
/* 	for(;;) { */
/* 		pixel(dst, ax, ay, color); */
/* 		if(ax == bx && ay == by) */
/* 			break; */
/* 		e2 = 2 * err; */
/* 		if(e2 >= dy) { */
/* 			err += dy; */
/* 			ax += sx; */
/* 		} */
/* 		if(e2 <= dx) { */
/* 			err += dx; */
/* 			ay += sy; */
/* 		} */
/* 	} */
/* } */

/* void */
/* clear(Uint32 *dst) */
/* { */
/* 	int i, j; */
/* 	for(i = 0; i < HEIGHT; i++) */
/* 		for(j = 0; j < WIDTH; j++) */
/* 			dst[i * WIDTH + j] = color1; */
/* } */

/* void */
/* redraw(Uint32 *dst, Brush *b) */
/* { */
/* 	int i; */
/* 	clear(dst); */
/* 	for(i = 0; i < noton.glen; i++) */
/* 		drawgate(dst, &noton.gates[i]); */
/* 	for(i = 0; i < noton.wlen; i++) */
/* 		drawwire(dst, &noton.wires[i], color2); */
/* 	drawwire(dst, &b->wire, color3); */
/* 	SDL_UpdateTexture(gTexture, NULL, dst, WIDTH * sizeof(Uint32)); */
/* 	SDL_RenderClear(gRenderer); */
/* 	SDL_RenderCopy(gRenderer, gTexture, NULL, NULL); */
/* 	SDL_RenderPresent(gRenderer); */
/* } */

static void teardown(void) {
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
  SDL_PumpEvents();
  if (wName != NULL) {
    free(wName);
    wName = NULL;
  }
}

/*
 * Forth uses address + length for string storage, where C uses NULL-terminated
 *  byte arrays. This function converts between the two.
 */
static char *forth_to_c_str(cell_t addr, cell_t len) {
  char *buf;
  buf = (char *)malloc(len + 1);

  if (buf != NULL) {
    memcpy(buf, addr, len);
    buf[len] = NULL;
  }

  return buf;
}

/*
 * Helper for returning SDL_WINDOWPOS_UNDEFINED to Forth.
 */
static cell_t windowpos_undefined(void) { return SDL_WINDOWPOS_UNDEFINED; }

/*
 * Helper for returning SDL_WINDOWPOS_CENTERED to Forth.
 */
static cell_t windowpos_centered(void) { return SDL_WINDOWPOS_CENTERED; }

static cell_t start(cell_t width, cell_t height, cell_t loc_x, cell_t loc_y,
                    cell_t name_ptr, cell_t name_len) {
  SDL_Rect r;

  if (gWindow != NULL) {
    MSG(" Already initialized ");
    return 0;
  }

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    MSG(" Failed to initialize SDL");
    return SDL_GetError();
  }

  wName = forth_to_c_str(name_ptr, name_len);

  if (wName == NULL) {
    MSG(" Failed to allocate memory for window name! ");
    return 1;
  }

  gWindow =
      SDL_CreateWindow(wName, loc_x, loc_y, width, height, SDL_WINDOW_SHOWN);
  if (gWindow == NULL) {
    MSG(" Failed to create SDL window");
    return SDL_GetError();
  }

  gRenderer = SDL_CreateRenderer(gWindow, -1, 0);
  if (gRenderer == NULL) {
    MSG(" Failed to create SDL renderer");
    return SDL_GetError();
  }

  gTexture = SDL_CreateTexture(gRenderer, SDL_PIXELFORMAT_ARGB8888,
                               SDL_TEXTUREACCESS_TARGET, width, height);
  if (gTexture == NULL) {
    MSG(" Failed to create SDL texture");
    return SDL_GetError();
  }

  MSG(" Created SDL window with parameters:");
  EMIT_CR;
  MSG_NUM_D("  Height: ", height);
  MSG_NUM_D("  Width: ", width);
  MSG("  Name: ");
  MSG(wName);
  EMIT_CR;

  r.w = width;
  r.h = height;
  r.x = 0;
  r.y = 0;

  SDL_SetRenderTarget(gRenderer, gTexture);
  SDL_SetRenderDrawColor(gRenderer, 0x00, 0x00, 0x00, 0x00);
  SDL_RenderClear(gRenderer);
  SDL_RenderDrawRect(gRenderer, &r);
  SDL_SetRenderDrawColor(gRenderer, 0xFF, 0x00, 0x00, 0x00);
  SDL_RenderFillRect(gRenderer, &r);
  SDL_SetRenderTarget(gRenderer, NULL);
  SDL_RenderCopy(gRenderer, gTexture, NULL, NULL);
  SDL_RenderPresent(gRenderer);

  /* Note: This call is necessary to force SDL to update the window. */
  SDL_PumpEvents();

  return 0;
}

/*
 * pForth function table. The functions here are bound to names in the Forth
 * dictionary below.
 */
CFunc0 CustomFunctionTable[] = {
    (CFunc0)SDL_Quit,
    (CFunc0)SDL_PumpEvents,
    (CFunc0)windowpos_undefined,
    (CFunc0)windowpos_centered,
    (CFunc0)teardown,
    (CFunc0)start,
};

Err CompileCustomFunctions(void) {
  Err err;
  int i = 0;

  /* Compile Forth words that call custom functions.
   * Make sure order of functions matches that in CustomFunctionTable.
   * Parameters are: Name in UPPER CASE, Function Index, Mode, NumParams
   */
  err = CreateGlueToC("DISP.QUIT", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.PUMP", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.UNDEFINED", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.CENTERED", i++, C_RETURNS_VALUE, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.TEARDOWN", i++, C_RETURNS_VOID, 0);
  if (err < 0) return err;

  err = CreateGlueToC("DISP.START", i++, C_RETURNS_VALUE, 6);
  if (err < 0) return err;

  return 0;
}

/* int */
/* main(int argc, char **argv) */
/* { */
/* 	if(!init()) */
/* 		return error("Init", "Failure"); */

/* 	while(1) { */
/* 		SDL_Event event; */
/* 		if(!begintime) */
/* 			begintime = SDL_GetTicks(); */
/* 		else */
/* 			delta = endtime - begintime; */

/* 		if(delta < noton.speed) */
/* 			SDL_Delay(noton.speed - delta); */

/* 		if(noton.alive) { */
/* 			run(&noton); */
/* 			redraw(pixels, &brush); */
/* 		} */

/* 		while(SDL_PollEvent(&event) != 0) { */
/* 			if(event.type == SDL_QUIT) */
/* 				quit(); */
/* 			else if(event.type == SDL_MOUSEBUTTONUP || */
/* 					event.type == SDL_MOUSEBUTTONDOWN || */
/* 					event.type == SDL_MOUSEMOTION) { */
/* 				domouse(&event, &brush); */
/* 			} else if(event.type == SDL_KEYDOWN) */
/* 				dokey(&noton, &event); */
/* 			else if(event.type == SDL_WINDOWEVENT) */
/* 				if(event.window.event == */
/* SDL_WINDOWEVENT_EXPOSED) */
/* 					redraw(pixels, &brush); */
/* 		} */

/* 		begintime = endtime; */
/* 		endtime = SDL_GetTicks(); */
/* 	} */
/* 	quit(); */
/* 	(void)argc; */
/* 	(void)argv; */
/* 	return 0; */
/* } */
