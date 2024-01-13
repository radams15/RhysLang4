//
// Created by rhys on 1/13/24.
//

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>

#if defined(unix) || defined(__linux__)
#include <unistd.h>
#endif

#include "builtins.h"

extern cell sp;
cell get_word(cell a);

cell t3xopen(char *s, int mode) {
    int	r;

    if (1 == mode)
        r = creat(s, 0644);
    else if (3 == mode)
        r = open(s, O_WRONLY);
    else
        r = open(s, get_word(sp + 2));
#ifdef __TURBOC__
    if (r > 0) setmode(r, O_BINARY);
#endif
    if (3 == mode) lseek(r, 0L, SEEK_END);
    return r;
}

cell t3xseek(cell fd, cell where, cell how) {
    long	w;
    int	h;

    switch (how) {
        case 0:	w = where; h = SEEK_SET; break;
        case 1: w = where; h = SEEK_CUR; break;
        case 2: w = where; w = -w; h = SEEK_END; break;
        case 3: w = where; w = -w; h = SEEK_CUR; break;
        default: return 0xffff;
    }
    return lseek(fd, w, h) < 0? 0xffff: 0;
}

cell t3xtrunc(cell fd) {
#ifndef EXTRA
    fail("t3x.trunc not implemented");
    return 0;
#else
    #ifdef unix
	return ftruncate(fd, lseek(fd, 0, SEEK_CUR));
 #endif
 #ifdef __TURBOC__
	return write(fd, "", 0);
 #endif
#endif
}

char	*Sem;

void handle_break(int dummy) {
    Sem[0] = Sem[1] = -1;
#ifdef EXTRA
    #ifdef unix
	signal(SIGINT, handle_break);
 #endif
#endif
}

cell t3xbreak(cell sem) {
#ifndef EXTRA
    fail("t3x.break not implemented");
#else
    #ifdef unix
	if (0 == sem) {
		signal(SIGINT, SIG_DFL);
	}
	else if (1 == sem) {
		/* ignore */
	}
	else {
		Sem = (char *) &mem[sem];
		Sem[0] = Sem[1] = 0;
		signal(SIGINT, handle_break);
	}
 #endif
 #ifdef __TURBOC__
	fail("t3x.break not implemented");
 #endif
#endif
    return 0;
}