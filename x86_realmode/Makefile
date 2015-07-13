all: build

build: pixel.asm
	nasm -f bin -o pixel.bin -l pixel.lss pixel.asm

clean:
	rm pixel.bin
	rm pixel.lss

qemu: build
	qemu-system-i386 -boot a -fda pixel.bin

.PHONY: all build clean qemu
