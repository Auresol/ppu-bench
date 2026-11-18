# libppu (ppu.h): make -C version/base/fw/lib/ppu -> libppu.a. Programs link it with -I<this folder> and libppu.a.
# The compiler: riscv32-none-elf-gcc on PATH, else the project's .toolchain (the nix build of toolchain/flake.nix).
ROOT  := $(abspath ../../../../..)
FW    := ../..
CROSS ?= $(if $(wildcard $(ROOT)/.toolchain/rv32imc_zicsr/bin/riscv32-none-elf-gcc),$(ROOT)/.toolchain/rv32imc_zicsr/bin/,)riscv32-none-elf-
CFLAGS = -march=rv32imc_zicsr -mabi=ilp32 -O2 -g -Wall -Wextra -ffreestanding -ffunction-sections -fdata-sections -I. -I$(FW)
OBJS   = ppu_core.o ppu_text.o ppu_math.o ppu_io.o

libppu.a: $(OBJS)
	rm -f $@
	$(CROSS)ar rcs $@ $^

%.o: %.c ppu.h $(FW)/soc.h
	$(CROSS)gcc $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) libppu.a

.PHONY: clean
