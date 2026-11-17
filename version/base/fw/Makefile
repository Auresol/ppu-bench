# Builds the firmware of ppu_bench: app.elf and app.bin. `make` builds, `make bake` says how to put app.bin in the chip.
# The generated files beside this one (soc.h, crt0.s, bsp_runtime.c, chip_ram.ld) are written by `hw-proj gen`; main.c is yours.
# The compiler is the one built from the project (.toolchain/rv32imc_zicsr, the command `hw-proj gen` prints) when it is there, else riscv32-none-elf- on the PATH.
CROSS ?= $(if $(wildcard ../../../.toolchain/rv32imc_zicsr/bin/riscv32-none-elf-gcc),$(abspath ../../../.toolchain/rv32imc_zicsr/bin)/,)riscv32-none-elf-

# the core's isa, derived by hw-proj from its parameters (hw-proj gen toolchain prints it): rv32imc_zicsr
MARCH = rv32imc_zicsr
MABI  = ilp32

# chip_ram.ld: the program runs from RAM and is loaded from outside, so crt0 copies nothing. Address 0 is the first byte of
# app.bin, and the core starts there (RESET_VECTOR = 0).
CFLAGS  = -march=$(MARCH) -mabi=$(MABI) -Os -g -Wall -ffreestanding -I.
LDFLAGS = -nostdlib -nostartfiles -L. -T chip_ram.ld -Wl,--gc-sections -Wl,--no-warn-rwx-segments

# After the objects, as `hw-proj test build` links its cases (guide/firmware.md): gcc calls libgcc by itself for a 64-bit divide or
# a soft multiply on a core without M. For a C library (memcpy, printf) set libc: in doc/firmware.yaml and add the library's link
# words here (newlib-nano: --specs=nano.specs -lc, before -lgcc).
LDLIBS = -lgcc

all: app.bin

app.elf: crt0.s bsp_runtime.c main.c soc.h chip_ram.ld
	$(CROSS)gcc $(CFLAGS) $(LDFLAGS) crt0.s bsp_runtime.c main.c -o $@ $(LDLIBS)

app.bin: app.elf
	$(CROSS)objcopy -O binary $< $@
	@echo "app.bin: $$(wc -c < $@) bytes"

# The program goes into the chip's SRAM when the bitstream is made: vivado-job fills the SRAM from FIRMWARE_MEM.
bake: app.bin
	@echo "cd $(abspath ../../../) && FIRMWARE_MEM=$(abspath app.bin) vivado-job bundle version/base/frame/basys3 --job bit --out /tmp/ppu_bench-bundle"

clean:
	rm -f app.elf app.bin

.PHONY: all bake clean
