// A small library for firmware that animates the render unit (ppu0) frame after frame: the showcases in this folder.
//
// The benchmark renders one frame per reset; a showcase sets CTRL.CONT (render every frame) and double-buffers the sprite
// table: oam0 has two banks of 128 sprites, CTRL.OAM_SEL names the one the next frame reads (latched as that frame starts
// to be prepared), and FRAME counts finished frames. The loop:
//
//     ppu_start(giant);                 // palette and textures loaded, bank 0 written: render from the next frame on
//     for (;;) {
//         ppu_wait_frame();             // a frame finished: its HIT bits are readable, the next frame's bank is latched
//         ... move things, read ppu_hit(i) ...
//         spr_clear(); spr(i, ...);     // write the back bank
//         ppu_present();                // the back bank is the one the frame after next reads
//     }
//
// Textures are written through the loader (TEXLD0_BASE) before ppu_start(); after it the texture SRAM is locked.
#pragma once
#include <stdint.h>
#include "soc.h"

// ---- palette (256 entries of rgb444; entry 0 is the backdrop) ----
#define RGB(r, g, b) ((uint16_t)((((r) & 15) << 8) | (((g) & 15) << 4) | ((b) & 15)))
void pal_set(int n, uint16_t rgb);          // into a copy here; ppu_start() writes it to the texture SRAM

// ---- textures ----
typedef struct {
    uint16_t tex;      // start in 32-byte units (sprite word 1 [13:0])
    uint16_t w, h;     // pixels, multiples of 8
    uint8_t  bpp8;
} tex_t;

tex_t tex_alloc(int w, int h, int bpp8);    // the next free place, 32-byte aligned, after the palette
// 4bpp pixel art: rows of characters, '.' or ' ' = 0 (transparent), '1'..'9' = 1..9, 'a'..'f' = 10..15; each art pixel
// becomes scale x scale texels, so a 16x16 drawing at scale 2 is a 32x32 texture
tex_t tex_art(const char *const *rows, int art_w, int art_h, int scale);
// any texture from a function of (u, v): 4bpp returns 0..15, 8bpp 0..255
tex_t tex_fn(int w, int h, int bpp8, uint8_t (*pixel)(int u, int v));

// ---- sprites, written into the back bank ----
#define SPR_HFLIP  (1u << 0)
#define SPR_VFLIP  (1u << 1)
#define SPR_HITBOX (1u << 2)
#define SPR_GIANT  (1u << 3)
void spr_clear(void);                                                   // every sprite of the back bank off
void spr(int i, int x, int y, tex_t t, int pal, int prio, unsigned flags);
void spr_off(int i);

// ---- the frame loop ----
void     ppu_pins(void);                     // the VGA pins are racer0's (FUNCSEL)
void     ppu_start(uint32_t giant);          // palette out, both banks written, START with CONT
void     ppu_wait_frame(void);               // until FRAME moves on
void     ppu_present(void);                  // the back bank becomes the one the frame after next reads
int      ppu_hit(int i);                     // sprite i was hit in the last finished frame
uint32_t ppu_frame(void);
uint32_t ppu_late(void);                     // pixels shown black because they were late, since START

// ---- small helpers ----
uint32_t rnd(void);                          // xorshift32
int      rnd_range(int lo, int hi);          // lo .. hi-1
uint32_t buttons(void);                      // Basys3 buttons: bit 0 up, 1 left, 2 right, 3 down (pads 32..35)
uint32_t switches(void);                     // Basys3 switches 0..15 (pads 16..31)
void     leds(uint32_t v);                   // Basys3 LEDs 0..15 (pads 0..15)
