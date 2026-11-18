"""The workloads of the benchmark, by name. Each function returns a Workload (model/workload.py).

empty_black    the control case: no sprite and a black backdrop, so it is right even with no renderer
sprites_basic  every rule of the spec at least once: a 2x-scaled giant background, 4bpp and 8bpp, palettes, flips,
               priorities and index ties, sprites off every edge, pixel-exact hitboxes (one hit, one near miss, one hidden hit)

Stress workloads: each one pushes one limit, and the model reports the load it asks for (expected.json "load": the deepest
stack of sprites over one pixel, the most sprites on one line).
sparse         a few small sprites on the backdrop: the light case
line_storm     80 sprites side by side on the same lines (81 on a line with the background, but only 2 deep): what a fixed
               per-line design (NES) cannot do and a slot design that frees slots behind the beam can
stack_7        7 sprites on the same pixels over the background: 8 deep, exactly the base design's 8 slots
stack_16       16 sprites on the same pixels over the background: 17 deep, more than the base design's slots
bandwidth_8bpp 6 overlapping 64x64 8bpp sprites over the background: few enough slots, but each slot needs a texture word
               every 4 pixels: the texture bus's bandwidth is the limit
busy_screen    all 128 sprites: the background and 127 random ones (sizes, depths, flips, palettes, hitboxes; seed fixed)

Sweeps (one knob a ladder; a version's capacity is the last step it passes):
depth_N        N deep: N-1 stacked 32x32 4bpp sprites over the background, N = 4 .. 24
bw_N           N overlapping 64x64 8bpp sprites over the background, N = 2 .. 10
"""

import random

from workload import Workload, rgb444


def empty_black():
    wl = Workload("empty_black", "no sprite, black backdrop")
    wl.palette(0, rgb444(0, 0, 0))
    return wl


def _disc(r):
    """A filled disc of radius r in a 2r x 2r box: colour 1 inside, 2 on its rim, 0 (transparent) outside."""
    def px(u, v):
        d = (u - r + 0.5) ** 2 + (v - r + 0.5) ** 2
        return 0 if d > r * r else (2 if d > (r - 2) ** 2 else 1)
    return px


def _arrow(u, v):
    """16x16, asymmetric both ways so every flip is visible: an 'F'-like shape."""
    if u < 3:
        return 1                                  # the stem, on the left
    if v < 3 and u < 14:
        return 2                                  # the top bar
    if 6 <= v < 9 and u < 10:
        return 3                                  # the middle bar
    return 0


def _palette(wl):
    """entry 0 the backdrop; bank 0 (1..15) the background; banks 1..3 (16..63) sprite colours; 64..255 an 8bpp ramp."""
    wl.palette(0, rgb444(1, 1, 2))
    for n in range(1, 16):
        wl.palette(n, rgb444(n, 15 - n, (n * 7) & 15))
    for bank, (a, b, c) in {1: ((15, 0, 0), (15, 15, 15), (15, 15, 0)),
                            2: ((0, 15, 0), (0, 0, 0), (0, 15, 15)),
                            3: ((0, 0, 15), (15, 0, 15), (8, 8, 8))}.items():
        wl.palette(bank * 16 + 1, rgb444(*a))
        wl.palette(bank * 16 + 2, rgb444(*b))
        wl.palette(bank * 16 + 3, rgb444(*c))
    for n in range(64, 256):
        wl.palette(n, rgb444(n >> 4, (n >> 2) & 15, n & 15))


def _background(wl):
    """The background: a giant 320x240 4bpp texture shown at 2x, with holes (index 0) where the backdrop shows through."""
    wl.set_giant(320, 240, scale2=True)

    def bg(u, v):
        if (u // 40 + v // 40) % 5 == 4 and (u % 40) < 8:
            return 0
        return 1 + ((u // 20) + (v // 20)) % 15
    return wl.texture(320, 240, bpp8=False, pixel=bg)


def sprites_basic():
    wl = Workload("sprites_basic", "giant background, 4bpp/8bpp, flips, priorities, edges, hitboxes")
    _palette(wl)
    bg_tex = _background(wl)

    disc16 = wl.texture(16, 16, bpp8=False, pixel=_disc(8))
    disc32 = wl.texture(32, 32, bpp8=False, pixel=_disc(16))
    arrow = wl.texture(16, 16, bpp8=False, pixel=_arrow)
    ramp = wl.texture(64, 64, bpp8=True, pixel=lambda u, v: 0 if (u - 32) ** 2 + (v - 32) ** 2 < 64 else 64 + (u * 4 + v) % 192)
    tall = wl.texture(8, 64, bpp8=False, pixel=lambda u, v: 1 + (v // 8) % 3)

    s = wl.sprite
    # flips: the same arrow four ways, side by side
    s(arrow, 40, 40, pal=1)
    s(arrow, 60, 40, pal=1, hflip=True)
    s(arrow, 80, 40, pal=1, vflip=True)
    s(arrow, 100, 40, pal=1, hflip=True, vflip=True)
    # priorities: prio 2 under prio 1 under prio 0; and a tie, where the lower index wins
    s(disc32, 200, 100, pal=3, prio=2)
    s(disc32, 212, 110, pal=2, prio=1)
    s(disc32, 224, 120, pal=1, prio=0)
    s(disc16, 300, 100, pal=1, prio=1)                 # tie with the next one: this lower index is in front
    s(disc16, 306, 104, pal=2, prio=1)
    # 8bpp with a transparent hole, on top of a 4bpp sprite
    s(ramp, 400, 200, prio=0)
    s(tall, 420, 190, pal=2, prio=1)
    # off every edge
    s(disc32, -12, 150, pal=1)                         # left
    s(disc32, 625, 300, pal=2)                         # right
    s(disc32, 50, -20, pal=3)                          # top
    s(ramp, 500, 440)                                  # bottom
    s(disc16, -40, 400, pal=1)                         # wholly off the left: drawn nowhere
    # hitboxes (section 7)
    s(disc16, 100, 300, pal=1, hitbox=True)            # A: opaque overlap with B -> both hit
    s(disc16, 110, 300, pal=2, hitbox=True)            # B
    s(disc16, 200, 300, pal=1, hitbox=True)            # C: boxes overlap at a corner, the corners are transparent -> no hit
    s(disc16, 213, 313, pal=2, hitbox=True)            # D
    s(disc32, 290, 290, pal=3, prio=0)                 # a cover, no hitbox, in front of E and F
    s(disc16, 296, 296, pal=1, prio=2, hitbox=True)    # E: hidden behind the cover, still overlaps F -> both hit
    s(disc16, 302, 300, pal=2, prio=2, hitbox=True)    # F
    s(disc16, 400, 350, pal=1, hitbox=True)            # G: overlaps H, which has no hitbox -> no hit
    s(disc16, 405, 352, pal=3)                         # H

    # the background last: the highest index, so it loses every tie as well as on prio
    s(bg_tex, 0, 0, pal=0, prio=3, giant=True, index=127)
    return wl


def sparse():
    wl = Workload("sparse", "4 small sprites on the backdrop, no background")
    _palette(wl)
    disc16 = wl.texture(16, 16, bpp8=False, pixel=_disc(8))
    arrow = wl.texture(16, 16, bpp8=False, pixel=_arrow)
    wl.sprite(disc16, 100, 100, pal=1)
    wl.sprite(arrow, 300, 200, pal=2, hflip=True)
    wl.sprite(disc16, 500, 300, pal=3)
    wl.sprite(arrow, 600, 450, pal=1, vflip=True)
    return wl


def line_storm():
    wl = Workload("line_storm", "80 8x8 sprites side by side on the same 8 lines, over the background")
    _palette(wl)
    bg_tex = _background(wl)
    tile = wl.texture(8, 8, bpp8=False, pixel=lambda u, v: 0 if (u, v) in ((0, 0), (7, 0), (0, 7), (7, 7)) else 1 + (u + v) % 3)
    for n in range(80):
        wl.sprite(tile, 8 * n, 236, pal=1 + n % 3, hflip=bool(n & 1), vflip=bool(n & 2))
    wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
    return wl


def _stack(n):
    wl = Workload(f"stack_{n}", f"{n} 32x32 sprites on the same pixels (offsets of 1 pixel), over the background")
    _palette(wl)
    bg_tex = _background(wl)
    disc32 = wl.texture(32, 32, bpp8=False, pixel=_disc(16))
    for i in range(n):
        wl.sprite(disc32, 300 + i, 220 + i, pal=1 + i % 3, prio=i % 3)
    wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
    return wl


def stack_7():
    return _stack(7)


def stack_16():
    return _stack(16)


def bandwidth_8bpp():
    wl = Workload("bandwidth_8bpp", "6 overlapping 64x64 8bpp sprites over the background: one texture word every 4 pixels each")
    _palette(wl)
    bg_tex = _background(wl)
    ramp = wl.texture(64, 64, bpp8=True, pixel=lambda u, v: 64 + (u * 3 + v * 5) % 192)
    for i in range(6):
        wl.sprite(ramp, 200 + 8 * i, 200 + 8 * i, prio=i % 3, hflip=bool(i & 1))
    wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
    return wl


def busy_screen():
    wl = Workload("busy_screen", "the background and 127 random sprites: sizes, depths, flips, palettes, hitboxes (seed 1)")
    rng = random.Random(1)
    _palette(wl)
    bg_tex = _background(wl)
    textures = [
        wl.texture(8, 8, bpp8=False, pixel=_disc(4)),
        wl.texture(16, 16, bpp8=False, pixel=_disc(8)),
        wl.texture(16, 16, bpp8=False, pixel=_arrow),
        wl.texture(32, 32, bpp8=False, pixel=_disc(16)),
        wl.texture(64, 32, bpp8=False, pixel=lambda u, v: 0 if (u // 8 + v // 8) % 2 else 1 + (u // 16) % 3),
        wl.texture(32, 32, bpp8=True, pixel=lambda u, v: 0 if (u - 16) ** 2 + (v - 16) ** 2 > 256 else 64 + (u * 5 + v) % 192),
        wl.texture(64, 64, bpp8=True, pixel=lambda u, v: 0 if (u - 32) ** 2 + (v - 32) ** 2 < 100 else 64 + (u + v * 3) % 192),
    ]
    for i in range(127):
        t = rng.choice(textures)
        wl.sprite(t, rng.randrange(-t.w // 2, 640), rng.randrange(-t.h // 2, 480), pal=rng.randrange(1, 4),
                  prio=rng.randrange(0, 3), hflip=rng.random() < 0.5, vflip=rng.random() < 0.5, hitbox=rng.random() < 0.2)
    wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
    return wl


# ---- sweeps: one knob per ladder, so each version gets a capacity (the last step it passes), not one pass or fail ----
DEPTH_STEPS = (4, 8, 12, 16, 20, 24)
BW_STEPS = (2, 4, 6, 8, 10)


def _depth(n):
    """n deep with the background: n-1 32x32 4bpp discs stacked 1 pixel apart. Each step adds n slots and n/8 words a pixel."""
    def make():
        wl = Workload(f"depth_{n}", f"{n - 1} stacked 32x32 4bpp sprites over the background: {n} deep")
        _palette(wl)
        bg_tex = _background(wl)
        disc32 = wl.texture(32, 32, bpp8=False, pixel=_disc(16))
        for i in range(n - 1):
            wl.sprite(disc32, 300 + i, 200 + i, pal=1 + i % 3, prio=i % 3)
        wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
        return wl
    make.__name__ = f"depth_{n}"
    return make


def _bw(n):
    """n overlapping 64x64 8bpp sprites over the background: a texture word every 4 pixels each, so bandwidth climbs fastest."""
    def make():
        wl = Workload(f"bw_{n}", f"{n} overlapping 64x64 8bpp sprites over the background")
        _palette(wl)
        bg_tex = _background(wl)
        ramp = wl.texture(64, 64, bpp8=True, pixel=lambda u, v: 64 + (u * 3 + v * 5) % 192)
        for i in range(n):
            wl.sprite(ramp, 200 + 4 * i, 200 + 4 * i, prio=i % 3, hflip=bool(i & 1))
        wl.sprite(bg_tex, 0, 0, prio=3, giant=True, index=127)
        return wl
    make.__name__ = f"bw_{n}"
    return make


SWEEP = [_depth(n) for n in DEPTH_STEPS] + [_bw(n) for n in BW_STEPS]

WORKLOADS = {f.__name__: f for f in (empty_black, sprites_basic, sparse, line_storm, stack_7, stack_16, bandwidth_8bpp,
                                     busy_screen, *SWEEP)}
