// Showcase: a double pendulum, simulated on the core and drawn by the render unit at 60 frames a second.
// Two equal masses on two equal massless rods; the equations of motion (Lagrangian, angles from the vertical) integrated
// with RK4, four steps a frame, in float (soft float: the core has no FPU; about 70k cycles of the 1.68M a frame).
// Drawn: the pivot, the rods as rows of dots, the two bobs, and a fading trail of the lower bob over a giant grid.
//
// Basys3: the up button kicks the pendulum, the down button starts it again. Switch 0 hides the trail.
#include "ppu.h"

enum { S_PIVOT = 0, S_BOB1 = 1, S_BOB2 = 2, S_ROD = 3, N_ROD = 22, S_TRAIL = 32, N_TRAIL = 64, S_TEXT = 100, S_GRID = 127 };
enum { P_GRID = 0, P_ROD = 1, P_BOB1 = 2, P_BOB2 = 3, P_TRAIL = 4, P_TEXT = 8 };   // P_TRAIL .. P_TRAIL+3: the trail, newest first

#define PIVOT_X 320
#define PIVOT_Y 120
#define LEN_PX  110.0f            // one rod on screen
#define DOTS    11                // dots on a rod

// ---- the physics: state (t1, t2, w1, w2), g/l = 9.81 with l = 1 ----
typedef struct { float t1, t2, w1, w2; } state_t;
static const float G = 9.81f;

static state_t deriv(state_t s)
{
    float d = s.t1 - s.t2, sd = ppu_sin(d), cd = ppu_cos(d);
    float den = 3 - ppu_cos(2 * d);                 // 2 m1 + m2 - m2 cos 2d, m1 = m2 = 1
    float a1 = (-G * 3 * ppu_sin(s.t1) - G * ppu_sin(s.t1 - 2 * s.t2) - 2 * sd * (s.w2 * s.w2 + s.w1 * s.w1 * cd)) / den;
    float a2 = (2 * sd * (s.w1 * s.w1 * 2 + G * 2 * ppu_cos(s.t1) + s.w2 * s.w2 * cd)) / den;
    return (state_t){s.w1, s.w2, a1, a2};
}
static state_t axpy(state_t a, float h, state_t b)
{
    return (state_t){a.t1 + h * b.t1, a.t2 + h * b.t2, a.w1 + h * b.w1, a.w2 + h * b.w2};
}
static state_t rk4(state_t s, float h)
{
    state_t k1 = deriv(s), k2 = deriv(axpy(s, h / 2, k1)), k3 = deriv(axpy(s, h / 2, k2)), k4 = deriv(axpy(s, h, k3));
    return (state_t){s.t1 + h / 6 * (k1.t1 + 2 * k2.t1 + 2 * k3.t1 + k4.t1), s.t2 + h / 6 * (k1.t2 + 2 * k2.t2 + 2 * k3.t2 + k4.t2),
                     s.w1 + h / 6 * (k1.w1 + 2 * k2.w1 + 2 * k3.w1 + k4.w1), s.w2 + h / 6 * (k1.w2 + 2 * k2.w2 + 2 * k3.w2 + k4.w2)};
}

// ---- textures ----
static const char *const dot_art[8] = {
    "..1111..", ".111111.", "11111111", "11111111", "11111111", "11111111", ".111111.", "..1111..",
};
static const char *const pivot_art[8] = {
    "..2222..", ".211112.", "21133112", "21333312", "21333312", "21133112", ".211112.", "..2222..",
};
static uint8_t bob(int u, int v)        // a shaded ball, 32x32: 1 rim, 2 body, 3 light
{
    int dx = u - 16, dy = v - 16, r2 = dx * dx + dy * dy;
    if (r2 > 15 * 15) return 0;
    if (r2 > 13 * 13) return 1;
    int lx = u - 11, ly = v - 11;
    return (uint8_t)(lx * lx + ly * ly < 16 ? 3 : 2);
}
static uint8_t grid(int u, int v)       // 320x240 at 2x: lines every 20 texels, a brighter one every 80
{
    if (u % 80 == 0 || v % 80 == 0) return 2;
    if (u % 20 == 0 || v % 20 == 0) return 1;
    return 0;
}

static tex_t t_dot, t_pivot, t_bob, t_grid;
static int trail_x[N_TRAIL], trail_y[N_TRAIL], trail_n, trail_head;

static void palette(void)
{
    pal_set(0, RGB(0, 1, 2));
    pal_set(P_GRID * 16 + 1, RGB(1, 2, 4)); pal_set(P_GRID * 16 + 2, RGB(2, 4, 7));
    pal_set(P_ROD * 16 + 1, RGB(12, 12, 13)); pal_set(P_ROD * 16 + 2, RGB(6, 6, 7)); pal_set(P_ROD * 16 + 3, RGB(15, 15, 15));
    pal_set(P_BOB1 * 16 + 1, RGB(6, 1, 1)); pal_set(P_BOB1 * 16 + 2, RGB(14, 3, 2)); pal_set(P_BOB1 * 16 + 3, RGB(15, 12, 11));
    pal_set(P_BOB2 * 16 + 1, RGB(6, 5, 0)); pal_set(P_BOB2 * 16 + 2, RGB(15, 12, 1)); pal_set(P_BOB2 * 16 + 3, RGB(15, 15, 11));
    static const uint16_t fade[4] = {RGB(15, 13, 3), RGB(11, 8, 2), RGB(7, 5, 2), RGB(4, 3, 2)};
    for (int k = 0; k < 4; k++) pal_set((P_TRAIL + k) * 16 + 1, fade[k]);
    pal_set(P_TEXT * 16 + 1, RGB(11, 13, 15));
}

static state_t start_state(void) { return (state_t){2.2f, 2.6f, 0.0f, 0.0f}; }

static void draw(state_t s)
{
    float x1 = LEN_PX * ppu_sin(s.t1), y1 = LEN_PX * ppu_cos(s.t1);
    float x2 = x1 + LEN_PX * ppu_sin(s.t2), y2 = y1 + LEN_PX * ppu_cos(s.t2);
    int bx1 = PIVOT_X + ppu_round(x1), by1 = PIVOT_Y + ppu_round(y1), bx2 = PIVOT_X + ppu_round(x2), by2 = PIVOT_Y + ppu_round(y2);

    spr_clear();
    spr(S_PIVOT, PIVOT_X - 4, PIVOT_Y - 4, t_pivot, P_ROD, 0, 0);
    for (int k = 0; k < DOTS; k++) {          // dots along each rod, centred on the line
        float f = (float)(k + 1) / (DOTS + 1);
        spr(S_ROD + k, PIVOT_X + ppu_round(x1 * f) - 4, PIVOT_Y + ppu_round(y1 * f) - 4, t_dot, P_ROD, 1, 0);
        spr(S_ROD + DOTS + k, bx1 + ppu_round((x2 - x1) * f) - 4, by1 + ppu_round((y2 - y1) * f) - 4, t_dot, P_ROD, 1, 0);
    }
    spr(S_BOB1, bx1 - 16, by1 - 16, t_bob, P_BOB1, 0, 0);
    spr(S_BOB2, bx2 - 16, by2 - 16, t_bob, P_BOB2, 0, 0);

    // the trail: a point when the bob has moved 6 pixels from the last one (so dots never pile up on one pixel: that would be
    // more sprites on a pixel than the render unit has slots), newest brightest
    int mx = bx2 - trail_x[trail_head], my = by2 - trail_y[trail_head];
    if (trail_n == 0 || mx * mx + my * my >= 36) {
        trail_head = (trail_head + 1) % N_TRAIL;
        trail_x[trail_head] = bx2; trail_y[trail_head] = by2;
        if (trail_n < N_TRAIL) trail_n++;
    }
    if (!(ppu_switches() & 1u))
        for (int k = 0; k < trail_n; k++) {
            int i = (trail_head - k + N_TRAIL) % N_TRAIL;
            spr(S_TRAIL + k, trail_x[i] - 4, trail_y[i] - 4, t_dot, P_TRAIL + k * 4 / N_TRAIL, 2, 0);
        }
    text(S_TEXT, 24, 20, "DOUBLE PENDULUM - RK4", P_TEXT, 0);
    spr(S_GRID, 0, 0, t_grid, P_GRID, 3, SPR_GIANT);
}

int main(void)
{
    ppu_pins();
    palette();
    t_dot = tex_art(dot_art, 8, 8, 1);
    t_pivot = tex_art(pivot_art, 8, 8, 1);
    t_bob = tex_fn(32, 32, 0, bob);
    t_grid = tex_fn(320, 240, 0, grid);
    text_init(2);

    state_t s = start_state();
    draw(s);
    ppu_start(GIANT_SIZE(320, 240, 1));
    uint32_t last = 0;
    for (;;) {
        ppu_wait_frame();
        uint32_t b = ppu_buttons();
        if ((b & BTN_UP) && !(last & BTN_UP)) s.w2 += 6.0f;                          // up: a kick
        if ((b & BTN_DOWN) && !(last & BTN_DOWN)) { s = start_state(); trail_n = 0; }    // down: again
        last = b;
        for (int k = 0; k < 4; k++) s = rk4(s, 1.0f / 240);
        s.t1 = ppu_wrap_pi(s.t1); s.t2 = ppu_wrap_pi(s.t2);
        draw(s);
        ppu_present();
    }
}
