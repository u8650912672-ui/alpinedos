.PHONY: all clean
all: init
init: init.o
	ld -static -o $@ $^
init.o: init.asm
	as -o $@ $<
clean:
	rm -f init init.o
