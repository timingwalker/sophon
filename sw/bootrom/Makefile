
RISCV_PREFIX   ?= riscv64-unknown-elf

RISCV_GCC      := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP  := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY  := $(RISCV_PREFIX)-objcopy

MARCH         ?= rv32ia
MABI          ?= ilp32
LDS_FILE      ?= link_bootrom.ld
SW_SIMPLE_CRT ?= YES
SW_RVE        ?= NO
SW_ZICSR      ?= YES

# ----------------------------------------------------------------------
#  bootrom
# ----------------------------------------------------------------------
COM_SRC = "./uart.c"

bootrom: to_sv
	cp ../build/bootrom/boot_code.sv ../../design/sophon/

sw: 
	$(MAKE) -C ../common PROGRAM=bootrom COM_SRC=$(COM_SRC) MARCH=$(MARCH) MABI=$(MABI) LDS_FILE=$(LDS_FILE) SW_SIMPLE_CRT=$(SW_SIMPLE_CRT) SW_RVE=$(SW_RVE) SW_ZICSR=$(SW_ZICSR)

to_sv: sw
	python hex_to_sv.py ../build/bootrom/bootrom.hex ../build/bootrom/boot_code.sv -n mem -d 512

clean: 
	rm -rf ../build/bootrom

.PHONY: bootrom clean

