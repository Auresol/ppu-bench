// The chip tests of ppu_bench: one frame per reset (spec/sprite-spec.md section 8).
//
// Each case loads bench/build/<workload>/app.elf into sram0 through the backdoor (the program runs from RAM: there is no
// flash and no boot ROM, so hw-proj's firmware: cases do not apply), resets the chip, captures the picture from the VGA
// pins, finds the frame the render unit drew and compares it pixel by pixel with the golden model's (model/build.py),
// then checks LATE and the hit bits the firmware read back. Build the workloads first: make -C bench.
//
// The capture holds a frame in the testbench, never in the chip: the chip streams each pixel once on its pins.
package ppubench

import (
	"debug/elf"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"os"
	"path/filepath"
	"strings"

	"ppu_bench/test-suite/hwproj-tb"
	"ppu_bench/test-suite/ppu_bench/gen"
)

// T is the test set; every declared test is one workload.
type T struct{ gen.PpuBenchDefaults }

// Tests is what main runs.
var Tests = &T{}

func (t *T) EmptyBlack(u *gen.PpuBench)   { oneFrame(u, "empty_black") }
func (t *T) SpritesBasic(u *gen.PpuBench) { oneFrame(u, "sprites_basic") }

// stress: one limit each (model/workloads.py); a failure is a deadline the configuration misses
func (t *T) Sparse(u *gen.PpuBench)        { oneFrame(u, "sparse") }
func (t *T) LineStorm(u *gen.PpuBench)     { oneFrame(u, "line_storm") }
func (t *T) Stack7(u *gen.PpuBench)        { oneFrame(u, "stack_7") }
func (t *T) Stack16(u *gen.PpuBench)       { oneFrame(u, "stack_16") }
func (t *T) Bandwidth8bpp(u *gen.PpuBench) { oneFrame(u, "bandwidth_8bpp") }
func (t *T) BusyScreen(u *gen.PpuBench)    { oneFrame(u, "busy_screen") }

// The raster of the stream VGA block (guide/vga.md): 640x480@60 in 800 x 525, 4 chip cycles a pixel at 100 MHz.
const (
	screenW, screenH = 640, 480
	lineCols         = 800
	frameLines       = 525
	cyclesPerPixel   = 4
	lineCycles       = lineCols * cyclesPerPixel
	hsyncCol         = 656 // hsync is low in columns 656..751
	vsyncLine        = 490 // vsync is low in lines 490 and 491
	maxFrames        = 4   // frames to wait for DONE before giving up
	bspCrashAddr     = 0xFFD0 // BSP_CRASH_ADDR of fw/soc.h
)

// The VGA pins on the pad bundle (pinout.yaml: functions of ppu0): rgb on pads 48..59 (bit 0 first), hsync 60, vsync 61.
const (
	padRGB   = 48
	padHsync = 60
	padVsync = 61
)

type pins struct{ u *gen.PpuBench }

func (p pins) rgb() uint16 { return uint16(p.u.PadOut.Get()>>padRGB) & 0xFFF }
func (p pins) hs() uint64  { return p.u.PadOut.Get() >> padHsync & 1 }
func (p pins) vs() uint64  { return p.u.PadOut.Get() >> padVsync & 1 }

// expected is model/build.py's output for one workload.
type expected struct {
	Workload string   `json:"workload"`
	Hit      []uint32 `json:"hit"`
	Sprites  []int    `json:"hit_sprites"`
	Load     struct {
		Sprites    int   `json:"sprites"`
		MaxDepth   int   `json:"max_depth"`
		DepthAt    []int `json:"max_depth_at"`
		MaxPerLine int   `json:"max_per_line"`
		LineAt     int   `json:"max_per_line_at"`
	} `json:"load"`
	frame    []uint16
}

// result is struct bench_result of bench/main.c, read through the backdoor.
type result struct {
	late, done uint32
	hit        [4]uint32
}

func oneFrame(u *gen.PpuBench, workload string) {
	s := u.Sim
	dir := filepath.Join(repoRoot(s), "bench", "build", workload)
	elfPath := filepath.Join(dir, "app.elf")
	if _, err := os.Stat(elfPath); err != nil {
		s.Fatalf("%s: no %s: build the workloads first (make -C bench)", workload, elfPath)
	}
	want := loadExpected(s, dir)

	// the program into sram0, then a reset: Hazard3 starts at 0, where the program now is
	sram, err := u.Mem("sram0")
	if err != nil {
		s.Fatalf("%v", err)
	}
	if _, err := tb.LoadELF(elfPath, []tb.Region{{Base: 0, Mem: sram}}); err != nil {
		s.Fatalf("load %s: %v", elfPath, err)
	}
	resAddr := symbol(s, elfPath, "bench_result")
	readResult := func() result {
		w := func(off uint64) uint32 { return uint32(sram.Read(int((resAddr + off) / 4))) }
		return result{late: w(0), hit: [4]uint32{w(4), w(8), w(12), w(16)}, done: w(20)}
	}
	u.Reset()

	got, res := capture(u, readResult)

	// the textures went through the loader into tex0 (bus tex) intact
	checkTextures(u, dir)

	// the picture
	bad := 0
	var first []string
	for i := range got {
		if got[i] != want.frame[i] {
			if bad < 8 {
				first = append(first, fmt.Sprintf("(%d,%d) got %03x want %03x", i%screenW, i/screenW, got[i], want.frame[i]))
			}
			bad++
		}
	}
	gotPNG := filepath.Join(dir, "got.png")
	writePNG(s, gotPNG, got)
	u.Metric("frame_bad_pixels", int64(bad))
	u.Metric("late_pixels", int64(res.late))
	l := want.Load
	s.Logf("%s: %d of %d pixels wrong, LATE %d; load: %d sprites, %d deep at %v, %d on line %d; captured frame in %s",
		workload, bad, len(got), res.late, l.Sprites, l.MaxDepth, l.DepthAt, l.MaxPerLine, l.LineAt, gotPNG)
	u.Metric("load_max_depth", int64(l.MaxDepth))
	u.Metric("load_max_per_line", int64(l.MaxPerLine))
	if bad > 0 {
		s.Errorf("frame: %d pixels differ from the golden model; first: %v (see %s and expected.png)", bad, first, gotPNG)
	}
	// late pixels make the run wrong even when the picture happens to match (section 8)
	if res.late != 0 {
		s.Errorf("LATE = %d: pixels were not ready in time", res.late)
	}
	// hit bits (section 7)
	for n := 0; n < 4; n++ {
		if res.hit[n] != want.Hit[n] {
			s.Errorf("HIT%d = %08x, want %08x (sprites hit: %v)", n, res.hit[n], want.Hit[n], want.Sprites)
		}
	}
}

// capture locks onto the raster from the sync pins, then records every frame from the pins until the firmware says the
// render unit is done, and returns the last whole frame: the one the render unit drew. DONE rises as the lead side leaves
// line 479, so it is seen in the vertical blanking that follows that frame, long before the next one starts.
func capture(u *gen.PpuBench, readResult func() result) ([]uint16, result) {
	s := u.Sim
	p := pins{u}

	// 1. the column: the first cycle hsync is low is the first cycle of column 656. The pins drive once the firmware selects
	//    them (FUNCSEL), so wait for a real falling edge, not the pad's level before that.
	prev := p.hs()
	if !u.RunUntil(func() bool { now := p.hs(); fell := prev == 1 && now == 0; prev = now; return fell }, 4*frameLines*lineCycles) {
		s.Fatalf("no hsync edge on pad %d: the VGA pins never drove (is FUNCSEL of ppu0 selected?); %s", padHsync, where(u, readResult))
	}
	// 2. the line: step whole lines, sampling at column 656, until vsync falls (line 490)
	sawHigh := false
	for line := 0; ; line++ {
		if line > 2*frameLines {
			s.Fatalf("no vsync on pad %d in two frames", padVsync)
		}
		if p.hs() != 0 {
			s.Fatalf("lost the raster: hsync is not low at column %d (cycle %d)", hsyncCol, s.Cycle())
		}
		if v := p.vs(); v == 1 {
			sawHigh = true
		} else if sawHigh {
			break
		}
		u.Run(lineCycles)
	}
	// now: column 656 of line 490. Go to the middle of pixel (0, 0) of the next frame.
	u.Run(uint64((frameLines-vsyncLine)*lineCycles - hsyncCol*cyclesPerPixel + cyclesPerPixel/2))

	frame := make([]uint16, screenW*screenH)
	for f := 0; f < maxFrames; f++ {
		for y := 0; y < screenH; y++ {
			row := frame[y*screenW : (y+1)*screenW]
			for x := range row {
				row[x] = p.rgb()
				u.Run(cyclesPerPixel)
			}
			// in the blanking: check the raster is still where we think, then on to the next line
			u.Run(uint64(700-screenW) * cyclesPerPixel)
			if p.hs() != 0 {
				s.Fatalf("lost the raster: hsync is not low at column 700 of line %d (cycle %d)", y, s.Cycle())
			}
			u.Run(uint64(lineCols-700) * cyclesPerPixel)
		}
		// line 480: run into the blanking and ask the firmware
		u.Run(20 * lineCycles)
		if r := readResult(); r.done == 1 {
			return frame, r
		}
		u.Run(uint64(frameLines-screenH-20) * lineCycles)
	}
	s.Fatalf("the render unit was not DONE after %d frames (STATUS.DONE never seen by the firmware)", maxFrames)
	return nil, result{}
}

// where says how far the program got, for a failure message: the core's fetch address and what bench_result holds.
func where(u *gen.PpuBench, readResult func() result) string {
	fetch := "?"
	if n, err := u.Net("core0", "i_haddr"); err == nil {
		a := n.Out().Get()
		fetch = fmt.Sprintf("0x%08x (%s)", a, u.AddrName(a))
	}
	r := readResult()
	msg := fmt.Sprintf("core0 fetching at %s; bench_result.done %d", fetch, r.done)
	// the crash record of the runtime (fw/soc.h: struct bsp_crash at BSP_CRASH_ADDR): magic, cause, pc, sp, mcause
	if sram, err := u.Mem("sram0"); err == nil {
		w := func(i int) uint32 { return uint32(sram.Read(bspCrashAddr/4 + i)) }
		if w(0) != 0 {
			msg += fmt.Sprintf("; crash record: magic %08x cause %d pc 0x%x sp 0x%x mcause 0x%x", w(0), w(1), w(2), w(3), w(4))
		}
	}
	return msg
}

// checkTextures compares tex0, read through the backdoor, with the image the firmware loaded (tex.bin of model/build.py).
func checkTextures(u *gen.PpuBench, dir string) {
	s := u.Sim
	want, err := os.ReadFile(filepath.Join(dir, "tex.bin"))
	if err != nil {
		s.Fatalf("%v (make -C bench)", err)
	}
	tex0, err := u.Mem("tex0")
	if err != nil && strings.Contains(err.Error(), "backdoor not supported") {
		// the backdoor reads words of up to 64 bits (a 128-bit bus tex is wider): the frame check still covers the textures
		s.Logf("tex0 not checked: %v", err)
		return
	}
	if err != nil {
		s.Fatalf("%v", err)
	}
	got, err := tex0.Dump(0, len(want))
	if err != nil {
		s.Fatalf("tex0: %v", err)
	}
	for i := range want {
		if got[i] != want[i] {
			s.Errorf("tex0 byte 0x%x = %02x, want %02x: the texture loader did not write the image intact", i, got[i], want[i])
			return
		}
	}
}

func loadExpected(s *tb.Sim, dir string) expected {
	var e expected
	b, err := os.ReadFile(filepath.Join(dir, "expected.json"))
	if err != nil {
		s.Fatalf("%v (make -C bench)", err)
	}
	if err := json.Unmarshal(b, &e); err != nil || len(e.Hit) != 4 {
		s.Fatalf("expected.json of %s: %v", dir, err)
	}
	raw, err := os.ReadFile(filepath.Join(dir, "expected.bin"))
	if err != nil || len(raw) != 2*screenW*screenH {
		s.Fatalf("expected.bin of %s: %d bytes, %v", dir, len(raw), err)
	}
	e.frame = make([]uint16, screenW*screenH)
	for i := range e.frame {
		e.frame[i] = binary.LittleEndian.Uint16(raw[2*i:])
	}
	return e
}

func symbol(s *tb.Sim, path, name string) uint64 {
	f, err := elf.Open(path)
	if err != nil {
		s.Fatalf("%v", err)
	}
	defer f.Close()
	syms, err := f.Symbols()
	if err != nil {
		s.Fatalf("%s: %v", path, err)
	}
	for _, sym := range syms {
		if sym.Name == name {
			return sym.Value
		}
	}
	s.Fatalf("no symbol %s in %s", name, path)
	return 0
}

func writePNG(s *tb.Sim, path string, frame []uint16) {
	img := image.NewRGBA(image.Rect(0, 0, screenW, screenH))
	for i, c := range frame {
		img.Set(i%screenW, i/screenW, color.RGBA{uint8(c>>8&15) * 17, uint8(c>>4&15) * 17, uint8(c&15) * 17, 255})
	}
	f, err := os.Create(path)
	if err != nil {
		s.Errorf("%v", err)
		return
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		s.Errorf("%s: %v", path, err)
	}
}

// repoRoot is the nearest folder upward from where the test runs that holds version/base/doc/system.yaml.
func repoRoot(s *tb.Sim) string {
	dir, _ := os.Getwd()
	for d := dir; ; d = filepath.Dir(d) {
		if _, err := os.Stat(filepath.Join(d, "version", "base", "doc", "system.yaml")); err == nil {
			return d
		}
		if filepath.Dir(d) == d {
			s.Fatalf("no repo root (version/base/doc/system.yaml) above %s", dir)
		}
	}
}
