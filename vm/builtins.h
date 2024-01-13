//
// Created by rhys on 1/13/24.
//

#ifndef RHYSLANG4_BUILTINS_H
#define RHYSLANG4_BUILTINS_H

#include "types.h"

cell t3xopen(char *s, int mode);

cell t3xseek(cell fd, cell where, cell how);

cell t3xtrunc(cell fd);

void handle_break(int dummy) ;

cell t3xbreak(cell sem);

void fail(char *s);

#endif //RHYSLANG4_BUILTINS_H
