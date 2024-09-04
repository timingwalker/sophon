
RISCV_PREFIX   ?= riscv64-unknown-elf

RISCV_GCC      := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP  := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY  := $(RISCV_PREFIX)-objcopy

ISA_SRC_DIR    := ../vrf/riscv-tests/isa
BMARKS_SRC_DIR := ../vrf/riscv-tests/benchmarks
SANITY_SRC_DIR := ./sanity-tests
CM_SRC_DIR     := ./coremark

ifdef LDS_FILE
	RV_LDS_FILE  := $(LDS_FILE)
	BM_LDS_FILE  := $(LDS_FILE)
	SA_LDS_FILE  := $(LDS_FILE)
	APP_LDS_FILE := $(LDS_FILE)
else
	RV_LDS_FILE  := ./../env/p/link.ld
	BM_LDS_FILE  := ./common/link.ld
	SA_LDS_FILE  := ../../../common/link.ld
	APP_LDS_FILE := ../../common/link.ld
endif

# ------------------------------------------------
#  target
# ------------------------------------------------
fgpio_uart: clean_fgpio_uart
	cd fgpio_uart &&\
	make

FreeRTOS: clean_FreeRTOS
	cd FreeRTOS &&\
	make init &&\
	make LINKER=$(APP_LDS_FILE)

sanity-tests : clean_sanity-tests
	mkdir -p build/sanity-tests/
	$(MAKE) -C sanity-tests/clint         		LINKER=$(SA_LDS_FILE)
	$(MAKE) -C sanity-tests/ext_access 			LINKER=$(SA_LDS_FILE)
	$(MAKE) -C sanity-tests/fgpio      			LINKER=$(SA_LDS_FILE)
	$(MAKE) -C sanity-tests/clic          		LINKER=$(SA_LDS_FILE)
	$(MAKE) -C sanity-tests/exception     		LINKER=$(SA_LDS_FILE)

rv32ui:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui lds_dir=$(RV_LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa/

rv32si:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32si lds_dir=$(RV_LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32si-* build/isa/

isa:rv32ui rv32si

benchmarks:
	mkdir -p build/benchmarks/
	$(MAKE) -C $(BMARKS_SRC_DIR) all lds_dir=$(BM_LDS_FILE)
	mv $(BMARKS_SRC_DIR)/*.riscv* build/benchmarks/

coremark:
	mkdir -p build/coremark/
	cd $(CM_SRC_DIR) && $(MAKE) PORT_DIR=./sophon compile ITERATIONS=10
	mv $(CM_SRC_DIR)/coremark.elf build/coremark/coremark.riscv
	riscv64-unknown-elf-objdump -D build/coremark/coremark.riscv >> build/coremark/coremark.dump
	riscv64-unknown-elf-objcopy -O verilog build/coremark/coremark.riscv build/coremark/coremark.hex
	sed -i 's/@800/@000/g' build/coremark/coremark.hex


# ------------------------------------------------
#  clean
# ------------------------------------------------
clean: clean_benchmarks clean_isa clean_sanity-tests clean_coremark clean_fgpio_uart clean_FreeRTOS

clean_coremark:
	[ ! -d build/coremark ]     || rm -rf ./build/coremark

clean_fgpio_uart:
	[ ! -d build/fgpio_uart ]     || rm -rf ./build/fgpio_uart

clean_FreeRTOS:
	[ ! -d build/FreeRTOS ]     || rm -rf ./build/FreeRTOS

clean_benchmarks:
	[ ! -d build/benchmarks ]     || $(MAKE) -C $(BMARKS_SRC_DIR)  clean ; rm -rf ./build/benchmarks
	
clean_isa:
	[ ! -d build/isa ]    || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa

clean_sanity-tests:
	[ ! -d build/sanity-tests ]     || rm -rf ./build/sanity-tests

subfold=$(shell find * -maxdepth 0 -type d)
.PHONY: $(subfold)

echo:
	echo $(subfold)

