PROGRAM   ?= $(CURRENT_DIR_NAME)

default:run

run:
	$(MAKE) -C ../common PROGRAM=$(PROGRAM)

clean:
	$(MAKE) -C ../common PROGRAM=$(PROGRAM) clean


CURRENT_DIR_NAME := $(notdir $(shell pwd))
test:
	@echo $(CURRENT_DIR_NAME)
