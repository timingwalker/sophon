
RISCV_PREFIX ?= riscv64-unknown-elf

RISCV_GCC     := $(RISCV_PREFIX)-gcc
RISCV_OBJDUMP := $(RISCV_PREFIX)-objdump
RISCV_OBJCOPY := $(RISCV_PREFIX)-objcopy

ISA_SRC_DIR    := ./testcase/riscv-tests/isa
BMARKS_SRC_DIR := ./testcase/riscv-tests/benchmarks
PCL_SRC_DIR := ./testcase/pcl-tests


ifdef LDS_FILE
	RV_LDS_FILE := $(LDS_FILE)
	BM_LDS_FILE := $(LDS_FILE)
else
	RV_LDS_FILE := ./../env/p/link.ld
	BM_LDS_FILE := ./common/link.ld
endif

pcl-tests : clean_pcl-tests
	mkdir -p build/pcl-tests/
	$(MAKE) -C $(PCL_SRC_DIR) TC=gpio
	$(MAKE) -C $(PCL_SRC_DIR) TC=clic_shv
	$(MAKE) -C $(PCL_SRC_DIR) TC=clic_no_shv
	$(MAKE) -C $(PCL_SRC_DIR) TC=clic_no_shv_snapreg
	mv $(PCL_SRC_DIR)/build/* build/pcl-tests

rv32ui:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui lds_dir=$(RV_LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa/

rv32si:
	mkdir -p build/isa/
	$(MAKE) -C $(ISA_SRC_DIR) rv32si lds_dir=$(RV_LDS_FILE)
	mv $(ISA_SRC_DIR)/rv32si-* build/isa/


benchmarks:
	mkdir -p build/benchmarks/
	$(MAKE) -C $(BMARKS_SRC_DIR) all lds_dir=$(BM_LDS_FILE)
	mv $(BMARKS_SRC_DIR)/*.riscv* build/benchmarks/

isa:rv32ui rv32si


clean: clean_benchmarks clean_isa clean_pcl-tests

clean_benchmarks:
	[ ! -d build/benchmarks ]     || $(MAKE) -C $(BMARKS_SRC_DIR)  clean ; rm -rf ./build/benchmarks
	
clean_isa:
	[ ! -d build/isa ]    || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa

clean_pcl-tests:
	[ ! -d build/pcl-tests ]     || $(MAKE) -C $(PCL_SRC_DIR)  clean ; rm -rf ./build/pcl-tests

subfold=$(shell find * -maxdepth 0 -type d)
.PHONY: $(subfold)

echo:
	echo $(subfold)

