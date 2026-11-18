# The showcase programs (README in shooter.c and pendulum.c): make -C version/base/fw/showcase
# They run frame after frame (CTRL.CONT) from sram0, on libppu (../lib/ppu: ppu.h), linked with the files hw-proj
# generates one folder up (crt0.s, bsp_runtime.c, chip_ram.ld, soc.h). <name>.elf for the simulation (hw-link's program picker lists version/*/fw/**.elf),
# <name>.bin for the bitstream: FIRMWARE_MEM=version/base/fw/showcase/<name>.bin vivado-job submit ...
FW    := ..
CROSS ?= $(if $(wildcard ../../../../.toolchain/rv32imc_zicsr/bin/riscv32-none-elf-gcc),$(abspath ../../../../.toolchain/rv32imc_zicsr/bin)/,)riscv32-none-elf-
LIB     := ../lib/ppu
CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -O2 -g -Wall -Wextra -ffreestanding -I$(LIB) -I$(FW)
LDFLAGS = -nostdlib -nostartfiles -L$(FW) -T chip_ram.ld -Wl,--gc-sections -Wl,--no-warn-rwx-segments
PROGS   = shooter pendulum

all: $(PROGS:%=%.bin)

$(LIB)/libppu.a: FORCE
	$(MAKE) -C $(LIB)

%.elf: %.c $(LIB)/libppu.a $(LIB)/ppu.h $(FW)/crt0.s $(FW)/bsp_runtime.c $(FW)/chip_ram.ld $(FW)/soc.h
	$(CROSS)gcc $(CFLAGS) $(LDFLAGS) $(FW)/crt0.s $(FW)/bsp_runtime.c $< $(LIB)/libppu.a -o $@ -lgcc
	@$(CROSS)size $@ | tail -1

%.bin: %.elf
	$(CROSS)objcopy -O binary $< $@

clean:
	rm -f $(PROGS:%=%.elf)

.PHONY: all clean FORCE
.PRECIOUS: %.elf
