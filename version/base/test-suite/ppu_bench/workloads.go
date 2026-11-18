// Workloads: what one frame is asked to show, built into the exact bytes the firmware hands the chip.
//
// A workload holds the texture SRAM image (palette at 0..511, then the textures, each 32-byte aligned), the 128 OAM entries
// packed as spec/sprite-spec.md section 2 says, and the GIANT register. render() and the firmware both start from those bytes.
//
//	empty_black     the control case: no sprite and a black backdrop, so it is right even with no renderer
//	sprites_basic   every rule of the spec at least once: a 2x-scaled giant background, 4bpp and 8bpp, palettes, flips,
//	                priorities and index ties, sprites off every edge, pixel-exact hitboxes (a hit, a near miss, a hidden hit)
//	sparse          a few small sprites on the backdrop: the light case
//	line_storm      80 sprites side by side on the same lines (81 on a line with the background, 2 deep)
//	stack_7/16      7 or 16 sprites on the same pixels over the background: 8 or 17 deep
//	bandwidth_8bpp  6 overlapping 64x64 8bpp sprites: a texture word every 4 pixels each
//	busy_screen     all 128 sprites: the background and 127 random ones (seed fixed)
//	pile_96         96 8x8 sprites on one spot at the top left: far more than the slots, all but one hidden
//	depth_N, bw_N   the ladders (category bench): N deep (N-1 stacked 32x32 4bpp), N overlapping 64x64 8bpp
//	admit_N         the admission ladder (bench): N 8x8 sprites spread along one line band, 2 deep, light on bandwidth
package ppubench

import (
	"fmt"
	"math"
)

const texSRAMBytes = 64 * 1024 // tex0

type texture struct {
	tex, w, h int // tex in 32-byte units
	bpp8      bool
}

type workload struct {
	name, desc string
	image      []byte
	oam        [2 * nSprites]uint32
	giant      uint32
	used       int
}

func newWorkload(name, desc string) *workload {
	return &workload{name: name, desc: desc, image: make([]byte, paletteBytes)}
}

func rgb(r, g, b int) uint16 { return uint16((r&15)<<8 | (g&15)<<4 | b&15) }

// palette sets entry n (section 5): 256 entries of 16 bits; entry 0 is the backdrop.
func (wl *workload) palette(n int, c uint16) {
	wl.image[2*n] = byte(c)
	wl.image[2*n+1] = byte(c>>8) & 0x0F
}

// texture places a texture: row-major, 4bpp with the even u in the low nibble; pixel gives the colour index (0 transparent).
func (wl *workload) texture(w, h int, bpp8 bool, pixel func(u, v int) int) texture {
	if w%8 != 0 || h%8 != 0 || w <= 0 || h <= 0 {
		panic(fmt.Sprintf("texture %dx%d: a multiple of 8 each way", w, h))
	}
	for len(wl.image)%32 != 0 {
		wl.image = append(wl.image, 0)
	}
	start := len(wl.image)
	for v := 0; v < h; v++ {
		for u := 0; u < w; u++ {
			c := pixel(u, v)
			switch {
			case bpp8:
				wl.image = append(wl.image, byte(c))
			case u&1 != 0:
				wl.image[len(wl.image)-1] |= byte(c&15) << 4
			default:
				wl.image = append(wl.image, byte(c&15))
			}
		}
	}
	if len(wl.image) > texSRAMBytes {
		panic(fmt.Sprintf("%s: textures need %d bytes, the texture SRAM has %d", wl.name, len(wl.image), texSRAMBytes))
	}
	return texture{start / 32, w, h, bpp8}
}

func (wl *workload) setGiant(w, h int, scale2 bool) {
	wl.giant = uint32(w) | uint32(h)<<10
	if scale2 {
		wl.giant |= 1 << 20
	}
}

// spr says how a sprite is drawn; index -1 is the next free entry.
type spr struct {
	pal, prio                   int
	hflip, vflip, hitbox, giant bool
	index                       int
}

func b2u(b bool) uint32 {
	if b {
		return 1
	}
	return 0
}

// sprite places texture t at (x, y) (section 2). Normal sprites take their size from t (8..64 each way); giant ones from GIANT.
func (wl *workload) sprite(t texture, x, y int, o spr) int {
	i := wl.used
	if o.index > 0 {
		i = o.index
	}
	var wc, hc uint32
	if !o.giant {
		if t.w > 64 || t.h > 64 {
			panic(fmt.Sprintf("%s: sprite %d is %dx%d: over 64, make it giant", wl.name, i, t.w, t.h))
		}
		wc, hc = uint32(t.w/8-1), uint32(t.h/8-1)
	}
	wl.oam[2*i] = uint32(y)&0x3FF | (uint32(x)&0x7FF)<<10 | wc<<21 | hc<<24 | b2u(o.giant)<<27 | 1<<28 |
		b2u(o.hflip)<<29 | b2u(o.vflip)<<30 | b2u(o.hitbox)<<31
	wl.oam[2*i+1] = uint32(t.tex) | uint32(o.pal)<<14 | b2u(t.bpp8)<<18 | uint32(o.prio)<<19
	wl.used = max(wl.used, i+1)
	return i
}

// texBytes is the texture SRAM image, padded to whole 32-bit words.
func (wl *workload) texBytes() []byte {
	b := append([]byte(nil), wl.image...)
	for len(b)%4 != 0 {
		b = append(b, 0)
	}
	return b
}

// ---- shared pieces ----

// stdPalette: entry 0 the backdrop; bank 0 (1..15) the background; banks 1..3 sprite colours; 64..255 an 8bpp ramp.
func stdPalette(wl *workload) {
	wl.palette(0, rgb(1, 1, 2))
	for n := 1; n < 16; n++ {
		wl.palette(n, rgb(n, 15-n, (n*7)&15))
	}
	for bank, c := range map[int][3][3]int{
		1: {{15, 0, 0}, {15, 15, 15}, {15, 15, 0}},
		2: {{0, 15, 0}, {0, 0, 0}, {0, 15, 15}},
		3: {{0, 0, 15}, {15, 0, 15}, {8, 8, 8}},
	} {
		for k := 0; k < 3; k++ {
			wl.palette(bank*16+1+k, rgb(c[k][0], c[k][1], c[k][2]))
		}
	}
	for n := 64; n < 256; n++ {
		wl.palette(n, rgb(n>>4, (n>>2)&15, n&15))
	}
}

// background: a giant 320x240 4bpp texture shown at 2x, with holes (index 0) where the backdrop shows through.
func background(wl *workload) texture {
	wl.setGiant(320, 240, true)
	return wl.texture(320, 240, false, func(u, v int) int {
		if (u/40+v/40)%5 == 4 && u%40 < 8 {
			return 0
		}
		return 1 + (u/20+v/20)%15
	})
}

// disc: a filled disc of radius r in a 2r x 2r box: 1 inside, 2 on its rim, 0 outside.
func disc(r int) func(u, v int) int {
	return func(u, v int) int {
		d := math.Pow(float64(u-r)+0.5, 2) + math.Pow(float64(v-r)+0.5, 2)
		switch {
		case d > float64(r*r):
			return 0
		case d > float64((r-2)*(r-2)):
			return 2
		}
		return 1
	}
}

// arrow: 16x16, asymmetric both ways so every flip is visible
func arrow(u, v int) int {
	switch {
	case u < 3:
		return 1
	case v < 3 && u < 14:
		return 2
	case v >= 6 && v < 9 && u < 10:
		return 3
	}
	return 0
}

func bg(wl *workload, t texture) { wl.sprite(t, 0, 0, spr{prio: 3, giant: true, index: 127}) }

// ---- the workloads ----

func emptyBlack() *workload {
	wl := newWorkload("empty_black", "no sprite, black backdrop")
	wl.palette(0, rgb(0, 0, 0))
	return wl
}

func spritesBasic() *workload {
	wl := newWorkload("sprites_basic", "giant background, 4bpp/8bpp, flips, priorities, edges, hitboxes")
	stdPalette(wl)
	bgTex := background(wl)
	disc16 := wl.texture(16, 16, false, disc(8))
	disc32 := wl.texture(32, 32, false, disc(16))
	arr := wl.texture(16, 16, false, arrow)
	ramp := wl.texture(64, 64, true, func(u, v int) int {
		if (u-32)*(u-32)+(v-32)*(v-32) < 64 {
			return 0
		}
		return 64 + (u*4+v)%192
	})
	tall := wl.texture(8, 64, false, func(u, v int) int { return 1 + (v/8)%3 })

	s := wl.sprite
	// flips: the same arrow four ways
	s(arr, 40, 40, spr{pal: 1})
	s(arr, 60, 40, spr{pal: 1, hflip: true})
	s(arr, 80, 40, spr{pal: 1, vflip: true})
	s(arr, 100, 40, spr{pal: 1, hflip: true, vflip: true})
	// priorities: prio 2 under 1 under 0; and a tie, where the lower index wins
	s(disc32, 200, 100, spr{pal: 3, prio: 2})
	s(disc32, 212, 110, spr{pal: 2, prio: 1})
	s(disc32, 224, 120, spr{pal: 1, prio: 0})
	s(disc16, 300, 100, spr{pal: 1, prio: 1})
	s(disc16, 306, 104, spr{pal: 2, prio: 1})
	// 8bpp with a transparent hole, over a 4bpp sprite
	s(ramp, 400, 200, spr{prio: 0})
	s(tall, 420, 190, spr{pal: 2, prio: 1})
	// off every edge
	s(disc32, -12, 150, spr{pal: 1})
	s(disc32, 625, 300, spr{pal: 2})
	s(disc32, 50, -20, spr{pal: 3})
	s(ramp, 500, 440, spr{})
	s(disc16, -40, 400, spr{pal: 1}) // wholly off the left: drawn nowhere
	// hitboxes (section 7)
	s(disc16, 100, 300, spr{pal: 1, hitbox: true})          // A: opaque overlap with B -> both hit
	s(disc16, 110, 300, spr{pal: 2, hitbox: true})          // B
	s(disc16, 200, 300, spr{pal: 1, hitbox: true})          // C: boxes meet at transparent corners -> no hit
	s(disc16, 213, 313, spr{pal: 2, hitbox: true})          // D
	s(disc32, 290, 290, spr{pal: 3, prio: 0})               // a cover, no hitbox, in front of E and F
	s(disc16, 296, 296, spr{pal: 1, prio: 2, hitbox: true}) // E: hidden, still overlaps F -> both hit
	s(disc16, 302, 300, spr{pal: 2, prio: 2, hitbox: true}) // F
	s(disc16, 400, 350, spr{pal: 1, hitbox: true})          // G: overlaps H, which has no hitbox -> no hit
	s(disc16, 405, 352, spr{pal: 3})                        // H
	bg(wl, bgTex)
	return wl
}

func sparse() *workload {
	wl := newWorkload("sparse", "4 small sprites on the backdrop, no background")
	stdPalette(wl)
	disc16 := wl.texture(16, 16, false, disc(8))
	arr := wl.texture(16, 16, false, arrow)
	wl.sprite(disc16, 100, 100, spr{pal: 1})
	wl.sprite(arr, 300, 200, spr{pal: 2, hflip: true})
	wl.sprite(disc16, 500, 300, spr{pal: 3})
	wl.sprite(arr, 600, 450, spr{pal: 1, vflip: true})
	return wl
}

func lineStorm() *workload {
	wl := newWorkload("line_storm", "80 8x8 sprites side by side on the same 8 lines, over the background")
	stdPalette(wl)
	bgTex := background(wl)
	tile := wl.texture(8, 8, false, func(u, v int) int {
		if (u == 0 || u == 7) && (v == 0 || v == 7) {
			return 0
		}
		return 1 + (u+v)%3
	})
	for n := 0; n < 80; n++ {
		wl.sprite(tile, 8*n, 236, spr{pal: 1 + n%3, hflip: n&1 != 0, vflip: n&2 != 0})
	}
	bg(wl, bgTex)
	return wl
}

func stack(n int) func() *workload {
	return func() *workload {
		wl := newWorkload(fmt.Sprintf("stack_%d", n), fmt.Sprintf("%d 32x32 sprites on the same pixels, over the background", n))
		stdPalette(wl)
		bgTex := background(wl)
		disc32 := wl.texture(32, 32, false, disc(16))
		for i := 0; i < n; i++ {
			wl.sprite(disc32, 300+i, 220+i, spr{pal: 1 + i%3, prio: i % 3})
		}
		bg(wl, bgTex)
		return wl
	}
}

func bandwidth8bpp() *workload {
	wl := newWorkload("bandwidth_8bpp", "6 overlapping 64x64 8bpp sprites over the background")
	stdPalette(wl)
	bgTex := background(wl)
	ramp := wl.texture(64, 64, true, func(u, v int) int { return 64 + (u*3+v*5)%192 })
	for i := 0; i < 6; i++ {
		wl.sprite(ramp, 200+8*i, 200+8*i, spr{prio: i % 3, hflip: i&1 != 0})
	}
	bg(wl, bgTex)
	return wl
}

func busyScreen() *workload {
	wl := newWorkload("busy_screen", "the background and 127 random sprites: sizes, depths, flips, palettes, hitboxes")
	stdPalette(wl)
	bgTex := background(wl)
	texs := []texture{
		wl.texture(8, 8, false, disc(4)),
		wl.texture(16, 16, false, disc(8)),
		wl.texture(16, 16, false, arrow),
		wl.texture(32, 32, false, disc(16)),
		wl.texture(64, 32, false, func(u, v int) int {
			if (u/8+v/8)%2 != 0 {
				return 0
			}
			return 1 + (u/16)%3
		}),
		wl.texture(32, 32, true, func(u, v int) int {
			if (u-16)*(u-16)+(v-16)*(v-16) > 256 {
				return 0
			}
			return 64 + (u*5+v)%192
		}),
		wl.texture(64, 64, true, func(u, v int) int {
			if (u-32)*(u-32)+(v-32)*(v-32) < 100 {
				return 0
			}
			return 64 + (u+v*3)%192
		}),
	}
	r := xorshift(1)
	for i := 0; i < 127; i++ {
		t := texs[r.n(len(texs))]
		wl.sprite(t, r.n(640+t.w/2)-t.w/2, r.n(480+t.h/2)-t.h/2, spr{pal: 1 + r.n(3), prio: r.n(3),
			hflip: r.n(2) == 0, vflip: r.n(2) == 0, hitbox: r.n(5) == 0})
	}
	bg(wl, bgTex)
	return wl
}

// xorshift is a fixed-seed generator: the same workload on every machine and every run.
type xorshift uint32

func (x *xorshift) n(k int) int {
	v := uint32(*x)
	v ^= v << 13
	v ^= v >> 17
	v ^= v << 5
	*x = xorshift(v)
	return int(v % uint32(k))
}

// pile: n identical 8x8 sprites on the same spot at the top left, each its own palette bank. Only the front one is seen;
// the renderer cannot know that until it reads texels, so every one must be in a slot, more than there are.
func pile(n int) func() *workload {
	return func() *workload {
		wl := newWorkload(fmt.Sprintf("pile_%d", n), fmt.Sprintf("%d 8x8 sprites on one spot at the top left", n))
		stdPalette(wl)
		bgTex := background(wl)
		tile := wl.texture(8, 8, false, func(u, v int) int { return 1 + (u+v)%3 })
		for i := 0; i < n; i++ {
			wl.sprite(tile, 0, 0, spr{pal: 1 + i%3})
		}
		bg(wl, bgTex)
		return wl
	}
}

// ---- the ladders ----

var depthSteps = []int{4, 8, 12, 16, 20, 24}
var bwSteps = []int{2, 4, 6, 8, 10}
var admitSteps = []int{32, 64, 96, 120}

// admitN: N 8x8 4bpp sprites spread evenly along the same 8 lines (one every 640/N pixels), over the background. Depth stays
// about 2 and bandwidth about 10 bits a pixel, so the only thing that grows is how many sprites admission must load into slots
// within one line: about 9 bus-main cycles each, against 2 cycles a pixel of beam.
func admitN(n int) func() *workload {
	return func() *workload {
		wl := newWorkload(fmt.Sprintf("admit_%d", n), fmt.Sprintf("%d 8x8 sprites spread along one line band: admission rate", n))
		stdPalette(wl)
		bgTex := background(wl)
		tile := wl.texture(8, 8, false, func(u, v int) int {
			if (u == 0 || u == 7) && (v == 0 || v == 7) {
				return 0
			}
			return 1 + (u+v)%3
		})
		for i := 0; i < n; i++ {
			wl.sprite(tile, i*632/n, 236, spr{pal: 1 + i%3})
		}
		bg(wl, bgTex)
		return wl
	}
}

func depthN(n int) func() *workload {
	return func() *workload {
		wl := newWorkload(fmt.Sprintf("depth_%d", n), fmt.Sprintf("%d stacked 32x32 4bpp sprites over the background: %d deep", n-1, n))
		stdPalette(wl)
		bgTex := background(wl)
		disc32 := wl.texture(32, 32, false, disc(16))
		for i := 0; i < n-1; i++ {
			wl.sprite(disc32, 300+i, 200+i, spr{pal: 1 + i%3, prio: i % 3})
		}
		bg(wl, bgTex)
		return wl
	}
}

func bwN(n int) func() *workload {
	return func() *workload {
		wl := newWorkload(fmt.Sprintf("bw_%d", n), fmt.Sprintf("%d overlapping 64x64 8bpp sprites over the background", n))
		stdPalette(wl)
		bgTex := background(wl)
		ramp := wl.texture(64, 64, true, func(u, v int) int { return 64 + (u*3+v*5)%192 })
		for i := 0; i < n; i++ {
			wl.sprite(ramp, 200+4*i, 200+4*i, spr{prio: i % 3, hflip: i&1 != 0})
		}
		bg(wl, bgTex)
		return wl
	}
}

// workloads are every workload by name.
var workloads = func() map[string]func() *workload {
	m := map[string]func() *workload{
		"empty_black": emptyBlack, "sprites_basic": spritesBasic, "sparse": sparse, "line_storm": lineStorm,
		"stack_7": stack(7), "stack_16": stack(16), "bandwidth_8bpp": bandwidth8bpp, "busy_screen": busyScreen,
		"pile_96": pile(96),
	}
	for _, n := range depthSteps {
		m[fmt.Sprintf("depth_%d", n)] = depthN(n)
	}
	for _, n := range bwSteps {
		m[fmt.Sprintf("bw_%d", n)] = bwN(n)
	}
	for _, n := range admitSteps {
		m[fmt.Sprintf("admit_%d", n)] = admitN(n)
	}
	return m
}()
