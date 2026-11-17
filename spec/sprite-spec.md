# Sprite and texture spec (v0)

The contract between the firmware, the RTL and the golden model. Whatever this file says is the right
picture; a render that differs from it, or is late, is wrong.

Status: v0, 2026-11-18. Addresses and register bits are those of `version/base/doc/system.yaml` and
`version/base/doc/ppu.yaml` (and `fw/soc.h`, generated from them); section 9 lists them.

## 0. Architecture in one paragraph

Race the beam only. The render unit (`ppu0`) is a bus master on both buses: on bus main it reads the sprite
table (`oam0`) itself and writes back per-line sprite lists (`lst0`, sprite indices only, never texels); on
bus tex it reads textures and the palette (`tex0`); and it streams each finished pixel straight into the
VGA output unit `racer0`, which holds no buffer: `racer0` names the pixel it needs (`x`, `y`, one pixel ahead of
the beam) and `ppu0` answers on `pixel`. The core sets things up and starts it; there is no fetch engine.

How the render unit gets there in time is its own business (the benchmark compares ways of doing it); the
plan for v0: while line `y` is on show, scan OAM and write the sprites of line `y+1`, sorted by `x`, into a
list in `lst0` (two lists, one being read, one being written, no length limit); while drawing, walk the list
left to right and keep only the sprites that cover the current pixel in a small active set, prefetching
their texels over bus tex ahead of the beam.

## 1. Screen

- 640 x 480, the standard VGA raster (800 x 525, 60 Hz), pixel clock 25 MHz.
- Output colour: rgb444 (the Basys3 connector).
- Screen coordinates: `sx` 0..639 left to right, `sy` 0..479 top to bottom.

## 2. OAM: the sprite table

- 128 sprites, 8 bytes each: one OAM bank is 1 KB.
- Sprite `i` is at `OAM0_BASE + 8*i`: word 0 at `+0`, word 1 at `+4` (little endian, as the core stores them).
- One bank. The core writes it before `CTRL.START`; writing it while the engine runs is undefined.
- `lst0` belongs to the render unit: the core must not touch it while the engine runs.

### Word 0: placement (the render unit needs only this word to decide whether a sprite is on a line)

| bits    | field    | meaning |
|---------|----------|---------|
| [9:0]   | `y`      | top edge, signed two's complement, -512..511 |
| [20:10] | `x`      | left edge, signed two's complement, -1024..1023 |
| [23:21] | `w`      | texture width  = (w + 1) * 8 pixels (8..64) |
| [26:24] | `h`      | texture height = (h + 1) * 8 pixels (8..64) |
| [27]    | `giant`  | 1: ignore `w` and `h`; the size and scale come from the `GIANT` register (section 4) |
| [28]    | `enable` | 0: the sprite does not exist (not drawn, takes no part in hits) |
| [29]    | `hflip`  | mirror left-right |
| [30]    | `vflip`  | mirror top-bottom |
| [31]    | `hitbox` | 1: the sprite takes part in hit detection (section 7) |

### Word 1: appearance (read only for the sprites that are on the line)

| bits    | field  | meaning |
|---------|--------|---------|
| [13:0]  | `tex`  | texture start in texture SRAM, in 32-byte units (byte address `tex * 32`) |
| [17:14] | `pal`  | palette bank, 0..15 (4bpp only; ignored for 8bpp) |
| [18]    | `bpp8` | 0: 4 bits per pixel (16 colours), 1: 8 bits per pixel (256 colours) |
| [20:19] | `prio` | draw order, 0 is in front |
| [31:21] | -      | reserved, write 0; the hardware ignores them |

## 3. Size and scale

For a sprite, `W` and `H` are the texture size in pixels and `s` the scale:

| sprite      | `W`                | `H`                | `s` |
|-------------|--------------------|--------------------|-----|
| `giant = 0` | `(w + 1) * 8`      | `(h + 1) * 8`      | 1   |
| `giant = 1` | `GIANT.W`          | `GIANT.H`          | 2 if `GIANT.SCALE2`, else 1 |

The sprite covers the screen rectangle `x <= sx < x + W*s`, `y <= sy < y + H*s`. Only the part inside the
screen is drawn; there is no wrap-around (the coordinates are signed, so a sprite can stick out of any edge).

## 4. The GIANT register

One register for the whole engine, shared by every sprite with `giant = 1`. Written before the engine starts.

| bits    | field    | meaning |
|---------|----------|---------|
| [9:0]   | `W`      | texture width in pixels, a multiple of 8, 8..1016 |
| [19:10] | `H`      | texture height in pixels, a multiple of 8, 8..1016 |
| [20]    | `SCALE2` | 1: every texture pixel is shown as 2 x 2 screen pixels |
| [31:21] | -        | reserved, write 0 |

A `W` or `H` that is 0 or not a multiple of 8 is undefined.

The intended background: `GIANT = {W: 320, H: 240, SCALE2: 1}`, one sprite with `giant = 1`, `x = y = 0`,
`prio = 3`, at the highest OAM index (so it loses every tie), 4bpp: 38,400 bytes of texture.

## 5. Texture SRAM

The texture SRAM is one byte address space on bus B (its size and number of banks depend on the
configuration). It is static: written by the core through the loader before the engine starts, and only read
after that. Any loader access after `CTRL.START` is refused (an AHB error response) and changes nothing:
bus tex then belongs to the render unit alone. The core reaches the texture SRAM only through the loader
window (`TEXLD0_BASE + k` is texture byte `k`).

### Palette

- Bytes 0..511 of the texture SRAM: 256 entries of 16 bits, entry `n` at byte `2*n`.
- An entry holds rgb444 in bits [11:0] (red [11:8], green [7:4], blue [3:0]); bits [15:12] are ignored.
- 4bpp sprites use entries `pal*16 + 0 .. pal*16 + 15`; 8bpp sprites use all 256.
- **Entry 0 is the backdrop**: the colour of every screen pixel that no sprite covers with an opaque pixel.

A texture placed over bytes 0..511 overwrites the palette; that is the firmware's mistake, not undefined
hardware behaviour (both read the same bytes).

### Texture layout

A texture is a row-major bitmap, rows top to bottom, pixels left to right, with no padding:

- 8bpp: pixel `(u, v)` is the byte at `tex*32 + v*W + u`.
- 4bpp: pixel `(u, v)` is in the byte at `tex*32 + (v*W + u) / 2`; an even `u` is the low nibble [3:0],
  an odd `u` the high nibble [7:4].

Since `W` is a multiple of 8, a 4bpp row is a multiple of 4 bytes and an 8bpp row a multiple of 8, so a row
starts on a 32-bit boundary.

A texture that runs past the end of the texture SRAM is undefined (the golden model reports it as an error).

## 6. Drawing a pixel

For screen pixel `(sx, sy)` and an enabled sprite whose rectangle covers it:

```
u = (sx - x) / s          integer division, s is 1 or 2
v = (sy - y) / s
if hflip: u = W - 1 - u
if vflip: v = H - 1 - v
c = texel(u, v)           the 4- or 8-bit colour index from section 5
```

- `c == 0` is **transparent**: the sprite does not cover the pixel (for 4bpp it is the nibble that is 0,
  whatever `pal` is).
- Otherwise the sprite is **opaque** at the pixel and its colour is
  `palette[pal*16 + c]` (4bpp) or `palette[c]` (8bpp).

The screen pixel takes the colour of the opaque sprite with the smallest `(prio, i)`: the lowest `prio`
wins, and between equal `prio` the lowest OAM index `i` wins. With no opaque sprite it is the backdrop,
`palette[0]`.

There is no limit on the number of sprites on a line or on the screen. Hardware that cannot produce a pixel
in time misses its deadline (section 8); that is a result of the benchmark, not a change of the picture.

## 7. Hit detection

- Sprite `i` is **hit** when there is a screen pixel (inside 0..639 x 0..479) at which `i` and at least one
  other sprite `j` are both enabled, both have `hitbox = 1`, and are both opaque.
- What is in front does not matter: a hitbox sprite hidden behind another sprite still hits.
- Parts of a sprite outside the screen never hit.
- The result is `HIT[127:0]`, one bit per OAM index, readable as four 32-bit words (`HIT0` holds sprites 0..31,
  bit `k` = sprite `k`). It is 0 after reset and valid once `STATUS.DONE` is 1.

How hardware may find it (not part of the contract, only a hint): keep, per pixel, the index of one opaque
hitbox sprite already drawn there; when another opaque hitbox sprite draws the same pixel, set the hit bit of
both. This finds every sprite of the definition above, however many overlap.

## 8. One frame per reset

The unit of a benchmark run is one frame after one reset:

1. Reset. Every register is 0, `HIT` is 0.
2. The firmware writes the palette and the textures through the loader, the OAM bank and `GIANT`.
3. The firmware sets `CTRL.START`. From then on the texture SRAM is read-only.
4. The engine loads the palette from the texture SRAM, waits for the next vertical blanking (it
   prepares line 0 there), renders exactly the one frame that follows it, and sets `STATUS.DONE` a few
   pixels after that frame's last line (`sy = 479`).
5. The run is **right** when every one of the 640 x 480 pixels equals the golden model's picture and
   `STATUS.LATE` is 0. Anything else is **wrong**.

### Deadline miss

- The render unit races the beam: it holds no line buffer and no frame buffer, and hands the VGA each pixel
  as it is scanned out. A pixel that is not ready when the VGA needs it is a miss.
- The hardware shows a missed pixel as black (rgb444 0x000) and counts it: `STATUS.LATE` is the number of
  late pixels, saturating.
- A miss always makes the run wrong, even if the shown pixel happens to equal the right one.

## 9. Registers named in this spec

Render unit registers at `PPU0_BASE` (0x30000000):

| offset | name           | fields |
|--------|----------------|--------|
| 0x000  | `CTRL`         | `START` [0], write 1 to start (write only, an event) |
| 0x004  | `STATUS`       | `DONE` [0], `BUSY` [1] (read only) |
| 0x008  | `LATE`         | `COUNT` [31:0], late pixels (read only) |
| 0x00C  | `GIANT`        | `W` [9:0], `H` [19:10], `SCALE2` [20] (section 4) |
| 0x010  | `HIT0`..`HIT3` | `BITS` [31:0], sprites 32n..32n+31 (section 7) |

Memory map of bus main: `sram0` program 0x00000000 (64 KB), `oam0` 0x20000000 (1 KB), `lst0` 0x20010000
(4 KB), `ppu0` 0x30000000, `texld0` 0x31000000 (64 KB window onto bus tex), `gpio0` 0x40000000. Bus tex:
`tex0` 0x00000000 (64 KB).

## 10. Not in v0

Line buffers (L+1 rendering), a separate fetch engine, affine sprites (rotation, free scaling), mosaic, blending and transparency levels, a per-line sprite
limit, more than one frame per reset, writing textures while the engine runs.
