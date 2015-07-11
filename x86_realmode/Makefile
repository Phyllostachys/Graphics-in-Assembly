all: build

build: pixel.nasm
	nasm -f bin -o pixel.bin -l pixel.lss pixel.nasm

clean:
	rm pixel.bin
	rm pixel.lss

qemu:
	qemu-system-i386 -boot a -fda pixel.bin
