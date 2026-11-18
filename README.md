# ppu_bench: a frameless sprite renderer, benchmarked

A sprite renderer (a PPU, in the sense of the NES and the Game Boy Advance) with **no framebuffer**: every pixel is computed
just before the VGA beam reaches it, from a table of up to 128 sprites. It runs on a [Hazard3](https://github.com/Wren6991/Hazard3)
RISC-V SoC on a Digilent **Basys3** (Artix-7) at 50 MHz, 640×480 VGA at 60 Hz.

The point of the project is the benchmark: the same renderer in seven configurations (slot count, texture bus width), run on
a suite of workloads that each push one limit, checked pixel-exact against a golden model, then synthesised for the board.
Which limit hits first, what each step up costs in FPGA resources, and what it buys.

## The rules

- **No framebuffer.** No line buffer either: the renderer races the beam (a pixel every 2 clock cycles).
- **The renderer is a bus master.** It reads the sprite table over the main bus and textures over its own texture bus.
- **The CPU only writes sprite descriptions,** never pixels. Textures and the palette sit in a texture SRAM the CPU may write
  only before the renderer starts; after that the texture loader is locked in hardware.
- **VGA in stream mode:** the VGA unit holds no picture; it shows what the renderer outputs, 6 pixels of pipeline ahead.
- **Deterministic:** one frame per reset in the benchmark. A pixel the renderer cannot finish in time is drawn black and
  counted (the `LATE` register). Late means wrong: a configuration passes a workload only with zero late pixels and every
  pixel equal to the golden model.

## How the renderer works

The sprite format is our own, 64 bits per sprite (`spec/sprite-spec.md`): position, size 8 to 64 px, 4bpp or 8bpp, palette
bank, priority, flips, and a `hitbox` bit for pixel-exact collision (the renderer latches which hitbox sprites were drawn over
another sprite, per frame). The background is one scaled giant sprite.

For each line the renderer:

1. **Evaluates** the next line while the current one is on screen: reads all 128 entries, and files each sprite that touches
   the line into one of 40 bins (16-pixel columns, by left edge), as linked lists in a small RAM. A bucket sort into beam order.
2. **Admits** sprites into a small set of **slots** (8, 16 or 24) bin by bin, left to right. A slot frees as soon as the beam
   has passed its sprite, so 8 slots can draw ~96 sprites on one line. A pixel is drawn only when admission is past its bin
   (the frontier); sprites the beam has already passed are skipped.
3. **Fetches textures** into each slot's two-word buffer over the texture bus, most urgent first: the sprite under the beam,
   then the ones just ahead, then the next line's.
4. **Draws** each pixel: every slot checks whether it covers it, a priority tree picks the front opaque one, the palette gives
   the colour.

So three resources race the beam: **slots** (how many sprites stack on a pixel), **texture bandwidth** (how many texture
bits a pixel needs), and **admission** (how fast sprites can be loaded, ~9 cycles each). Unlike the NES, there is no fixed
cap of sprites per line; the cost is a scheduler where the NES has a fixed schedule.

## Results

Seven versions, all at 50 MHz on the Basys3, post-route (Vivado):

| Version | Slots | Tex bus | LUTs | FFs | WNS | Max stack, 4bpp 32×32 | Max stack, 8bpp 64×64 | Random scenes perfect |
|---|---|---|---|---|---|---|---|---|
| base | 8 | 32 | 8,436 (41%) | 8,715 (21%) | +2.39 ns | 4 | 0 | 0 of 16 ¹ |
| slots16 | 16 | 32 | 11,213 (54%) | 11,316 (27%) | +1.88 ns | 4 | 0 | 5 of 256 |
| slots24 | 24 | 32 | 13,894 (67%) | 13,945 (34%) | +1.03 ns | 4 | 0 | 5 of 256 |
| tex64 | 8 | 64 | 9,901 (48%) | 9,249 (22%) | +1.18 ns | 8 | 2 | 255 of 256 |
| tex128 | 8 | 128 | 9,613 (46%) | 10,262 (25%) | +0.86 ns | 8 | 6 | 256 of 256 |
| slots24-tex64 | 24 | 64 | 15,622 (75%) | 15,512 (37%) | +1.22 ns | 24 | 2 | 255 of 256 |
| slots24-tex128 | 24 | 128 | 16,096 (77%) | 18,478 (44%) | +0.11 ns | 24 | 10 | 256 of 256 |

Block RAM is 34.5 of 50 tiles (69%) in every version. ¹ The 256-seed run of base was not finished when this was written.

- **At 50 MHz, texture bandwidth decides.** A 32-bit texture bus streams ~21 bits a pixel, a 64-bit one ~43, a 128-bit one
  ~85. On random scenes (16 to 127 sprites anywhere, at most 6 deep) every 32-bit version fails almost every scene; 64 bits
  fail one in 256; 128 bits none.
- **Width is cheap, slots are expensive.** 64 bits cost +17% LUTs; each slot costs ~340 LUTs and ~330 flip-flops, and 24 slots
  on a 32-bit bus change nothing on ordinary scenes. Slots pay off only for deep stacks.
- **Admission is a third limit.** 8×8 sprites spread along one line: 8 slots keep up to 64 per line, 24 slots to 96; at 120
  even the largest version falls behind, with the main bus only ~17% busy. The fix would be a faster admission path, not
  more slots or bandwidth.
- **The top configuration is at the edge:** 77% of the LUTs, +0.11 ns of slack.

## The test suite

The tests are declared in `version/base/doc/system.yaml` and written in Go in `version/base/test-suite/ppu_bench/`
(`workloads.go`, the golden model in `model.go`). Each case builds a workload and its golden frame, loads the benchmark
firmware (`version/base/fw/bench`) with the workload, resets the chip, captures one frame from the VGA pins and compares it
pixel by pixel; `LATE` and the hit bits too. Performance counters in the renderer (texture and main bus busy, slots peak,
admission slack, …) become metrics.

| Category | Cases | What they push |
|---|---|---|
| frame | `empty_black`, `sprites_basic` | correctness: the control case; background, 4/8bpp overlap, flips, edges, hitboxes |
| stress | `sparse`, `line_storm`, `stack_7`, `stack_16`, `bandwidth_8bpp`, `busy_screen`, `pile_96` | one load each: sprites per line, depth, bandwidth, all 128 sprites, 96 sprites on one spot |
| bench | `depth_4` … `depth_24` | slots: 4 to 24 deep |
| bench | `bw_2` … `bw_10` | texture bandwidth: 2 to 10 overlapping 64×64 8bpp sprites |
| bench | `admit_32` … `admit_120` | admission rate: 8×8 sprites along one line |
| random | `random_scene` (256 seeds) | a random scene per seed: 16–127 sprites of every kind anywhere on the screen |

A failure in stress or bench is a result of the benchmark (a deadline the configuration misses), not a broken test.

## Firmware

- `version/base/fw/bench/`: the benchmark program, one frame with nothing else.
- `version/base/fw/lib/ppu/`: **libppu**, a small library for programs that animate the renderer frame after frame: palette
  and texture loading, a double-buffered sprite table, the frame loop, text, fixed-point math, buttons and LEDs.
- `version/base/fw/showcase/`: three demos on libppu: `shooter` (a 2D space shooter, buttons), `pendulum` (a double
  pendulum), `boids` (a flock). The prebuilt `.bin` files are tracked.

## Layout

```
spec/sprite-spec.md          the sprite format, registers and frame rule: the contract between firmware and renderer
version/base/doc/            the chip in YAML: system.yaml (instances, buses, tests) and one spec per module
version/base/rtl/soc/        the RTL; peripheral/ppu.sv is the renderer, racer.sv the VGA output, texld.sv the texture loader
version/base/rtl/core/hazard3  the CPU (git submodule)
version/base/test-suite/     the Go testbench: workloads, golden model, random scenes
version/base/fw/             firmware: bench, libppu, showcases
version/<name>/              the other six versions: generated overrides of the base (tools/versions.py)
frame/basys3/                the board: pins, clock (MMCM, 50 MHz), reset
vivado/job/                  Vivado recipes: synth, bit
toolchain/flake.nix          the RISC-V cross compiler (nix)
bench/screen.yaml            a live view of the VGA pins in simulation (hw-link)
```

## Building

The project is built with **hw-proj**, a YAML-driven hardware project tool: the YAML under `version/base/doc/` is the source
of truth, and `hw-proj gen all` writes the chip top, buses, crossbar, register headers (`fw/soc.h`), file lists and the
testbench scaffolding. The generated files are committed, so the RTL can also be used without it.

```sh
git clone --recursive <this repo>          # Hazard3 is a submodule

# the cross compiler (nix), into a git-ignored folder
nix build path:./toolchain#rv32imc_zicsr --override-input nixpkgs nixpkgs -o .toolchain/rv32imc_zicsr

# firmware
make -C version/base/fw/bench               # the benchmark program
make -C version/base/fw/showcase            # shooter.bin, pendulum.bin, boids.bin

# with hw-proj
hw-proj validate && hw-proj gen all
hw-proj test run ppu_bench                  # the whole suite on the base (Verilator)
hw-proj test run ppu_bench --run 'random_scene#39'   # replay one random scene

# lint without hw-proj
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-MULTITOP -f version/base/filelist.f --top-module ppu_bench
```

For the board, the firmware is baked into the SRAM's initial contents at synthesis (`FIRMWARE_MEM=<program>.bin`); the
Vivado sources are `version/<name>/frame/basys3/filelist.f` with `frame/basys3/` (pins, clock).

## Credits

- [Hazard3](https://github.com/Wren6991/Hazard3) by Luke Wren, the RISC-V core (Apache 2.0), as a submodule.
- Board files after Digilent's Basys3 master XDC.
