# The benchmark firmware (bench.c): one program for every workload; the testbench writes the workload into it.
# Built by the testbench itself (test-suite/ppu_bench) until hw-proj builds programs of a chip that boots from RAM
# (handoff ram-boot-firmware-cases.md in hw-proj). The compiler: riscv32-none-elf-gcc on PATH, else the project's own
# (.toolchain, the nix build of toolchain/flake.nix), built here when missing (a job's fresh worktree has none).
ROOT      := $(abspath ../../../..)
FW        := ..
TOOLCHAIN := $(ROOT)/.toolchain/rv32imc_zicsr
ifeq ($(origin CROSS),undefined)
  ifneq ($(shell command -v riscv32-none-elf-gcc),)
    CROSS := riscv32-none-elf-
  else
    CROSS := $(TOOLCHAIN)/bin/riscv32-none-elf-
    GCC_DEP := $(TOOLCHAIN)/bin/riscv32-none-elf-gcc
  endif
endif
CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -O2 -g -Wall -ffreestanding -I$(FW)
LDFLAGS = -nostdlib -nostartfiles -L$(FW) -T chip_ram.ld -Wl,--gc-sections -Wl,--no-warn-rwx-segments

bench.elf: bench.c $(FW)/crt0.s $(FW)/bsp_runtime.c $(FW)/chip_ram.ld $(FW)/soc.h | $(GCC_DEP)
	$(CROSS)gcc $(CFLAGS) $(LDFLAGS) $(FW)/crt0.s $(FW)/bsp_runtime.c bench.c -o $@ -lgcc
	@$(CROSS)size $@ | tail -1

$(TOOLCHAIN)/bin/riscv32-none-elf-gcc:
	cd $(ROOT) && flock .toolchain.lock sh -c 'test -x $@ || nix build path:./toolchain#rv32imc_zicsr --override-input nixpkgs nixpkgs -o .toolchain/rv32imc_zicsr'

clean:
	rm -f bench.elf

.PHONY: clean
