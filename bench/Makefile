# The benchmark workloads: for each one, the golden frame (model/build.py) and the firmware that loads it (main.c).
#   make -C bench                 every workload
#   make -C bench WORKLOADS=x     one
# Output: build/<workload>/{workload.h, expected.bin, expected.json, expected.png, app.elf}. The chip tests read them
# (hw-proj test run ppu_bench); build them first.
#
# The firmware links the files hw-proj generates in version/base/fw (crt0.s, bsp_runtime.c, chip_ram.ld, soc.h), with
# the flags of its Makefile, so it follows system.yaml.

ROOT  := $(abspath ..)
FW    := $(ROOT)/version/base/fw
CROSS ?= $(if $(wildcard $(ROOT)/.toolchain/rv32imc_zicsr/bin/riscv32-none-elf-gcc),$(ROOT)/.toolchain/rv32imc_zicsr/bin/,)riscv32-none-elf-

WORKLOADS ?= $(shell python3 -I -c "import sys; sys.path.insert(0, '$(ROOT)/model'); from workloads import WORKLOADS; print(' '.join(WORKLOADS))")

CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -O2 -g -Wall -ffreestanding -I$(FW)
LDFLAGS = -nostdlib -nostartfiles -L$(FW) -T chip_ram.ld -Wl,--gc-sections -Wl,--no-warn-rwx-segments
MODEL   = $(wildcard $(ROOT)/model/*.py)

all: $(foreach w,$(WORKLOADS),build/$(w)/app.elf)

build/%/workload.h: $(MODEL)
	python3 -I $(ROOT)/model/build.py $* build/$*

build/%/app.elf: build/%/workload.h main.c $(FW)/crt0.s $(FW)/bsp_runtime.c $(FW)/chip_ram.ld $(FW)/soc.h
	$(CROSS)gcc $(CFLAGS) -Ibuild/$* $(LDFLAGS) $(FW)/crt0.s $(FW)/bsp_runtime.c main.c -o $@ -lgcc
	@$(CROSS)size $@ | tail -1

clean:
	rm -rf build

.PHONY: all clean
.PRECIOUS: build/%/workload.h
