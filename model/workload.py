"""Workloads: what one frame is asked to show, built into the exact bytes the firmware hands the chip.

A Workload holds the texture SRAM image (palette at 0..511, then the textures, each 32-byte aligned), the 128 OAM entries
packed as spec/sprite-spec.md section 2 says, and the GIANT register. ppu_model.render() and the firmware both start from
those bytes, never from the Python objects.
"""

from ppu_model import N_SPRITES, PALETTE_BYTES, SCREEN_H, SCREEN_W

TEX_SRAM_BYTES = 64 * 1024     # tex0 in system.yaml


def rgb444(r, g, b):
    return ((r & 0xF) << 8) | ((g & 0xF) << 4) | (b & 0xF)


def _check(cond, msg):
    if not cond:
        raise ValueError(msg)


class Texture:
    """A placed texture: its 32-byte unit address and its size."""

    def __init__(self, tex, w, h, bpp8):
        self.tex, self.w, self.h, self.bpp8 = tex, w, h, bpp8


class Workload:
    def __init__(self, name, desc):
        self.name, self.desc = name, desc
        self.image = bytearray(PALETTE_BYTES)        # grows as textures are added
        self.oam = [0] * (2 * N_SPRITES)
        self.giant = 0
        self.used = 0                                 # sprites placed so far, in OAM order

    # ---- palette (section 5): 256 entries of 16 bits; entry 0 is the backdrop ----
    def palette(self, n, colour):
        _check(0 <= n < 256, f"palette entry {n}")
        self.image[2 * n] = colour & 0xFF
        self.image[2 * n + 1] = (colour >> 8) & 0x0F

    # ---- textures (section 5): row-major, 4bpp even u in the low nibble ----
    def texture(self, w, h, bpp8, pixel):
        """pixel(u, v) -> colour index (0 = transparent). Returns the placed Texture."""
        _check(w % 8 == 0 and h % 8 == 0 and w > 0 and h > 0, f"texture {w}x{h}: a multiple of 8 each way")
        while len(self.image) % 32:
            self.image.append(0)
        start = len(self.image)
        for v in range(h):
            for u in range(w):
                c = pixel(u, v)
                _check(0 <= c < (256 if bpp8 else 16), f"texel ({u},{v}) = {c}: out of range")
                if bpp8:
                    self.image.append(c)
                elif u & 1:
                    self.image[-1] |= c << 4
                else:
                    self.image.append(c)
        _check(len(self.image) <= TEX_SRAM_BYTES, f"textures need {len(self.image)} bytes, the texture SRAM has {TEX_SRAM_BYTES}")
        return Texture(start // 32, w, h, bpp8)

    def set_giant(self, w, h, scale2):
        _check(w % 8 == 0 and h % 8 == 0 and 8 <= w <= 1016 and 8 <= h <= 1016, f"GIANT {w}x{h}")
        self.giant = w | (h << 10) | ((1 if scale2 else 0) << 20)

    # ---- sprites (section 2) ----
    def sprite(self, t, x, y, pal=0, prio=0, hflip=False, vflip=False, hitbox=False, giant=False, index=None):
        """Place texture t at (x, y). Normal sprites take their size from t (8..64 each way); giant ones from GIANT."""
        i = self.used if index is None else index
        _check(0 <= i < N_SPRITES, f"sprite index {i}")
        _check(-512 <= y <= 511 and -1024 <= x <= 1023, f"sprite {i} at ({x},{y}): out of the signed range")
        _check(0 <= pal < 16 and 0 <= prio < 4, f"sprite {i}: pal {pal} prio {prio}")
        if giant:
            gw, gh = self.giant & 0x3FF, (self.giant >> 10) & 0x3FF
            _check((t.w, t.h) == (gw, gh), f"sprite {i}: giant texture {t.w}x{t.h} but GIANT is {gw}x{gh}")
            wcode = hcode = 0
        else:
            _check(t.w <= 64 and t.h <= 64, f"sprite {i}: {t.w}x{t.h} is over 64: make it giant")
            wcode, hcode = t.w // 8 - 1, t.h // 8 - 1
        w0 = ((y & 0x3FF) | ((x & 0x7FF) << 10) | (wcode << 21) | (hcode << 24) | (int(giant) << 27) | (1 << 28)
              | (int(hflip) << 29) | (int(vflip) << 30) | (int(hitbox) << 31))
        w1 = t.tex | (pal << 14) | (int(t.bpp8) << 18) | (prio << 19)
        self.oam[2 * i], self.oam[2 * i + 1] = w0, w1
        self.used = max(self.used, i + 1)
        return i

    def tex_bytes(self):
        """The texture SRAM image, padded to whole 32-bit words."""
        b = bytes(self.image)
        return b + bytes(-len(b) % 4)


__all__ = ["Workload", "Texture", "rgb444", "SCREEN_W", "SCREEN_H", "TEX_SRAM_BYTES"]
