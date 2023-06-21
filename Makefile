OS?=LINUX
ARCH?=x86_64

dos:
	OS=DOS ARCH=x86_16 make compile assemble_dos

linux:
	OS=LINUX ARCH=x86_64 make compile assemble_elf
	
mac:
	OS=DARWIN ARCH=x86_64 make compile assemble_mach


all: compile assemble_linux

compile:
	perl preprocess.pl -d ${OS}=1 -d ${ARCH}=1 in.rl | perl main.pl --os ${OS} --arch ${ARCH} | tee out.nasm

assemble_dos:
	nasm -fbin out.nasm -o out.com

assemble_elf:
	nasm -felf64 -g out.nasm
	ld out.o -o out
	
assemble_mach:
	nasm -fmacho64 -g out.nasm
	ld out.o -o out -e _start
	
run:
	./out

rundos:
	flatpak run com.dosbox_x.DOSBox-X -set cputype=286 ./out.com
