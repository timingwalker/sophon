#=======================================================================
# Makefile for riscv-tests/isa
#-----------------------------------------------------------------------

XLEN ?= 32

src_dir := .
lds_dir := $(src_dir)/../env/p/link.ld

ifeq ($(XLEN),64)
include $(src_dir)/rv64ui/Makefrag
include $(src_dir)/rv64uc/Makefrag
include $(src_dir)/rv64um/Makefrag
include $(src_dir)/rv64ua/Makefrag
include $(src_dir)/rv64uf/Makefrag
include $(src_dir)/rv64ud/Makefrag
include $(src_dir)/rv64uzfh/Makefrag
include $(src_dir)/rv64si/Makefrag
include $(src_dir)/rv64ssvnapot/Makefrag
include $(src_dir)/rv64mi/Makefrag
endif
include $(src_dir)/rv32ui/Makefrag
include $(src_dir)/rv32uc/Makefrag
include $(src_dir)/rv32um/Makefrag
include $(src_dir)/rv32ua/Makefrag
include $(src_dir)/rv32uf/Makefrag
include $(src_dir)/rv32ud/Makefrag
include $(src_dir)/rv32uzfh/Makefrag
include $(src_dir)/rv32si/Makefrag
include $(src_dir)/rv32mi/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv64-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -ggdb -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= spike

RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy 
RISCV_OBJCOPY_OPTS ?= -O verilog

vpath %.S $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

%.hex: %
	$(RISCV_OBJCOPY) $< $(RISCV_OBJCOPY_OPTS)   $@
	sed -i 's/@800/@000/g' $@

%.out: %
	$(RISCV_SIM) --isa=rv64gc_zfh_svnapot $< 2> $@

%.out32: %
	$(RISCV_SIM) --isa=rv32gc_zfh_svnapot $< 2> $@

define compile_template

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(lds_dir) $$< -o $$@
$(1)_tests += $$($(1)_p_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))

$(1)_tests_hex  = $$(addsuffix .hex , $$($(1)_tests))


$(1): $$($(1)_tests_dump) $$($(1)_tests_hex)

.PHONY: $(1)

COMPILER_SUPPORTS_$(1) := $$(shell $$(RISCV_GCC) $(2) -c -x c /dev/null -o /dev/null 2> /dev/null; echo $$$$?)

ifeq ($$(COMPILER_SUPPORTS_$(1)),0)
tests += $$($(1)_tests)
endif

endef

$(eval $(call compile_template,rv32ui,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uc,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32um,-march=rv32g -mabi=ilp32))

$(eval $(call compile_template,rv32ua,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uf,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32ud,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32uzfh,-march=rv32g_zfh -mabi=ilp32))
$(eval $(call compile_template,rv32si,-march=rv32g -mabi=ilp32))
$(eval $(call compile_template,rv32mi,-march=rv32g -mabi=ilp32))
ifeq ($(XLEN),64)
$(eval $(call compile_template,rv64ui,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uc,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64um,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ua,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uf,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ud,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64uzfh,-march=rv64g_zfh -mabi=lp64))
$(eval $(call compile_template,rv64si,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64ssvnapot,-march=rv64g -mabi=lp64))
$(eval $(call compile_template,rv64mi,-march=rv64g -mabi=lp64))
endif

tests_dump = $(addsuffix .dump, $(tests))
tests_hex = $(addsuffix .hex, $(tests))
tests_out = $(addsuffix .out, $(filter rv64%,$(tests)))
tests32_out = $(addsuffix .out32, $(filter rv32%,$(tests)))

run: $(tests_out) $(tests32_out)

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)
