RISCV_PREFIX  ?= riscv64-unknown-elf

RISCV_GCC     := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY := $(RISCV_PREFIX)-objcopy
CC            := $(RISCV_GCC)
SED           ?= $(shell if sed --version >/dev/null 2>&1; then echo sed; elif command -v gsed >/dev/null 2>&1; then echo gsed; else echo sed; fi)

MABI          ?= ilp32
MARCH_BASE    ?= rv32ia
SW_ZICSR      ?= YES

ifeq ($(SW_ZICSR), YES)
MARCH         ?= $(shell printf '' | $(RISCV_GCC) -march=$(MARCH_BASE)_zicsr -mabi=$(MABI) -x c -c -o /dev/null - >/dev/null 2>&1 && echo $(MARCH_BASE)_zicsr || echo $(MARCH_BASE))
else
MARCH         ?= $(MARCH_BASE)
endif
