// libppu, math without libm (ppu.h). float is soft float on this core (no FPU).
#include "ppu.h"

float ppu_wrap_pi(float a)
{
    while (a > PPU_PI) a -= 2 * PPU_PI;
    while (a < -PPU_PI) a += 2 * PPU_PI;
    return a;
}

float ppu_sin(float x)
{
    x = ppu_wrap_pi(x);
    if (x > PPU_PI / 2) x = PPU_PI - x;
    else if (x < -PPU_PI / 2) x = -PPU_PI - x;
    float x2 = x * x;   // Taylor to x^11 on [-pi/2, pi/2]
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42 * (1 - x2 / 72 * (1 - x2 / 110)))));
}

float ppu_cos(float x) { return ppu_sin(x + PPU_PI / 2); }
int   ppu_round(float f) { return (int)(f < 0 ? f - 0.5f : f + 0.5f); }

static uint32_t rnd_state = 0x2545F491u;
uint32_t rnd(void)
{
    uint32_t x = rnd_state;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    return rnd_state = x;
}
int rnd_range(int lo, int hi) { return lo + (int)(rnd() % (uint32_t)(hi - lo)); }

int rect_overlap(int ax, int ay, int aw, int ah, int bx, int by, int bw, int bh)
{
    return ax < bx + bw && bx < ax + aw && ay < by + bh && by < ay + ah;
}
