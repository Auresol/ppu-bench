// The random scene (test random/random_scene, seeds: in system.yaml): each seed draws a whole frame of sprites placed
// anywhere on the screen, and the case checks it like any workload (golden frame, LATE, HIT). Across the seeds and the chip
// versions it says how often a configuration copes with an arbitrary scene, not just with one stressed limit.
//
// The sprite count and a layout seed are drawn with Pick (recorded: a failing seed's report says them, and
// hw-proj test run ppu_bench --run 'random_scene#<i>' replays it); the layout comes from the layout seed.
package ppubench

import (
	"fmt"

	"ppu_bench/test-suite/ppu_bench/gen"
)

func (t *T) RandomScene(u *gen.PpuBench) {
	n := u.Sim.Pick("sprites", 16, 127)
	seed := u.Sim.Pick("layout_seed", 1, 1<<30)
	wl := randomScene(n, uint32(seed))
	runFrame(u, wl, fmt.Sprintf("random_scene_%d", seed))
}

// randomScene: n sprites of random kinds, places, palettes, priorities, flips and hitboxes over the background.
func randomScene(n int, seed uint32) *workload {
	wl := newWorkload(fmt.Sprintf("random_%d", seed), fmt.Sprintf("%d random sprites over the background (layout seed %d)", n, seed))
	stdPalette(wl)
	bgTex := background(wl)
	kinds := []texture{
		wl.texture(8, 8, false, func(u, v int) int { return 1 + (u+v)%3 }),
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
	r := xorshift(seed)
	for i := 0; i < n; i++ {
		t := kinds[r.n(len(kinds))]
		wl.sprite(t, r.n(640+t.w)-t.w/2, r.n(480+t.h)-t.h/2, spr{pal: 1 + r.n(3), prio: r.n(3),
			hflip: r.n(2) == 0, vflip: r.n(2) == 0, hitbox: r.n(4) == 0})
	}
	bg(wl, bgTex)
	return wl
}
