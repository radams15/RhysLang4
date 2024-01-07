#include <stdio.h>
#include <stdlib.h>

#include "ops.h"

#ifdef __unix__
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;

typedef signed char int8_t;
typedef signed short int16_t;
#endif

uint16_t reg[RCNT] = {0};
FILE* fh;
uint8_t* code;

#define log(...) fprintf(stderr, __VA_ARGS__)
#define fatal(...) log(__VA_ARGS__); exit(1)

#define pc reg[RPC]
#define pc_off(x) code[pc+x]

#define pc_off_16(x) code[pc+x] | (code[pc+x+1] << 8)

void trap(uint8_t number) {
    log("Trap: 0x%04x\n", number);
    switch (number) {
        case TRP_IN_U16:
            reg[R0] = getchar();
            getchar(); // Consume the \n
            break;

        case TRP_OUT_U16:
            printf("%x", reg[R0]);
            fflush(stdout);
            break;

        default:
            fatal("Unknown trap 0x%04x\n", number);
    }
}

int main(int argc, char** argv) {
    if(argc <= 1) {
        fatal("Usage: %s [FILE] [ARGS]\n", argv[0]);
    }

    fh = fopen(argv[1], "r");

    if(fh == NULL) {
        fatal("Failed to open file: %s\n", argv[1]);
    }

    fseek(fh, 0, SEEK_END); // seek to end of file
    uint16_t size = ftell(fh); // get current file pointer
    fseek(fh, 0, SEEK_SET); // seek back to beginning of file

    code = malloc(size*sizeof(uint8_t));
    fread(code, sizeof(uint8_t), size, fh);

    fclose(fh);

    while(1) {
        uint8_t instr = code[pc];

        log("Instruction @ %d => %04x\n", pc, instr);

        switch(instr) {
            case OP_ADD1: // add1 a b c   =>   a = b + c
                reg[pc_off_16(1)] = reg[pc_off_16(3)] + reg[pc_off_16(5)];
                pc += 7;
                break;

            case OP_ADD2:
                reg[pc_off_16(1)] = reg[pc_off_16(3)] + pc_off_16(5);
                pc += 7;
                break;

            case OP_TRAP:
                trap(pc_off_16(1));
                pc += 3;
                break;

            case OP_HALT:
                goto end;

            default:
                fprintf(stderr, "Unknown instruction: %04x\n", instr);
                goto end;
        }
    }

end:

    return 0;
}
