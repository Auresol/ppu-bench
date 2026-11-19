// Showcase: boids. 96 sprites flock on their own with Craig Reynolds' three rules, computed on the core every frame; the
// render unit only draws them. The same bitstream as the other showcases: a different game is a different program.
//
// Each boid, each frame, looking at every other boid within NEAR pixels (the world wraps at the screen's edges):
//   separation  steer away from boids closer than SEP pixels
//   alignment   steer toward the neighbours' mean velocity
//   cohesion    steer toward the neighbours' centre
// then the speed is held between MIN_SPEED and MAX_SPEED. All in fixed point (1/256 pixel): the core has no FPU, and the
// all-pairs loop (96 x 95 checks, about a quarter of a frame's cycles) is left plain on purpose, to show the headroom.
// On screen: MISSED, the frames the program was not done in time (showcase_status.missed); also on the LEDs. LATE PX, the
// pixels the render unit was late for in the last finished frame (shown black); LATE FR, the frames with any late pixel.
// No controls.
#include "ppu.h"

#define N          96
#define NEAR       48                  // pixels: the neighbourhood
#define SEP        14                  // pixels: too close
#define MIN_SPEED  (1 * 256)           // 1/256 pixel a frame
#define MAX_SPEED  (3 * 256)
#define W          (640 * 256)
#define H          (480 * 256)

enum { S_BOID = 0, S_TEXT = 96, S_BG = 127 };   // text: 31 sprites, 96..126
enum { P_SKY = 0, P_BOID = 1, P_TEXT = 4 };   // P_BOID .. P_BOID+2: three colours of boid

static int32_t bx[N], by[N], bvx[N], bvy[N];   // position and velocity, 1/256 pixel
static int32_t nvx[N], nvy[N];                 // the next velocities (all boids see the same frame)
static uint32_t late_seen, late_px, late_fr;     // STATUS.LATE at the last frame, its step, frames with a step

// ---- 16 headings from 5 textures and the flips ----
// Heading d is d * 22.5 degrees, 0 = right, clockwise on the screen (y grows down). Textures exist for 0, 22.5, 45, 67.5 and
// 90 degrees; a horizontal flip turns a to 180 - a, a vertical one a to -a, both a to 180 + a.
static tex_t t_dart[5], t_sky;
static int16_t dir_x[16], dir_y[16];           // unit vectors, 1/256
static float dart_c, dart_s;                    // the texture being drawn: cos and sin of its angle

static uint8_t dart(int u, int v)               // a 16x16 dart pointing at the angle (dart_c, dart_s)
{
    float px = (float)u - 7.5f, py = (float)v - 7.5f;
    float along = px * dart_c + py * dart_s, across = -px * dart_s + py * dart_c;
    if (across < 0) across = -across;
    if (along < -5.0f || along > 6.5f) return 0;
    if (across > (6.5f - along) * 0.42f) return 0;          // tapers to the tip
    if (along < -2.0f && across < (-2.0f - along) * 0.9f) return 0;   // a notch at the tail
    return (uint8_t)(along > 2.0f ? 2 : 1);                  // a bright tip
}

static void heading_sprite(int d, int *base, unsigned *flags)
{
    if (d <= 4)       { *base = d;      *flags = 0; }                       //   0 .. 90
    else if (d <= 8)  { *base = 8 - d;  *flags = SPR_HFLIP; }               //  90 .. 180
    else if (d < 12)  { *base = d - 8;  *flags = SPR_HFLIP | SPR_VFLIP; }   // 180 .. 270
    else              { *base = 16 - d; *flags = SPR_VFLIP; }               // 270 .. 360
}

static int heading(int32_t vx, int32_t vy)      // the nearest of the 16 headings
{
    int best = 0;
    int32_t best_dot = INT32_MIN;
    for (int d = 0; d < 16; d++) {
        int32_t dot = vx * dir_x[d] + vy * dir_y[d];
        if (dot > best_dot) { best_dot = dot; best = d; }
    }
    return best;
}

// the shortest way from a to b in a world that wraps every `size`
static int32_t wrap_delta(int32_t a, int32_t b, int32_t size)
{
    int32_t d = b - a;
    if (d > size / 2) d -= size;
    else if (d < -size / 2) d += size;
    return d;
}

static void flock(void)
{
    for (int i = 0; i < N; i++) {
        int32_t n = 0, sum_vx = 0, sum_vy = 0, sum_dx = 0, sum_dy = 0, sep_x = 0, sep_y = 0;
        for (int j = 0; j < N; j++) {
            if (j == i) continue;
            int32_t dx = wrap_delta(bx[i], bx[j], W) >> 8, dy = wrap_delta(by[i], by[j], H) >> 8;   // pixels
            if (dx > NEAR || dx < -NEAR || dy > NEAR || dy < -NEAR) continue;
            int32_t d2 = dx * dx + dy * dy;
            if (d2 > NEAR * NEAR) continue;
            n++;
            sum_vx += bvx[j]; sum_vy += bvy[j];
            sum_dx += dx;     sum_dy += dy;
            if (d2 < SEP * SEP) { sep_x -= dx; sep_y -= dy; }
        }
        int32_t vx = bvx[i], vy = bvy[i];
        if (n) {
            vx += (sum_vx / n - vx) / 16;          // alignment
            vy += (sum_vy / n - vy) / 16;
            vx += (sum_dx / n) * 2;                // cohesion: toward the centre (pixels -> 1/128 pixel a frame)
            vy += (sum_dy / n) * 2;
            vx += sep_x * 12;                      // separation
            vy += sep_y * 12;
        }
        vx += rnd_range(-6, 7);                    // a little wander, so the flock never settles
        vy += rnd_range(-6, 7);
        uint32_t sp = ppu_isqrt((uint32_t)(vx * vx + vy * vy));
        if (sp > MAX_SPEED) { vx = vx * MAX_SPEED / (int32_t)sp; vy = vy * MAX_SPEED / (int32_t)sp; }
        else if (sp < MIN_SPEED && sp > 0) { vx = vx * MIN_SPEED / (int32_t)sp; vy = vy * MIN_SPEED / (int32_t)sp; }
        nvx[i] = vx; nvy[i] = vy;
    }
    for (int i = 0; i < N; i++) {
        bvx[i] = nvx[i]; bvy[i] = nvy[i];
        bx[i] = (bx[i] + bvx[i] + W) % W;
        by[i] = (by[i] + bvy[i] + H) % H;
    }
}

static void draw(void)
{
    spr_clear();
    for (int i = 0; i < N; i++) {
        int base; unsigned flags;
        heading_sprite(heading(bvx[i], bvy[i]), &base, &flags);
        spr(S_BOID + i, (bx[i] >> 8) - 8, (by[i] >> 8) - 8, t_dart[base], P_BOID + i % 3, 1, flags);
    }
    int s = text(S_TEXT, 24, 20, "MISSED", P_TEXT, 0);                   // 10 sprites
    s = text_number(s, 24 + 8 * 8, 20, showcase_status.missed, 4, P_TEXT, 0);
    s = text(s, 24, 44, "LATE PX", P_TEXT, 0);                           // 11
    s = text_number(s, 24 + 8 * 8, 44, late_px, 5, P_TEXT, 0);
    s = text(s, 24, 68, "LATE FR", P_TEXT, 0);                           // 10
    text_number(s, 24 + 8 * 8, 68, late_fr, 4, P_TEXT, 0);
    spr(S_BG, 0, 0, t_sky, P_SKY, 3, SPR_GIANT);
}

static uint8_t sky(int u, int v)                 // 320x240 at 2x: a dark vertical gradient, dithered
{
    return (uint8_t)(1 + (v * 8 + ((u + v) & 1) * 15) / 240);
}

static void palette(void)
{
    pal_set(0, RGB(0, 0, 1));
    for (int k = 1; k <= 9; k++) pal_set(P_SKY * 16 + k, RGB(0, k / 3, 2 + k / 2));
    static const uint16_t body[3] = {RGB(15, 11, 3), RGB(4, 13, 14), RGB(14, 6, 12)};
    static const uint16_t tip[3]  = {RGB(15, 15, 11), RGB(12, 15, 15), RGB(15, 12, 15)};
    for (int k = 0; k < 3; k++) {
        pal_set((P_BOID + k) * 16 + 1, body[k]);
        pal_set((P_BOID + k) * 16 + 2, tip[k]);
    }
    pal_set(P_TEXT * 16 + 1, RGB(11, 13, 15));
}

int main(void)
{
    ppu_pins();
    palette();
    for (int b = 0; b < 5; b++) {
        float a = (float)b * PPU_PI / 8;
        dart_c = ppu_cos(a); dart_s = ppu_sin(a);
        t_dart[b] = tex_fn(16, 16, 0, dart);
    }
    for (int d = 0; d < 16; d++) {
        float a = (float)d * PPU_PI / 8;
        dir_x[d] = (int16_t)ppu_round(256 * ppu_cos(a));
        dir_y[d] = (int16_t)ppu_round(256 * ppu_sin(a));
    }
    t_sky = tex_fn(320, 240, 0, sky);
    text_init(2);

    for (int i = 0; i < N; i++) {
        int d = rnd_range(0, 16);
        bx[i] = rnd_range(0, 640) * 256;
        by[i] = rnd_range(0, 480) * 256;
        bvx[i] = dir_x[d] * 2;
        bvy[i] = dir_y[d] * 2;
    }
    draw();
    ppu_start(GIANT_SIZE(320, 240, 1));
    for (;;) {
        ppu_wait_frame();
        late_px = showcase_status.late - late_seen;
        late_seen = showcase_status.late;
        if (late_px)
            late_fr++;
        flock();
        draw();
        ppu_present();
        ppu_leds(showcase_status.missed);
    }
}
