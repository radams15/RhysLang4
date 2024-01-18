#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define OP_HALT 0x0
#define OP_MOVE 0x1
#define OP_ADD 0x2
#define OP_SUB 0x3
#define OP_MUL 0x4
#define OP_DIV 0x5
#define OP_SHR 0x6
#define OP_SHL 0x7
#define OP_NAND 0x8
#define OP_XOR 0x9
#define OP_BR 0xa
#define OP_BRZ 0xb
#define OP_BRNZ 0xc
#define OP_IN 0xd
#define OP_OUT 0xe


typedef enum ArgType {
    ARG_REG,
    ARG_INT
} ArgType_t;

typedef struct Arg {
    uint16_t val;
    enum ArgType type;
    uint8_t addr;
} Arg_t;

typedef struct Op {
    uint8_t code;
    uint8_t n_args;
    Arg_t arg1;
    Arg_t arg2;
    Arg_t arg3;
} Op_t;

int parse_arg(uint16_t in, Arg_t* arg) {
    if((in >> 15) & 1) {
        arg->type = ARG_REG;
        arg->val = in & ~(1 << 15);
    } else {
        arg->type = ARG_INT;
        arg->val = in;
    }

    if((in >> 14) & 1) {
        arg->addr = 1;
        arg->val &= ~(1 << 14);
    } else {
        arg->addr = 0;
    }

    return 0;
}

uint8_t n_args(const uint16_t in) {
    switch (in) {
        case OP_ADD:
        case OP_SUB:
        case OP_MUL:
        case OP_DIV:
        case OP_SHR:
        case OP_SHL:
        case OP_NAND:
        case OP_XOR:
            return 3;

        case OP_MOVE:
            return 2;

        case OP_BR:
        case OP_BRZ:
        case OP_BRNZ:
        case OP_IN:
        case OP_OUT:
            return 1;

        default:
            return 0;
    }
}

int parse_op(const uint16_t* in, Op_t* op) {
    op->code = in[0];

    op->n_args = n_args(in[0]);

    if(op->n_args == 3) {
        parse_arg(in[1], &op->arg1);
        parse_arg(in[2], &op->arg2);
        parse_arg(in[3], &op->arg3);
    } else if(op->n_args == 2) {
        parse_arg(in[1], &op->arg1);
        parse_arg(in[2], &op->arg2);
    } else if(op->n_args == 1) {
        parse_arg(in[1], &op->arg1);
    }

    return 0;
}

uint16_t read_word(FILE* fh) {
    uint8_t a, b;

    if(fread(&a, sizeof(uint8_t), 1, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        exit(1);
    }

    if(fread(&b, sizeof(uint8_t), 1, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        exit(1);
    }

    return a | (b<<8);
}

int main(int argc, char** argv) {
    const char* file = "../out.rba";

    FILE* fh = fopen(file, "r");
    if(fh == NULL) {
        fprintf(stderr, "Failed to open file '%s'\n", file);
        return 1;
    }


    uint16_t size = read_word(fh);
    printf("Size: %d\n", size);

    uint16_t* raw = malloc(size * sizeof(uint16_t));

    uint16_t in_op = 0;
    uint16_t n_ops = 0;
    for(uint16_t i=0 ; i<size ; i++) {
        raw[i] = read_word(fh);

        if(in_op <= 0) {
            in_op = n_args(raw[i]);
            n_ops++;
        } else {
            in_op--;
        }
    }

    printf("Num Ops: %d\n", n_ops);

    Op_t* prog = malloc(n_ops * sizeof(Op_t));

    uint16_t p = 0;
    uint16_t i = 0;
    while(p < size) {
        parse_op(&raw[p], &prog[i]);

        p += prog[i].n_args + 1;
        i++;
    }

    free(raw);

    for(i=0 ; i<n_ops ; i++) {
        printf("Op: %04x\n", prog[i].code);
    }

    free(prog);

    fclose(fh);
}