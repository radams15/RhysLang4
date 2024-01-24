all: compile assemble

compile:
	cat in.rl | perl -MCarp::Always main.pl > out.rba

assemble:
	../rabbit/rabbit-asm out.rba

run:
	./out
