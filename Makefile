all: compile

compile:
	perl preprocess.pl in.rl | perl -MCarp::Always main.pl > out.rba
