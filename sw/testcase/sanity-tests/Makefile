
TC ?= gpio

default: all

init:
	test -d build/$(TC) || mkdir -p ./build/$(TC)

cp : init
	cp ./$(TC)/* ./build/$(TC)/
	cp ./lib/* ./build/$(TC)/

all : cp
	$(MAKE) -C ./build/$(TC) TC=$(TC) FILENAME=$(TC)

clean:
	rm ./build -rf


.PHONY: cp init
