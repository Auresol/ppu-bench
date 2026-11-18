# The benchmark workloads: for each one, the golden frame (model/build.py) and the firmware that loads it (main.c).
#   make -C bench                 every workload
#   make -C bench WORKLOADS=x     one
#   make -C bench board           the program for the bitstream: board/$(BOARD).bin (default sprites_basic)
# Output: build/<workload>/{workload.h, expected.bin, expected.json, expected.png, tex.bin, app.elf}. The chip tests read them
# (hw-proj test run ppu_bench) and run this Makefile for their own workload first, so a fresh worktree (a job) works too.
#
# The firmware links the files hw-proj generates in version/base/fw (crt0.s, bsp_runtime.c, chip_ram.ld, soc.h), with
# the flags of its Makefile, so it follows system.yaml.

ROOT  := $(abspath ..)
FW    := $(ROOT)/version/base/fw
# The compiler: riscv32-none-elf-gcc on PATH, else the project's own (.toolchain/rv32imc_zicsr, the nix build of toolchain/flake.nix),
# built here when it is missing: a job's fresh worktree has no .toolchain link. flock: test cases build workloads in parallel.
TOOLCHAIN := $(ROOT)/.toolchain/rv32imc_zicsr
ifeq ($(origin CROSS),undefined)
  ifneq ($(shell command -v riscv32-none-elf-gcc),)
    CROSS := riscv32-none-elf-
  else
    CROSS := $(TOOLCHAIN)/bin/riscv32-none-elf-
    GCC_DEP := $(TOOLCHAIN)/bin/riscv32-none-elf-gcc
  endif
endif

WORKLOADS ?= $(shell python3 -I -c "import sys; sys.path.insert(0, '$(ROOT)/model'); from workloads import WORKLOADS; print(' '.join(WORKLOADS))")

CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -O2 -g -Wall -ffreestanding -I$(FW)
LDFLAGS = -nostdlib -nostartfiles -L$(FW) -T chip_ram.ld -Wl,--gc-sections -Wl,--no-warn-rwx-segments
MODEL   = $(wildcard $(ROOT)/model/*.py)

all: $(foreach w,$(WORKLOADS),build/$(w)/app.elf)

build/%/workload.h: $(MODEL)
	python3 -I $(ROOT)/model/build.py $* build/$*

$(TOOLCHAIN)/bin/riscv32-none-elf-gcc:
	cd $(ROOT) && flock .toolchain.lock sh -c 'test -x $@ || nix build path:./toolchain#rv32imc_zicsr --override-input nixpkgs nixpkgs -o .toolchain/rv32imc_zicsr'

build/%/app.elf: build/%/workload.h main.c $(FW)/crt0.s $(FW)/bsp_runtime.c $(FW)/chip_ram.ld $(FW)/soc.h | $(GCC_DEP)
	$(CROSS)gcc $(CFLAGS) -Ibuild/$* $(LDFLAGS) $(FW)/crt0.s $(FW)/bsp_runtime.c main.c -o $@ -lgcc
	@$(CROSS)size $@ | tail -1

# The program baked into the bitstream (vivado-job's FIRMWARE_MEM must be a file git tracks): board/<BOARD>.bin
BOARD ?= sprites_basic
board: build/$(BOARD)/app.elf
	@mkdir -p board
	$(CROSS)objcopy -O binary $< board/$(BOARD).bin
	@echo "board/$(BOARD).bin: $$(wc -c < board/$(BOARD).bin) bytes (FIRMWARE_MEM=bench/board/$(BOARD).bin vivado-job submit ...)"

clean:
	rm -rf build

.PHONY: all board clean
.PRECIOUS: build/%/workload.h
