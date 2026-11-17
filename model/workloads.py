"""The workloads of the benchmark, by name. Each function returns a Workload (model/workload.py).

empty_black    the control case: no sprite and a black backdrop, so it is right even with no renderer
sprites_basic  every rule of the spec at least once: a 2x-scaled giant background, 4bpp and 8bpp, palettes, flips,
               priorities and index ties, sprites off every edge, pixel-exact hitboxes (one hit, one near miss, one hidden hit)
"""

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


def sprites_basic():
    wl = Workload("sprites_basic", "giant background, 4bpp/8bpp, flips, priorities, edges, hitboxes")

    # palette: entry 0 the backdrop; bank 0 the background; banks 1..3 (16..63) sprite colours; 64..255 the 8bpp ramp
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

    # the background: a giant 320x240 4bpp texture shown at 2x; index 0 in a few holes so the backdrop shows through
    wl.set_giant(320, 240, scale2=True)

    def bg(u, v):
        if (u // 40 + v // 40) % 5 == 4 and (u % 40) < 8:
            return 0                                   # holes: the backdrop
        return 1 + ((u // 20) + (v // 20)) % 15
    bg_tex = wl.texture(320, 240, bpp8=False, pixel=bg)

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


WORKLOADS = {f.__name__: f for f in (empty_black, sprites_basic)}
