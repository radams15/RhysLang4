all: compile assemble_linux

compile:
	perl main.pl | tee out.nasm

assemble_dos:
	nasm -fbin out.nasm -o out.com

assemble_linux:
	nasm -felf64 out.nasm
	ld out.o -o out

run:
	./out
