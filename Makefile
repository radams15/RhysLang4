all: compile assemble

compile:
	perl main.pl | tee out.nasm

assemble:
	nasm -felf64 out.nasm
	ld out.o -o out

run:
	./out
