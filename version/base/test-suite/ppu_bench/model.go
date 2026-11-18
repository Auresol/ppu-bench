// The golden model of the render unit: spec/sprite-spec.md, rule by rule.
//
// It works from the same bytes the hardware gets, never from friendlier values: the 128 packed OAM entries (two 32-bit words
// each), the GIANT register and the texture SRAM image (palette at bytes 0..511, then the textures). So a mistake in the
// encoding shows up here as well as in the RTL.
package ppubench

import "fmt"

const (
	nSprites     = 128
	paletteBytes = 512
)

// sprite is one decoded OAM entry (spec section 2), with its size resolved (section 3).
type sprite struct {
	index, y, x, w, h, s            int // w, h: texture size; s: scale 1 or 2
	giant, enable, hflip, vflip, hb bool
	tex, pal, prio                  int
	bpp8                            bool
}

func field(w uint32, hi, lo int) int { return int((w >> lo) & (1<<(hi-lo+1) - 1)) }

func sext(v, bits int) int {
	if v&(1<<(bits-1)) != 0 {
		return v - 1<<bits
	}
	return v
}

func decodeGiant(giant uint32) (w, h, s int) {
	s = 1
	if field(giant, 20, 20) != 0 {
		s = 2
	}
	return field(giant, 9, 0), field(giant, 19, 10), s
}

func decodeSprite(i int, w0, w1, giant uint32) (sprite, error) {
	sp := sprite{
		index: i, y: sext(field(w0, 9, 0), 10), x: sext(field(w0, 20, 10), 11),
		giant: field(w0, 27, 27) != 0, enable: field(w0, 28, 28) != 0, hflip: field(w0, 29, 29) != 0,
		vflip: field(w0, 30, 30) != 0, hb: field(w0, 31, 31) != 0,
		tex: field(w1, 13, 0), pal: field(w1, 17, 14), bpp8: field(w1, 18, 18) != 0, prio: field(w1, 20, 19),
	}
	if sp.giant {
		sp.w, sp.h, sp.s = decodeGiant(giant)
		if sp.enable && (sp.w == 0 || sp.h == 0 || sp.w%8 != 0 || sp.h%8 != 0) {
			return sp, fmt.Errorf("sprite %d: giant with GIANT W=%d H=%d: must be non-zero multiples of 8 (section 4)", i, sp.w, sp.h)
		}
	} else {
		sp.w, sp.h, sp.s = (field(w0, 23, 21)+1)*8, (field(w0, 26, 24)+1)*8, 1
	}
	return sp, nil
}

// paletteEntry is entry n: 16 bits little endian at byte 2n, rgb444 in bits [11:0] (section 5).
func paletteEntry(tex []byte, n int) uint16 {
	return (uint16(tex[2*n]) | uint16(tex[2*n+1])<<8) & 0x0FFF
}

// texel is the colour index of texel (u, v) of sp (section 5, texture layout).
func texel(sp sprite, tex []byte, u, v int) int {
	base := sp.tex * 32
	if sp.bpp8 {
		return int(tex[base+v*sp.w+u])
	}
	b := tex[base+(v*sp.w+u)/2]
	if u&1 != 0 {
		return int(b>>4) & 15
	}
	return int(b) & 15
}

// load is what a frame asks of the hardware (not part of the picture).
type load struct {
	Sprites    int   `json:"sprites"`
	MaxDepth   int   `json:"max_depth"`
	DepthAt    []int `json:"max_depth_at"`
	MaxPerLine int   `json:"max_per_line"`
	LineAt     int   `json:"max_per_line_at"`
}

// golden is the right picture of a workload and its hit bits.
type golden struct {
	frame []uint16 // screenW x screenH rgb444
	hit   [4]uint32
	load  load
}

// render: oam is 256 words (sprite i = words 2i, 2i+1), giant the GIANT register, tex the texture SRAM image.
func render(oam [2 * nSprites]uint32, giant uint32, tex []byte) (golden, error) {
	var g golden
	if len(tex) < paletteBytes {
		return g, fmt.Errorf("the texture image is shorter than the palette")
	}
	var sprites []sprite
	for i := 0; i < nSprites; i++ {
		sp, err := decodeSprite(i, oam[2*i], oam[2*i+1], giant)
		if err != nil {
			return g, err
		}
		if !sp.enable {
			continue
		}
		bytes := sp.w * sp.h / 2
		if sp.bpp8 {
			bytes = sp.w * sp.h
		}
		if end := sp.tex*32 + bytes; end > len(tex) {
			return g, fmt.Errorf("sprite %d: texture ends at byte %d, past the texture SRAM (%d bytes)", sp.index, end, len(tex))
		}
		sprites = append(sprites, sp)
	}

	n := screenW * screenH
	g.frame = make([]uint16, n)
	front := make([]int, n) // (prio, index) of the opaque sprite in front so far, as prio*256+index; -1 none
	owner := make([]int, n) // one opaque hitbox sprite already seen at the pixel; -1 none
	depth := make([]int, n) // sprites whose rectangle covers the pixel, opaque or not
	perLine := make([]int, screenH)
	backdrop := paletteEntry(tex, 0)
	for i := range g.frame {
		g.frame[i], front[i], owner[i] = backdrop, -1, -1
	}
	var hits [nSprites]bool

	for _, sp := range sprites {
		x0, x1 := max(sp.x, 0), min(sp.x+sp.w*sp.s, screenW)
		y0, y1 := max(sp.y, 0), min(sp.y+sp.h*sp.s, screenH)
		palBase := sp.pal * 16
		if sp.bpp8 {
			palBase = 0
		}
		key := sp.prio*256 + sp.index
		for sy := y0; sy < y1; sy++ {
			v := (sy - sp.y) / sp.s
			if sp.vflip {
				v = sp.h - 1 - v
			}
			if x0 < x1 {
				perLine[sy]++
			}
			for sx := x0; sx < x1; sx++ {
				p := sy*screenW + sx
				depth[p]++
				u := (sx - sp.x) / sp.s
				if sp.hflip {
					u = sp.w - 1 - u
				}
				c := texel(sp, tex, u, v)
				if c == 0 {
					continue // transparent
				}
				if front[p] < 0 || key < front[p] {
					front[p] = key
					g.frame[p] = paletteEntry(tex, palBase+c)
				}
				if sp.hb {
					switch o := owner[p]; {
					case o < 0:
						owner[p] = sp.index
					case o != sp.index:
						hits[o], hits[sp.index] = true, true
					}
				}
			}
		}
	}
	for i, h := range hits {
		if h {
			g.hit[i/32] |= 1 << (i % 32)
		}
	}
	g.load = load{Sprites: len(sprites), DepthAt: []int{0, 0}}
	for p, d := range depth {
		if d > g.load.MaxDepth {
			g.load.MaxDepth, g.load.DepthAt = d, []int{p % screenW, p / screenW}
		}
	}
	for y, c := range perLine {
		if c > g.load.MaxPerLine {
			g.load.MaxPerLine, g.load.LineAt = c, y
		}
	}
	return g, nil
}
