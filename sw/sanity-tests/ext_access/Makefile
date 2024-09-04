PROGRAM   ?= ext_access
LINKER    ?=../../../common/link.ld
BUILD_DIR ?=../build/sanity-tests/$(PROGRAM)
SW_DIR    ?=../sanity-tests/$(PROGRAM)

default:run

run:
	$(MAKE) -C ../../common NAME=$(PROGRAM) BUILD_DIR=$(BUILD_DIR) SW_DIR=$(SW_DIR) LINKER=$(LINKER)

clean:
	$(MAKE) -C ../../common NAME=$(PROGRAM) BUILD_DIR=$(BUILD_DIR) clean

