# ppu_bench

A hardware project made by `hw-proj init`. The chip is described in YAML under `version/base/doc/`; hw-proj checks it and writes the rest.

## What is here (yours to edit)

- `version/base/doc/system.yaml`: the chip, its clock and reset, the modules and the bus. Start here.
- `version/base/doc/<module>.yaml`: one spec per module that has hand-written parts.
- `version/base/fw/main.c` and `Makefile`: the first program (C) and how it is built; `make -C version/base/fw` makes `app.bin`.
- `version/base/rtl/soc/memory/sram_bank.sv`: the SRAM, 64kb, at address 0. The program is baked into it (`FIRMWARE_MEM`, below).
- `version/base/rtl/core/hazard3/`: the Hazard3 RISC-V core, a git submodule pinned at a release. Vendor code: do not edit.
- `version/base/doc/vga.yaml`: the VGA block, a 160x120 rgb444 picture in a RAM on the bus at 0x60000000 (4 bytes a pixel; pixel i at base + 4*i). `hw-proj gen all` writes `vga.sv`; `fw/soc.h` has `VGA0_WIDTH`, `VGA0_HEIGHT`, `VGA0_PIXEL(x, y)`.
  The 14 pins of the Basys3 VGA connector are a function of vga0 (`functions:` in `pinout.yaml`): they drive once FUNCSEL 1 is written into their CTRL registers, which the first program does.
- `frame/basys3/`: the board (Digilent's master xdc, the shell that makes the clock and reset) and `version/base/frame/basys3/wiring.yaml`, which pad goes to which board port.

## What hw-proj writes (do not edit)

`hw-proj gen all` writes the chip top `ppu_bench.sv`, the generated modules (gpio, the reset controller, the crossbar), the address package `ppu_bench_pkg.sv`, file lists, constraints and `fw/soc.h`.

With a CPU, gen also writes `version/base/fw/crt0.s`, `bsp_runtime.c` and the link scripts beside `main.c`. `hw-proj validate` warns that the chip has no boot program: that is right, this chip has no boot ROM; the program is baked into the SRAM.

## Next

```
hw-proj validate        # check the YAML and the RTL against it
hw-proj gen all         # write the generated files
hw-proj validate        # the generated files are now up to date
vivado-job bundle version/base/frame/basys3 --job synth --out /tmp/ppu_bench-bundle   # a bundle for Vivado
make -C version/base/fw   # build the firmware: app.elf and app.bin (needs the RISC-V gcc: the nix build command gen all prints)
make -C version/base/fw bake   # prints the vivado-job line that puts app.bin in the SRAM (FIRMWARE_MEM)
hw-doc                  # a web site of the project
```

The guide is in the hw-proj repository, `guide/README.md`.
