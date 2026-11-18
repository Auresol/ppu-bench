// libppu: the firmware library of the render unit (ppu0), for programs that animate it frame after frame.
// Build: make -C version/base/fw/lib/ppu (libppu.a); link with -Iversion/base/fw/lib/ppu and libppu.a. Used by the showcases
// (version/base/fw/showcase). The benchmark program (fw/bench) does not use it: it measures one frame with nothing in between.
//
// The render unit draws a frame from a sprite table (128 sprites, spec/sprite-spec.md section 2) and textures in its own
// texture SRAM; the core never touches pixels. This library:
//   - loads the palette and textures before the start (the texture SRAM is locked once the render unit runs)
//   - double-buffers the sprite table: oam0 has two banks; CTRL.OAM_SEL names the one the next frame reads, latched as that
//     frame starts, so the program writes the other ("the back bank") while a frame is on screen
//   - runs the frame loop (CTRL.CONT: a frame every 1/60 s), with the hardware's per-frame hit bits
//
//     ppu_pins();                       // the VGA connector shows the render unit
//     pal_set(...); tex_art(...);       // palette and textures
//     spr(...);                         // the first frame's sprites (into the back bank)
//     ppu_start(giant);                 // render from the next frame on
//     for (;;) {
//         ppu_wait_frame();             // a frame finished: its hit bits are readable
//         ... move things, ppu_hit(i) ...
//         spr_clear(); spr(i, ...);     // the next frame's sprites
//         ppu_present();                // ...shown from the frame after the current one
//     }
#pragma once
#include <stdint.h>
#include "soc.h"

// ============================================================================================================================
// Palette: 256 entries of rgb444; entry 0 is the backdrop (every pixel no sprite covers). A 4bpp sprite uses the 16 entries
// of its palette bank (pal * 16 + colour), an 8bpp sprite all 256.
// ============================================================================================================================
#define RGB(r, g, b) ((uint16_t)((((r) & 15) << 8) | (((g) & 15) << 4) | ((b) & 15)))
void pal_set(int n, uint16_t rgb);          // into a copy here; ppu_start() writes it to the texture SRAM

// ============================================================================================================================
// Textures: row-major bitmaps in the texture SRAM (64 kb, the palette's 512 bytes first), sizes multiples of 8. Colour index
// 0 is transparent. Allocated in order and never freed; all before ppu_start().
// ============================================================================================================================
typedef struct {
    uint16_t tex;      // start in 32-byte units (sprite word 1 [13:0])
    uint16_t w, h;     // pixels, multiples of 8
    uint8_t  bpp8;
} tex_t;

tex_t tex_alloc(int w, int h, int bpp8);    // the next free place, 32-byte aligned; out of memory: all LEDs on, stop
// 4bpp pixel art: rows of characters, '.' or ' ' = 0 (transparent), '1'..'9' = 1..9, 'a'..'f' = 10..15; each art pixel
// becomes scale x scale texels, so a 16x16 drawing at scale 2 is a 32x32 texture
tex_t tex_art(const char *const *rows, int art_w, int art_h, int scale);
// any texture from a function of (u, v): 4bpp returns 0..15, 8bpp 0..255
tex_t tex_fn(int w, int h, int bpp8, uint8_t (*pixel)(int u, int v));

// ============================================================================================================================
// Sprites: written into the back bank. i is 0..127; a lower prio (0..3) is in front, then the lower index. x, y may be off
// screen (signed). A giant sprite takes its size from the GIANT register of ppu_start() (one giant size for the program).
// ============================================================================================================================
#define SPR_HFLIP  (1u << 0)
#define SPR_VFLIP  (1u << 1)
#define SPR_HITBOX (1u << 2)    // takes part in the hardware's pixel-exact hit detection (ppu_hit)
#define SPR_GIANT  (1u << 3)
void spr_clear(void);                                                   // every sprite of the back bank off
void spr(int i, int x, int y, tex_t t, int pal, int prio, unsigned flags);
void spr_off(int i);

// ============================================================================================================================
// The frame loop
// ============================================================================================================================
#define GIANT_SIZE(w, h, scale2) ((uint32_t)(w) | (uint32_t)(h) << 10 | ((scale2) ? 1u << 20 : 0u))
void     ppu_pins(void);                     // the VGA pins (racer0's) and the LEDs
void     ppu_start(uint32_t giant);          // palette out, the first frame's sprites in, START with CONT; textures lock
void     ppu_wait_frame(void);               // until a frame finishes (FRAME moves on); updates ppu_status
void     ppu_present(void);                  // the back bank is the one the frame after next reads
int      ppu_hit(int i);                     // sprite i was hit in the last finished frame (two hitbox sprites overlapped)
uint32_t ppu_frame(void);                    // frames finished since the start
uint32_t ppu_late(void);                     // pixels shown black because they were late, since the start
// what a simulation reads by symbol (hw-link, tests): frames finished, late pixels, frames the program missed (it was not
// back in ppu_wait_frame before the next frame finished)
extern volatile struct ppu_status { uint32_t frames, late, missed; } showcase_status;

// ============================================================================================================================
// Text: a built-in 3x5 font (digits, A-Z, space and . : - / + ! ?), one sprite a character. Call text_init() before
// ppu_start() (it allocates the glyph textures, 16x16 each at scale 2); unknown characters are blanks.
// ============================================================================================================================
void text_init(int scale);                                              // 1: 8x8 glyphs, 2: 16x16 (the advance is 4*scale)
// draw s from sprite first on; returns the next free sprite index. Spaces take no sprite.
int  text(int first, int x, int y, const char *s, int pal, int prio);
// draw v right-aligned in `digits` places (leading zeros), from sprite first on; returns the next free index
int  text_number(int first, int x, int y, uint32_t v, int digits, int pal, int prio);

// ============================================================================================================================
// Math (no libm, no FPU: float is soft float, about 60-100 cycles an operation)
// ============================================================================================================================
#define PPU_PI 3.14159265f
float ppu_sin(float x);                      // |error| < 1e-6
float ppu_cos(float x);
float ppu_wrap_pi(float a);                  // into -pi .. pi
int   ppu_round(float f);
uint32_t ppu_isqrt(uint32_t v);              // floor(sqrt(v)), integer only (about 16 steps)
uint32_t rnd(void);                          // xorshift32, fixed seed
int      rnd_range(int lo, int hi);          // lo .. hi-1
int      rect_overlap(int ax, int ay, int aw, int ah, int bx, int by, int bw, int bh);

// ============================================================================================================================
// Basys3 board
// ============================================================================================================================
#define BTN_UP    (1u << 0)
#define BTN_LEFT  (1u << 1)
#define BTN_RIGHT (1u << 2)
#define BTN_DOWN  (1u << 3)
uint32_t ppu_buttons(void);                  // pads 32..35
uint32_t ppu_switches(void);                 // switches 0..15 (pads 16..31)
void     ppu_leds(uint32_t v);               // LEDs 0..15 (pads 0..15)
