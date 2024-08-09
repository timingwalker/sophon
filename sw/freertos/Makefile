PROGRAM ?= freertos
LINKER    ?=../../common/link.ld

default:run

run:
	$(MAKE) -C ../common NAME=$(PROGRAM) LINKER=$(LINKER)

clean:
	$(MAKE) -C ../common NAME=$(PROGRAM) clean

