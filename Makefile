all: assemble run

compile:
	go build
	./RhysLang < tests/hello.go

tcvm:
	c99 vm/tcvm.c -DDEBUG=1 -o tcvm

assemble:
	./casm.pl out.casm

run:
	./tcvm out.bin
