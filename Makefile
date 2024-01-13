all: assemble run

compile:
	go build
	./RhysLang < tests/hello.go > out.casm

tcvm:
	c99 -I vm vm/tcvm.c vm/builtins.c -DDEBUG=1 -o tcvm

assemble:
	./casm.pl out.casm

run:
	./tcvm out.bin
