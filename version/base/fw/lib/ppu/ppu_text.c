// libppu, text: a built-in 3x5 font, one sprite a character (ppu.h).
#include "ppu.h"

// a glyph is 5 rows of 3 bits, top row first, left pixel the high bit: (r0 << 12) | (r1 << 9) | (r2 << 6) | (r3 << 3) | r4
#define G(a, b, c, d, e) ((uint16_t)((0##a << 12) | (0##b << 9) | (0##c << 6) | (0##d << 3) | 0##e))
static const char chars[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.:-/+!?";
static const uint16_t glyphs[] = {
    // 0..9 (the digits, in octal: 07 = 111, 05 = 101, 02 = 010 ...)
    G(7, 5, 5, 5, 7), G(2, 6, 2, 2, 7), G(7, 1, 7, 4, 7), G(7, 1, 7, 1, 7), G(5, 5, 7, 1, 1),
    G(7, 4, 7, 1, 7), G(7, 4, 7, 5, 7), G(7, 1, 1, 1, 1), G(7, 5, 7, 5, 7), G(7, 5, 7, 1, 7),
    // A..Z
    G(2, 5, 7, 5, 5), G(6, 5, 6, 5, 6), G(3, 4, 4, 4, 3), G(6, 5, 5, 5, 6), G(7, 4, 6, 4, 7), G(7, 4, 6, 4, 4),
    G(3, 4, 5, 5, 3), G(5, 5, 7, 5, 5), G(7, 2, 2, 2, 7), G(1, 1, 1, 5, 2), G(5, 5, 6, 5, 5), G(4, 4, 4, 4, 7),
    G(5, 7, 7, 5, 5), G(6, 5, 5, 5, 5), G(2, 5, 5, 5, 2), G(6, 5, 6, 4, 4), G(2, 5, 5, 6, 3), G(6, 5, 6, 5, 5),
    G(3, 4, 2, 1, 6), G(7, 2, 2, 2, 2), G(5, 5, 5, 5, 7), G(5, 5, 5, 5, 2), G(5, 5, 7, 7, 5), G(5, 5, 2, 5, 5),
    G(5, 5, 2, 2, 2), G(7, 1, 2, 4, 7),
    // . : - / + ! ?
    G(0, 0, 0, 0, 2), G(0, 2, 0, 2, 0), G(0, 0, 7, 0, 0), G(1, 1, 2, 4, 4), G(0, 2, 7, 2, 0), G(2, 2, 2, 0, 2),
    G(6, 1, 2, 0, 2),
};
#define N_GLYPHS ((int)(sizeof glyphs / sizeof glyphs[0]))

static tex_t glyph_tex[N_GLYPHS];
static int text_scale = 2;
static uint16_t cur;                 // the glyph tex_fn is drawing

static uint8_t glyph_pixel(int u, int v)
{
    int x = u / text_scale, y = v / text_scale;
    if (x > 2 || y > 4) return 0;
    return (uint8_t)((cur >> ((4 - y) * 3 + (2 - x))) & 1u);
}

void text_init(int scale)
{
    text_scale = scale < 1 ? 1 : scale;
    for (int g = 0; g < N_GLYPHS; g++) {
        cur = glyphs[g];
        glyph_tex[g] = tex_fn(8 * text_scale, 8 * text_scale, 0, glyph_pixel);
    }
}

static int glyph_of(char c)
{
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    for (int g = 0; g < N_GLYPHS; g++)
        if (chars[g] == c) return g;
    return -1;
}

int text(int first, int x, int y, const char *s, int pal, int prio)
{
    for (int k = 0; s[k] && first < 128; k++) {
        int g = glyph_of(s[k]);
        if (g >= 0)
            spr(first++, x + k * 4 * text_scale, y, glyph_tex[g], pal, prio, 0);
    }
    return first;
}

int text_number(int first, int x, int y, uint32_t v, int digits, int pal, int prio)
{
    char buf[11];
    if (digits > 10) digits = 10;
    for (int d = digits - 1; d >= 0; d--, v /= 10)
        buf[d] = (char)('0' + v % 10);
    buf[digits] = 0;
    return text(first, x, y, buf, pal, prio);
}
