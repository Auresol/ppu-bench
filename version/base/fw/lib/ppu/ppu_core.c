// libppu, the core: palette, textures, sprites, the frame loop (ppu.h). The sprite format is spec/sprite-spec.md section 2.
#include "ppu.h"

#define TEX_BYTES  0x10000u                 // tex0: 64 kb
#define PAL_BYTES  512u
#define OAM_WORDS  256u                     // one bank: 128 sprites of two words

static uint16_t pal[256];
static uint32_t tex_next = PAL_BYTES;       // next free byte of the texture SRAM
static unsigned sel;                        // the bank the frame being shown reads (OAM_SEL as last written)
static uint32_t last_frame;

static volatile uint32_t *const texw = (volatile uint32_t *)TEXLD0_BASE;

void pal_set(int n, uint16_t rgb) { pal[n & 255] = rgb & 0x0FFF; }

tex_t tex_alloc(int w, int h, int bpp8)
{
    tex_t t = {(uint16_t)(tex_next / 32u), (uint16_t)w, (uint16_t)h, (uint8_t)bpp8};
    uint32_t bytes = (uint32_t)(w * h) / (bpp8 ? 1u : 2u);
    tex_next = (tex_next + bytes + 31u) & ~31u;
    if (tex_next > TEX_BYTES)
        for (;;) ppu_leds(0xFFFFu);          // out of texture memory: all LEDs on, stop
    return t;
}

// one row of a texture, given as texels, into the texture SRAM (a row is a whole number of words: w is a multiple of 8)
static void tex_row(tex_t t, int v, const uint8_t *texel)
{
    uint32_t bytes_per_row = t.bpp8 ? t.w : t.w / 2u;
    uint32_t at = t.tex * 32u + (uint32_t)v * bytes_per_row;
    for (uint32_t b = 0; b < bytes_per_row; b += 4) {
        uint32_t word = 0;
        for (int k = 0; k < 4; k++) {
            uint32_t byte = t.bpp8 ? texel[b + k]
                                   : (uint32_t)(texel[2 * (b + k)] & 15) | (uint32_t)(texel[2 * (b + k) + 1] & 15) << 4;
            word |= byte << (8 * k);
        }
        texw[(at + b) / 4] = word;
    }
}

static int art_index(char c)
{
    if (c >= '1' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return 0;
}

tex_t tex_art(const char *const *rows, int art_w, int art_h, int scale)
{
    tex_t t = tex_alloc(art_w * scale, art_h * scale, 0);
    static uint8_t row[512];
    for (int v = 0; v < t.h; v++) {
        const char *r = rows[v / scale];
        for (int u = 0; u < t.w; u++)
            row[u] = (uint8_t)art_index(r[u / scale]);
        tex_row(t, v, row);
    }
    return t;
}

tex_t tex_fn(int w, int h, int bpp8, uint8_t (*pixel)(int u, int v))
{
    tex_t t = tex_alloc(w, h, bpp8);
    static uint8_t row[1024];   // not on the stack (2 kb)
    for (int v = 0; v < h; v++) {
        for (int u = 0; u < w; u++)
            row[u] = pixel(u, v);
        tex_row(t, v, row);
    }
    return t;
}

static volatile uint32_t *bank(unsigned b) { return (volatile uint32_t *)(OAM0_BASE + 4u * OAM_WORDS * b); }

void spr_off(int i)
{
    volatile uint32_t *o = bank(sel ^ 1u);
    o[2 * i] = 0;
    o[2 * i + 1] = 0;
}

void spr_clear(void)
{
    volatile uint32_t *o = bank(sel ^ 1u);
    for (unsigned i = 0; i < OAM_WORDS; i++)
        o[i] = 0;
}

void spr(int i, int x, int y, tex_t t, int pal_bank, int prio, unsigned flags)
{
    unsigned giant = (flags & SPR_GIANT) ? 1u : 0u;
    unsigned wc = giant ? 0u : (t.w / 8u - 1u) & 7u, hc = giant ? 0u : (t.h / 8u - 1u) & 7u;
    uint32_t w0 = ((uint32_t)y & 0x3FFu) | ((uint32_t)x & 0x7FFu) << 10 | wc << 21 | hc << 24 | giant << 27 | 1u << 28
                | ((flags & SPR_HFLIP) ? 1u : 0u) << 29 | ((flags & SPR_VFLIP) ? 1u : 0u) << 30
                | ((flags & SPR_HITBOX) ? 1u : 0u) << 31;
    uint32_t w1 = (t.tex & 0x3FFFu) | ((uint32_t)pal_bank & 15u) << 14 | (uint32_t)t.bpp8 << 18 | ((uint32_t)prio & 3u) << 19;
    volatile uint32_t *o = bank(sel ^ 1u);
    o[2 * i] = w0;
    o[2 * i + 1] = w1;
}

void ppu_pins(void)
{
    for (int n = RACER0_0_RGB_PIN_FIRST; n <= RACER0_0_VSYNC_PIN; n++)
        GPIO_CTRL(n) = RACER0_0_FUNCSEL;
    GPIO_OE_SET(0) = 0x0000FFFFu;             // the LEDs
}

void ppu_start(uint32_t giant)
{
    for (int n = 0; n < 256; n += 2)
        texw[n / 2] = (uint32_t)pal[n] | (uint32_t)pal[n + 1] << 16;
    // the back bank (1) was written by the caller: copy it to bank 0, which the first frame reads, and present it
    volatile uint32_t *b0 = bank(0), *b1 = bank(1);
    for (unsigned i = 0; i < OAM_WORDS; i++)
        b0[i] = b1[i];
    sel = 0;
    PPU0_GIANT = giant;
    last_frame = PPU0_FRAME;
    PPU0_CTRL = (1u << PPU_CTRL_START_POS) | (1u << PPU_CTRL_CONT_POS);
}

volatile struct ppu_status showcase_status;

void ppu_wait_frame(void)
{
    // a frame that finished before we came back is one the program missed: its sprite table was the old one again
    uint32_t now = PPU0_FRAME;
    if (now != last_frame)
        showcase_status.missed += now - last_frame;
    while (PPU0_FRAME == last_frame)
        ;
    last_frame = PPU0_FRAME;
    showcase_status.late = PPU0_LATE;
    showcase_status.frames = last_frame;
}

void ppu_present(void)
{
    sel ^= 1u;
    PPU0_CTRL = (1u << PPU_CTRL_CONT_POS) | (sel << PPU_CTRL_OAM_SEL_POS);
}

int      ppu_hit(int i)  { return (int)((REG32(PPU0_BASE, PPU_HIT0 + 4 * (i / 32)) >> (i % 32)) & 1u); }
uint32_t ppu_frame(void) { return PPU0_FRAME; }
uint32_t ppu_late(void)  { return PPU0_LATE; }
