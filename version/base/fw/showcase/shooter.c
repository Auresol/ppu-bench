// Showcase: a vertical space shooter on the render unit. 640x480, 60 frames a second, every sprite from the sprite table:
// a scrolling starfield (two giant sprites), a formation of 32 enemies, bullets, explosions, a score. Collisions come from
// the hardware's pixel-exact hitboxes (HIT): a bullet and an enemy are only checked in software when both were hit.
//
// Basys3: left/right buttons move, up fires. With no button for two seconds the ship flies itself (the simulation and an
// idle board show the attract mode). LEDs: the lives left.
#include "ppu.h"

// ---- sprite table layout ----
enum {
    S_SHIP = 0,
    S_ENEMY = 1,  N_ENEMY = 32,
    S_SHOT = 33,  N_SHOT = 16,       // the ship's bullets
    S_BOMB = 49,  N_BOMB = 16,       // the enemies' bullets
    S_BOOM = 65,  N_BOOM = 16,       // explosions
    S_SCORE = 100, N_DIGITS = 6,     // the score: text_number, one sprite a digit
    S_STARS = 126,                   // and 127: two giant sprites, stacked, scrolling down
};

// ---- palette banks ----
enum { P_STARS = 0, P_SHIP = 1, P_ENEMY_A = 2, P_ENEMY_B = 3, P_SHOT = 4, P_BOMB = 5, P_BOOM = 6, P_TEXT = 7 };

static const char *const ship_art[16] = {
    ".......11.......",
    ".......11.......",
    "......1221......",
    "......1221......",
    ".....122221.....",
    ".....123321.....",
    "....12333321....",
    "...1223333221...",
    "..122233332221..",
    ".12222222222221.",
    "1222122222212221",
    "1221.122221.1221",
    "11...122221...11",
    ".....1.44.1.....",
    "......4554......",
    ".......55.......",
};
static const char *const enemy_a_art[16] = {
    "...1........1...",
    "....1......1....",
    "...1111111111...",
    "..112111111211..",
    ".11144111144111.",
    "1111441111441111",
    "1111111111111111",
    "1.111111111111.1",
    "1.1..........1.1",
    "1.1..........1.1",
    "...11......11...",
    "..11........11..",
    "................",
    "................",
    "................",
    "................",
};
static const char *const enemy_b_art[16] = {
    "......2222......",
    "....22111122....",
    "...2111111112...",
    "..211441144112..",
    ".21114411441112.",
    ".21111111111112.",
    "2111111111111112",
    "2113111111113112",
    "2133311111133312",
    ".23..331133..32.",
    ".2....3333....2.",
    "................",
    "................",
    "................",
    "................",
    "................",
};
static const char *const shot_art[16] = {
    "...22...", "..2112..", "..2112..", "..1111..", "..1111..", "..1111..", "...11...", "...11...",
    "...11...", "...11...", "...11...", "...11...", "...11...", "........", "........", "........",
};
static const char *const bomb_art[8] = {
    "........", "..2222..", ".211112.", ".211112.", ".211112.", ".211112.", "..2222..", "........",
};
static const char *const boom1_art[16] = {
    "................",
    "................",
    "......4..4......",
    "....4.1111.4....",
    ".....111111.....",
    "...4112222114...",
    "....12233221....",
    "....12344321....",
    "....12344321....",
    "....12233221....",
    "...4112222114...",
    ".....111111.....",
    "....4.1111.4....",
    "......4..4......",
    "................",
    "................",
};
static const char *const boom2_art[16] = {
    "..3....3....3...",
    "...3..2..2.3....",
    "3...22.33.22...3",
    "..22.33..33.22..",
    "..2.3.......3.2.",
    ".2.3..3...3..3.2",
    "3.3...........3.",
    "..3..3.....3..3.",
    ".3..3.......3..3",
    "..3.....3.....3.",
    ".2..3.......3..2",
    "..2..3..3..3..2.",
    "...22..3.3..22..",
    "3....22...22...3",
    "...3....3....3..",
    "..3...3...3...3.",
};
static uint8_t star(int u, int v)
{
    uint32_t h = (uint32_t)u * 0x9E3779B1u ^ (uint32_t)v * 0x85EBCA77u;
    h ^= h >> 15; h *= 0x2C1B3C6Du; h ^= h >> 12;
    if (h % 89u) return 0;              // most of it is the backdrop
    return (uint8_t)(1 + (h >> 8) % 5);
}

static tex_t t_ship, t_enemy[2], t_shot, t_bomb, t_boom[2], t_stars;

// ---- the game ----
typedef struct { int x, y, on; uint16_t id; } obj_t;

static obj_t ship, enemy[N_ENEMY], shot[N_SHOT], bomb[N_BOMB];
static struct { int x, y, life; } boom[N_BOOM];
static uint16_t next_id = 1;
static int lives = 3, respawn, invuln, cooldown, idle_frames, score, scroll;
static int form_x, form_y, form_dir = 1, wave;

// what each bank was written with: HIT of a frame belongs to the bank it showed (see collide())
static obj_t snap_ship[2], snap_enemy[2][N_ENEMY], snap_shot[2][N_SHOT], snap_bomb[2][N_BOMB];
static unsigned back;   // the bank this iteration writes: 1, 0, 1, ... (ppu_lib's back bank)

static void new_wave(void)
{
    form_x = 64; form_y = 48; form_dir = 1; wave++;
    for (int i = 0; i < N_ENEMY; i++)
        enemy[i] = (obj_t){0, 0, 1, next_id++};
}

static void explode(int x, int y)
{
    for (int i = 0; i < N_BOOM; i++)
        if (!boom[i].life) { boom[i].x = x; boom[i].y = y; boom[i].life = 24; return; }
}

static int overlap(const obj_t *a, int aw, int ah, const obj_t *b, int bw, int bh)
{
    return rect_overlap(a->x, a->y, aw, ah, b->x, b->y, bw, bh);
}

// HIT is of the frame that just ended, which showed the bank this iteration is about to write again: its snapshot says
// where everything was. A hit counts only between a shot and an enemy (or the ship and a bomb or an enemy) that were both hit,
// overlap in that snapshot, and are still the same objects (same spawn id) now.
static void collide(void)
{
    obj_t *se = snap_enemy[back], *ss = snap_shot[back], *sb = snap_bomb[back], *sh = &snap_ship[back];
    for (int s = 0; s < N_SHOT; s++) {
        if (!ss[s].on || !ppu_hit(S_SHOT + s)) continue;
        for (int e = 0; e < N_ENEMY; e++) {
            if (!se[e].on || !ppu_hit(S_ENEMY + e) || !overlap(&ss[s], 8, 16, &se[e], 32, 32)) continue;
            if (enemy[e].on && enemy[e].id == se[e].id) {
                enemy[e].on = 0; score += 100; explode(form_x + (e % 8) * 64, form_y + (e / 8) * 48);
            }
            if (shot[s].id == ss[s].id) shot[s].on = 0;
            break;
        }
    }
    if (!sh->on || !ppu_hit(S_SHIP) || invuln) return;
    int dead = 0;
    for (int b = 0; b < N_BOMB && !dead; b++)
        if (sb[b].on && ppu_hit(S_BOMB + b) && overlap(sh, 32, 32, &sb[b], 8, 8)) { dead = 1; if (bomb[b].id == sb[b].id) bomb[b].on = 0; }
    for (int e = 0; e < N_ENEMY && !dead; e++)
        if (se[e].on && ppu_hit(S_ENEMY + e) && overlap(sh, 32, 32, &se[e], 32, 32)) dead = 1;
    if (dead) {
        explode(ship.x, ship.y); ship.on = 0; respawn = 90;
        if (--lives < 0) { lives = 3; score = 0; wave = 0; new_wave(); }
    }
}

static void steer(int *dx, int *fire)
{
    uint32_t b = ppu_buttons();
    idle_frames = b ? 0 : idle_frames + 1;
    if (idle_frames < 120) {                       // a player
        *dx = (b & BTN_LEFT) ? -5 : (b & BTN_RIGHT) ? 5 : 0;
        *fire = (b & BTN_UP) != 0;
        return;
    }
    // attract mode: under the lowest enemy of the nearest column, away from bombs, always firing
    int target = ship.x, best = 1 << 30;
    for (int e = 0; e < N_ENEMY; e++) {
        if (!enemy[e].on) continue;
        int ex = form_x + (e % 8) * 64, d = ex - ship.x;
        d = d < 0 ? -d : d;
        if (d < best) { best = d; target = ex; }
    }
    for (int b2 = 0; b2 < N_BOMB; b2++)
        if (bomb[b2].on && bomb[b2].y > ship.y - 96 && bomb[b2].x > ship.x - 16 && bomb[b2].x < ship.x + 40)
            target = bomb[b2].x < ship.x + 12 ? ship.x + 64 : ship.x - 64;
    *dx = target > ship.x + 2 ? 4 : target < ship.x - 2 ? -4 : 0;
    *fire = 1;
}

static void update(void)
{
    int dx = 0, fire = 0;
    steer(&dx, &fire);

    // the ship
    if (!ship.on && --respawn <= 0) { ship = (obj_t){304, 420, 1, next_id++}; invuln = 120; }
    if (ship.on) {
        ship.x += dx;
        if (ship.x < 0) ship.x = 0;
        if (ship.x > 640 - 32) ship.x = 640 - 32;
        if (invuln) invuln--;
        if (cooldown) cooldown--;
        if (fire && !cooldown)
            for (int s = 0; s < N_SHOT; s++)
                if (!shot[s].on) { shot[s] = (obj_t){ship.x + 12, ship.y - 12, 1, next_id++}; cooldown = 9; break; }
    }
    for (int s = 0; s < N_SHOT; s++)
        if (shot[s].on && (shot[s].y -= 9) < -16) shot[s].on = 0;

    // the formation sways, steps down at each edge, and drops bombs
    form_x += form_dir * (1 + wave / 3);
    if (form_x > 640 - 8 * 64 + 16 || form_x < 16) { form_dir = -form_dir; form_y += 8; }
    if (form_y > 260) form_y = 48;
    int alive = 0;
    for (int e = 0; e < N_ENEMY; e++) {
        if (!enemy[e].on) continue;
        alive++;
        enemy[e].x = form_x + (e % 8) * 64;
        enemy[e].y = form_y + (e / 8) * 48 + ((ppu_frame() / 16 + e) & 1) * 2;
        if (rnd_range(0, 700) == 0)
            for (int b = 0; b < N_BOMB; b++)
                if (!bomb[b].on) { bomb[b] = (obj_t){enemy[e].x + 12, enemy[e].y + 24, 1, next_id++}; break; }
    }
    if (!alive) new_wave();
    for (int b = 0; b < N_BOMB; b++)
        if (bomb[b].on && (bomb[b].y += 4) > 480) bomb[b].on = 0;
    for (int i = 0; i < N_BOOM; i++)
        if (boom[i].life) boom[i].life--;
    scroll = (scroll + 1) % 480;
}

static void draw(void)
{
    spr_clear();
    if (ship.on && !(invuln & 4))
        spr(S_SHIP, ship.x, ship.y, t_ship, P_SHIP, 0, invuln ? 0 : SPR_HITBOX);
    for (int e = 0; e < N_ENEMY; e++)
        if (enemy[e].on)
            spr(S_ENEMY + e, enemy[e].x, enemy[e].y, t_enemy[(e / 8) & 1], (e / 8) & 1 ? P_ENEMY_B : P_ENEMY_A, 1,
                SPR_HITBOX | (((ppu_frame() / 20) & 1) ? SPR_HFLIP : 0));
    for (int s = 0; s < N_SHOT; s++)
        if (shot[s].on) spr(S_SHOT + s, shot[s].x, shot[s].y, t_shot, P_SHOT, 0, SPR_HITBOX);
    for (int b = 0; b < N_BOMB; b++)
        if (bomb[b].on) spr(S_BOMB + b, bomb[b].x, bomb[b].y, t_bomb, P_BOMB, 0, SPR_HITBOX);
    for (int i = 0; i < N_BOOM; i++)
        if (boom[i].life) spr(S_BOOM + i, boom[i].x, boom[i].y, t_boom[boom[i].life < 12], P_BOOM, 0, 0);
    text_number(S_SCORE, 16, 12, (uint32_t)score, N_DIGITS, P_TEXT, 0);
    spr(S_STARS, 0, scroll, t_stars, P_STARS, 3, SPR_GIANT);
    spr(S_STARS + 1, 0, scroll - 480, t_stars, P_STARS, 3, SPR_GIANT);

    // the snapshot of this bank, for the frame that shows it
    snap_ship[back] = ship;
    if (invuln) snap_ship[back].on = 0;
    for (int e = 0; e < N_ENEMY; e++) snap_enemy[back][e] = enemy[e];
    for (int s = 0; s < N_SHOT; s++) snap_shot[back][s] = shot[s];
    for (int b = 0; b < N_BOMB; b++) snap_bomb[back][b] = bomb[b];
    ppu_leds((1u << (lives > 0 ? lives : 0)) - 1u);
}

static void palette(void)
{
    pal_set(0, RGB(0, 0, 1));
    pal_set(P_STARS * 16 + 1, RGB(5, 5, 6));  pal_set(P_STARS * 16 + 2, RGB(9, 9, 10)); pal_set(P_STARS * 16 + 3, RGB(15, 15, 15));
    pal_set(P_STARS * 16 + 4, RGB(7, 9, 15)); pal_set(P_STARS * 16 + 5, RGB(15, 13, 8));
    pal_set(P_SHIP * 16 + 1, RGB(15, 15, 15)); pal_set(P_SHIP * 16 + 2, RGB(4, 12, 15)); pal_set(P_SHIP * 16 + 3, RGB(2, 4, 12));
    pal_set(P_SHIP * 16 + 4, RGB(15, 5, 2));   pal_set(P_SHIP * 16 + 5, RGB(15, 13, 3));
    pal_set(P_ENEMY_A * 16 + 1, RGB(3, 13, 4)); pal_set(P_ENEMY_A * 16 + 2, RGB(10, 15, 6)); pal_set(P_ENEMY_A * 16 + 4, RGB(15, 2, 2));
    pal_set(P_ENEMY_B * 16 + 1, RGB(13, 3, 12)); pal_set(P_ENEMY_B * 16 + 2, RGB(15, 9, 14)); pal_set(P_ENEMY_B * 16 + 3, RGB(7, 2, 10));
    pal_set(P_ENEMY_B * 16 + 4, RGB(15, 15, 2));
    pal_set(P_SHOT * 16 + 1, RGB(15, 15, 6)); pal_set(P_SHOT * 16 + 2, RGB(15, 15, 15));
    pal_set(P_BOMB * 16 + 1, RGB(15, 4, 2));  pal_set(P_BOMB * 16 + 2, RGB(15, 10, 2));
    pal_set(P_BOOM * 16 + 1, RGB(15, 14, 4)); pal_set(P_BOOM * 16 + 2, RGB(15, 9, 2)); pal_set(P_BOOM * 16 + 3, RGB(13, 3, 1));
    pal_set(P_BOOM * 16 + 4, RGB(15, 15, 15));
    pal_set(P_TEXT * 16 + 1, RGB(15, 15, 15));
}

int main(void)
{
    ppu_pins();
    palette();
    t_ship = tex_art(ship_art, 16, 16, 2);
    t_enemy[0] = tex_art(enemy_a_art, 16, 16, 2);
    t_enemy[1] = tex_art(enemy_b_art, 16, 16, 2);
    t_shot = tex_art(shot_art, 8, 16, 1);
    t_bomb = tex_art(bomb_art, 8, 8, 1);
    t_boom[0] = tex_art(boom1_art, 16, 16, 2);
    t_boom[1] = tex_art(boom2_art, 16, 16, 2);
    text_init(2);
    t_stars = tex_fn(320, 240, 0, star);

    idle_frames = 1000;                 // start in attract mode
    ship = (obj_t){304, 420, 1, next_id++};
    new_wave();
    back = 1;
    draw();                             // bank 1, which ppu_start copies to bank 0 for the first frame
    ppu_start(GIANT_SIZE(320, 240, 1));
    back = 1;
    for (;;) {
        ppu_wait_frame();
        collide();
        update();
        draw();
        ppu_present();
        back ^= 1u;
    }
}
