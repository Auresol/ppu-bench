"""Golden model of the render unit: spec/sprite-spec.md, rule by rule.

It works from the same bytes the hardware gets, never from friendlier objects: the 128 packed OAM entries (two 32-bit
words each), the GIANT register and the texture SRAM image (palette at bytes 0..511, then the textures). So a mistake in
the encoding shows up here as well as in the RTL.

render(oam, giant, tex) -> Frame: 640 x 480 rgb444 pixels and the 128 hit bits.
"""

from dataclasses import dataclass

SCREEN_W, SCREEN_H = 640, 480
N_SPRITES = 128
PALETTE_BYTES = 512


class ModelError(Exception):
    """The workload is outside the spec (an 'undefined' case): the model refuses it instead of guessing."""


def _sext(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def _field(word, hi, lo):
    return (word >> lo) & ((1 << (hi - lo + 1)) - 1)


@dataclass(frozen=True)
class Sprite:
    """One decoded OAM entry (spec section 2), with its size resolved (section 3)."""
    index: int
    y: int
    x: int
    W: int          # texture width in pixels
    H: int          # texture height in pixels
    s: int          # scale: 1 or 2
    giant: bool
    enable: bool
    hflip: bool
    vflip: bool
    hitbox: bool
    tex: int        # in 32-byte units
    pal: int
    bpp8: bool
    prio: int

    @property
    def key(self):
        """Draw order: the smallest (prio, index) is in front (section 6)."""
        return (self.prio, self.index)


def decode_giant(giant):
    w, h, scale2 = _field(giant, 9, 0), _field(giant, 19, 10), _field(giant, 20, 20)
    return w, h, (2 if scale2 else 1)


def decode_sprite(index, word0, word1, giant):
    giant_bit = bool(_field(word0, 27, 27))
    if giant_bit:
        W, H, s = decode_giant(giant)
        if W == 0 or H == 0 or W % 8 or H % 8:
            raise ModelError(f"sprite {index}: giant with GIANT W={W} H={H}: must be non-zero multiples of 8 (section 4)")
    else:
        W, H, s = (_field(word0, 23, 21) + 1) * 8, (_field(word0, 26, 24) + 1) * 8, 1
    return Sprite(
        index=index,
        y=_sext(_field(word0, 9, 0), 10),
        x=_sext(_field(word0, 20, 10), 11),
        W=W, H=H, s=s,
        giant=giant_bit,
        enable=bool(_field(word0, 28, 28)),
        hflip=bool(_field(word0, 29, 29)),
        vflip=bool(_field(word0, 30, 30)),
        hitbox=bool(_field(word0, 31, 31)),
        tex=_field(word1, 13, 0),
        pal=_field(word1, 17, 14),
        bpp8=bool(_field(word1, 18, 18)),
        prio=_field(word1, 20, 19),
    )


def palette_entry(tex, n):
    """Palette entry n: 16 bits little endian at byte 2n, rgb444 in bits [11:0] (section 5)."""
    return (tex[2 * n] | (tex[2 * n + 1] << 8)) & 0x0FFF


def texel(sp, tex, u, v):
    """The colour index of texel (u, v) of sprite sp (section 5, texture layout)."""
    base = sp.tex * 32
    if sp.bpp8:
        return tex[base + v * sp.W + u]
    b = tex[base + (v * sp.W + u) // 2]
    return (b >> 4) & 0xF if u & 1 else b & 0xF


@dataclass
class Frame:
    pixels: list       # SCREEN_H rows of SCREEN_W rgb444 values
    hits: int          # bit i = sprite i was hit (section 7)
    load: dict         # what the frame asks of the hardware (not part of the picture): see render()

    def hit_words(self):
        return [(self.hits >> (32 * n)) & 0xFFFFFFFF for n in range(4)]


def render(oam, giant, tex):
    """oam: 256 words (sprite i = words 2i, 2i+1); giant: the GIANT register; tex: the texture SRAM image (bytes)."""
    if len(oam) != 2 * N_SPRITES:
        raise ModelError(f"oam has {len(oam)} words, not {2 * N_SPRITES}")
    if len(tex) < PALETTE_BYTES:
        raise ModelError("the texture image is shorter than the palette")

    sprites = [decode_sprite(i, oam[2 * i], oam[2 * i + 1], giant) for i in range(N_SPRITES)]
    sprites = [sp for sp in sprites if sp.enable]

    # every texture must lie inside the texture SRAM (section 5: past the end is undefined)
    for sp in sprites:
        end = sp.tex * 32 + (sp.W * sp.H if sp.bpp8 else sp.W * sp.H // 2)
        if end > len(tex):
            raise ModelError(f"sprite {sp.index}: texture ends at byte {end}, past the texture SRAM ({len(tex)} bytes)")

    INF = (99, 999)
    front = [[INF] * SCREEN_W for _ in range(SCREEN_H)]        # key of the opaque sprite in front so far
    colour = [[palette_entry(tex, 0)] * SCREEN_W for _ in range(SCREEN_H)]   # backdrop: palette[0]
    hit_owner = [[-1] * SCREEN_W for _ in range(SCREEN_H)]     # one opaque hitbox sprite already seen at the pixel
    hits = 0
    depth = [[0] * SCREEN_W for _ in range(SCREEN_H)]          # sprites whose rectangle covers the pixel, opaque or not
    per_line = [0] * SCREEN_H

    for sp in sprites:
        x0, x1 = max(sp.x, 0), min(sp.x + sp.W * sp.s, SCREEN_W)
        y0, y1 = max(sp.y, 0), min(sp.y + sp.H * sp.s, SCREEN_H)
        pal_base = 0 if sp.bpp8 else sp.pal * 16
        for sy in range(y0, y1):
            v = (sy - sp.y) // sp.s
            if sp.vflip:
                v = sp.H - 1 - v
            row_front, row_colour, row_owner = front[sy], colour[sy], hit_owner[sy]
            per_line[sy] += 1
            row_depth = depth[sy]
            for sx in range(x0, x1):
                row_depth[sx] += 1
                u = (sx - sp.x) // sp.s
                if sp.hflip:
                    u = sp.W - 1 - u
                c = texel(sp, tex, u, v)
                if c == 0:
                    continue                                   # transparent
                if sp.key < row_front[sx]:
                    row_front[sx] = sp.key
                    row_colour[sx] = palette_entry(tex, pal_base + c)
                if sp.hitbox:
                    other = row_owner[sx]
                    if other < 0:
                        row_owner[sx] = sp.index
                    elif other != sp.index:
                        hits |= (1 << other) | (1 << sp.index)

    # the load: the deepest stack of sprites over one pixel (what a slot design must hold at once) and the most sprites on one
    # line (what a fixed per-line design must hold), with where they are
    max_depth, at = 0, (0, 0)
    for sy in range(SCREEN_H):
        for sx in range(SCREEN_W):
            if depth[sy][sx] > max_depth:
                max_depth, at = depth[sy][sx], (sx, sy)
    line = max(range(SCREEN_H), key=lambda y: per_line[y])
    load = {"sprites": len(sprites), "max_depth": max_depth, "max_depth_at": list(at),
            "max_per_line": per_line[line], "max_per_line_at": line}
    return Frame(pixels=colour, hits=hits, load=load)
