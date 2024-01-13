/*
 * Ad-hoc 16-bit Tcode/0 virtual machine
 * Nils mem Holm, 2017,2022,2023
 * Public domain / 0BSD license
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>

#if defined(unix) || defined(__linux__)
#include <unistd.h>
#endif

#include "types.h"
#include "builtins.h"

#ifndef DEBUG
#undef DEBUG
#endif

#if DEBUG
#define debug(...) printf(__VA_ARGS__)
#else
#define debug(...)
#endif

/*
 * Define EXTRA to enable t3x.trunc and t3x.break.
 */
#define EXTRA

#ifdef EXTRA
 #include <signal.h>
#endif

#include "ops.h"

#define MEMSIZE	0xfffe

byte	*mem;
cell	program_length;

char	**Args;
int	Narg;

void writes(char *s) { write(1, s, strlen(s)); }
void wlog(char *s) { write(2, s, strlen(s)); }

void fail(char *s) {
	wlog("tcvm: ");
	wlog(s);
	wlog("\n");
	exit(1);
}

void load(char *s) {
	int	fd, k;
	char	b[6];
	char	p[100];

	k = strlen(s);
	if (k > 96) fail("file name too long");
	strcpy(p, s);
	fd = open(p, O_RDONLY);
	if (fd < 0) fail("could not open program");
#ifdef __TURBOC__
	setmode(fd, O_BINARY);
#endif
	read(fd, b, 6);
	if (memcmp(b, "T3X0", 4)) fail("not arg1 tcvm program");
    mem = malloc(MEMSIZE);
	if (NULL == mem) fail("not enough memory");
    program_length = read(fd, mem, MEMSIZE);
	close(fd);
}

cell	acc, frame, I, sp;

cell get_word(cell a) {
    return mem[a + 0] | (mem[a + 1] << 8);
}

void set_word(cell a, cell w) {
    mem[a + 0] = w & 255;
    mem[a + 1] = (w >> 8) & 255;
}

void push(cell x) {
    sp -= 2;
	set_word(sp, x);
}

cell pop(void) {
    sp += 2;
	return get_word(sp - 2);
}
#ifdef __TURBOC__                                                               
 int trunc16(cell x) { return x; }
#else                                                                           
 int trunc16(cell x) { return x > 32767 ? x - 65536 : x; }
#endif

#define arg1()	get_word(I+1)
#define arg2() get_word(I+3)

cell memscan(cell p, cell c, cell k) {
	cell	i;

	for (i=0; i<k; i++)
		if (mem[p + i] == c)
			return i;
	return 0xffff;
}

int getarg(int n, char *s, int k) {
	int	j, m;

	n++;
	k--;
	if (n >= Narg) return -1;
	j = strlen(Args[n]);
	m = j>=k? k: j;
	memcpy(s, Args[n], m);
	s[m] = 0;
	return m;
}

cell libcall(cell n) {
    cell	r;

#ifdef DEBUG
    printf("LIBCALL(%d): sp+6=%x sp+4=%x sp+2=%x ret=%x\n", n, get_word(sp+6), get_word(sp+4), get_word(sp+2), get_word(sp));
#endif
    switch (n) {
        case  0: r = 2; break;
        case  1: strcpy((char *) &mem[get_word(sp + 2)], "\n"); r = get_word(sp + 2); break;
        case  2: r = memcmp(&mem[get_word(sp + 6)], &mem[get_word(sp + 4)], get_word(sp + 2)); break;
        case  3: memmove(&mem[get_word(sp + 6)], &mem[get_word(sp + 4)], get_word(sp + 2)); r = 0; break;
        case  4: memset(&mem[get_word(sp + 6)], get_word(sp + 4), get_word(sp + 2)); r = 0; break;
        case  5: r = memscan(get_word(sp + 6), get_word(sp + 4), get_word(sp + 2)); break;
        case  6: r = getarg(get_word(sp + 6), (char *) &mem[get_word(sp + 4)], get_word(sp + 2)); break;
        case  7: r = creat((char *) &mem[get_word(sp + 2)], 0644); break;
        case  8: r = t3xopen((char *) &mem[get_word(sp + 4)], get_word(sp + 2)); break;
        case  9: r = close(get_word(sp + 2)); break;
        case 10: r = read(get_word(sp + 6), &mem[get_word(sp + 4)], get_word(sp + 2)); break;
        case 11: r = write(get_word(sp + 6), &mem[get_word(sp + 4)], get_word(sp + 2)); break;
        case 12: r = t3xseek(get_word(sp + 6), get_word(sp + 4), get_word(sp + 2)); break;
        case 13: r = rename((char *) &mem[get_word(sp + 4)], (char *)&mem[get_word(sp + 2)]); break;
        case 14: r = remove((char *) &mem[get_word(sp + 2)]); break;
        case 15: r = t3xtrunc(get_word(sp + 2)); break;
        case 16: r = t3xbreak(get_word(sp + 2)); break;
        default: fail("bad library call"); r = 0; break;
    }
    return r & 0xffff;
}

void run(void) {
	cell	t;

    sp = MEMSIZE;
    frame = MEMSIZE;
	for (I = 0;; I++) {
#ifdef DEBUG
	printf("frame=%04x sp=%04x I=%04x C=%s(%02x) arg1=%04x acc=%04x S0=%04x\n",
		frame, sp, I, lookup[mem[I]], mem[I], arg1(), acc, get_word(sp));
#endif
	if (sp < program_length) fail("stack overflow");
	switch (mem[I]) {
	case OP_NOOP: break;
	case OP_PUSH: push(acc); break;
	case OP_CLEAR: acc = 0; break;
	case OP_DROP: sp += 2; break;
	case OP_LDVAL:
	case OP_LDADDR: acc = arg1(); I += 2; break;
	case OP_LDLREF: acc = frame + arg1() & 0xffff; I += 2; break;
	case OP_LDGLOB: acc = get_word(arg1()); I += 2; break;
	case OP_LDLOCL: acc = get_word(frame + arg1() & 0xffff); I += 2; break;
	case OP_STGLOB: set_word(arg1(), acc); I += 2; break;
	case OP_STLOCL: set_word(frame + arg1() & 0xffff, acc); I += 2; break;
	case OP_STINDR: set_word(pop(), acc); break;
	case OP_STINDB: mem[pop()] = (byte) acc; break;
	case OP_INCGLOB: t = arg1(); set_word(t, get_word(t) + 1 & 0xffff); I += 2; break;
	case OP_INCLOCL: t = arg1(); set_word(frame + t & 0xffff, get_word(frame + t & 0xffff) + 1 & 0xffff);
		   I += 2; break;
	case OP_INCR: acc += trunc16(arg1()); acc &= 0xffff; I += 2; break;
	case OP_STACK:
	case OP_UNSTACK: sp += trunc16(arg1()); sp &= 0xffff; I += 2; break;
	case OP_LOCLVEC: push(sp); break;
	case OP_GLOBVEC: set_word(arg1(), sp); I += 2; break;
	case OP_INDEX: acc = (acc << 1) + pop() & 0xffff; break;
	case OP_DEREF: acc = get_word(acc); break;
	case OP_INDXB: acc = acc + pop() & 0xffff; break;
	case OP_DREFB: acc = mem[acc]; break;
	case OP_CALL: debug("Call %02x,  ret => %02x\n", arg1(), I + 3); push(I + 2); I = arg1() - 1; if(arg1() == 0) {fprintf(stderr, "Error, null jump. Exiting...\n"); exit(1); } break;
	case OP_CALR: push(I); I = acc - 1; break;
	case OP_SKIP:
	case OP_JUMP: I = arg1() - 1; break;
	case OP_RJUMP: I += mem[I + 1] + 1; break;
	case OP_JMPFALSE: if (0 == acc) I = arg1() - 1; else I += 2; break;
	case OP_JMPTRUE: if (0 != acc) I = arg1() - 1; else I += 2; break;
	case OP_FOR: if (trunc16(pop()) >= trunc16(acc)) I = arg1() - 1; else I += 2; break;
	case OP_FORDOWN: if (trunc16(pop()) <= trunc16(acc)) I = arg1() - 1; else I += 2; break;
	case OP_MKFRAME: push(frame); debug("Mkframe: %04x => %04x\n", frame, sp); frame = sp; break;
	case OP_DELFRAME: debug("Delframe: %02x => %04x\n", sp, get_word(sp)); frame = pop(); break;
	case OP_RET: I = pop(); break;
	case OP_HALT: exit(pop()); break;
	case OP_NEG: acc = -acc & 0xffff; break;
	case OP_INV: acc = ~acc & 0xffff; break;
	case OP_LOGNOT: acc = 0 == acc ? 0xffff : 0; break;
	case OP_ADD: acc = pop() + acc & 0xffff; break;
	case OP_SUB: acc = pop() - acc & 0xffff; break;
	case OP_MUL: acc = trunc16(pop()) * trunc16(acc) & 0xffff; break;
	case OP_DIV: acc = trunc16(pop()) / trunc16(acc) & 0xffff; break;
	case OP_MOD: acc = pop() % acc & 0xffff; break;
	case OP_AND: acc = pop() & acc; break;
	case OP_OR: acc = pop() | acc; break;
	case OP_XOR: acc = pop() ^ acc; break;
	case OP_SHL: acc = (pop() << acc) & 0xffff; break;
	case OP_SHR: acc = pop() >> acc; break;
	case OP_EQ: acc = pop() == acc ? 0xffff : 0; break;
	case OP_NE: acc = pop() != acc ? 0xffff : 0; break;
	case OP_LT: acc = trunc16(pop()) < trunc16(acc) ? 0xffff : 0; break;
	case OP_GT: acc = trunc16(pop()) > trunc16(acc) ? 0xffff : 0; break;
	case OP_LE: acc = trunc16(pop()) <= trunc16(acc) ? 0xffff : 0; break;
	case OP_GE: acc = trunc16(pop()) >= trunc16(acc) ? 0xffff : 0; break;
	case OP_UMUL: acc = pop() * acc & 0xffff; break;
	case OP_UDIV: acc = pop() / acc & 0xffff; break;
	case OP_ULT: acc = pop() < acc ? 0xffff : 0; break;
	case OP_UGT: acc = pop() > acc ? 0xffff : 0; break;
	case OP_ULE: acc = pop() <= acc ? 0xffff : 0; break;
	case OP_UGE: acc = pop() >= acc ? 0xffff : 0; break;
	case OP_SCALL: debug("Stack @ %04x\n", sp); acc = libcall(mem[I + 1]); I = pop(); debug("Stack @ %04x\n", sp); break;
	case OP_POP:  acc = pop(); break;
	default:
	    fprintf(stderr, "invalid opcode: %x\n", mem[I]);
	    exit(1);
	}
	//getchar();
	}
}

int main(int argc, char **argv) {
	if (argc < 2) fail("usage: tcvm program [args]");
	Args = argv;
	Narg = argc;
	load(argv[1]);
	run();
	return EXIT_SUCCESS;
}
