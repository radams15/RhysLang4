#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum Opcode {
    OP_HALT = 0x0,
    OP_MOVE = 0x1,
    OP_ADD = 0x2,
    OP_SUB = 0x3,
    OP_MUL = 0x4,
    OP_DIV = 0x5,
    OP_SHR = 0x6,
    OP_SHL = 0x7,
    OP_NAND = 0x8,
    OP_XOR = 0x9,
    OP_BR = 0xa,
    OP_BRZ = 0xb,
    OP_BRNZ = 0xc,
    OP_IN = 0xd,
    OP_OUT = 0xe
} Opcode_t;


typedef enum ArgType {
    ARG_REG,
    ARG_INT
} ArgType_t;

typedef enum Register {
    REG_A = 0,
    REG_B,
    REG_C,
    REG_D,
    REG_E,
    REG_F,
    REG_G,
    REG_H,
    REG_I,
    REG_J,
    REG_IP,
    REG_SP,
    REG_BP,
    REG_RET,
    REG_TMP
} Register_t;

typedef struct Arg {
    uint16_t val;
    enum ArgType type;
    uint8_t addr;
} Arg_t;

typedef struct Op {
    enum Opcode code;
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

uint8_t load_ops(const char* file, Op_t** ops_ptr) {
    FILE* fh = fopen(file, "r");
    if(fh == NULL) {
        fprintf(stderr, "Failed to open file '%s'\n", file);
        return 1;
    }

    uint16_t size = read_word(fh);

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
    fclose(fh);

    Op_t* ops = malloc(n_ops * sizeof(Op_t));

    uint16_t p = 0;
    uint16_t i = 0;
    while(p < size) {
        parse_op(&raw[p], &ops[i]);

        p += ops[i].n_args + 1;
        i++;
    }

    free(raw);

    *ops_ptr = ops;

    return 0;
}

// Gets the value in the argument, ignoring references
#define arg_raw(arg) ((arg)->type == ARG_REG ? &regs[(arg)->type] : &(arg)->val)

// Gets the value in the argument, returning memory pointers for references
#define arg_val(arg) ((arg)->addr? &mem[*arg_raw(arg)] : arg_raw(arg))

int interp(Op_t* prog) {
    uint16_t regs[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint16_t* ip = &regs[REG_IP];

    uint16_t mem_size = 3200;
    uint16_t* mem = malloc(mem_size * sizeof(uint16_t));

    regs[REG_SP] = mem_size;
    regs[REG_BP] = mem_size;

    *ip = 0;

    while(1) {
        Op_t* op = &prog[*ip];

        switch (op->code) {
            case OP_HALT:
                goto end;
            case OP_MOVE:
                *arg_val(&op->arg1) = *arg_val(&op->arg2);
                break;
            case OP_ADD:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) + *arg_val(&op->arg3);
                break;
            case OP_SUB:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) - *arg_val(&op->arg3);
                break;
            case OP_MUL:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) * *arg_val(&op->arg3);
                break;
            case OP_DIV:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) / *arg_val(&op->arg3);
                break;
            case OP_SHR:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) >> *arg_val(&op->arg3);
                break;
            case OP_SHL:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) << *arg_val(&op->arg3);
                break;
            case OP_NAND:
                *arg_val(&op->arg1) = ! (*arg_val(&op->arg2) & *arg_val(&op->arg3));
                break;
            case OP_XOR:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) ^ *arg_val(&op->arg3);
                break;
            case OP_BR:
                *ip = *arg_val(&op->arg1);
                break;

            // TODO conditional branching with flags
            case OP_BRZ:
                break;
            case OP_BRNZ:
                break;

            case OP_IN:
                *arg_val(&op->arg1) = getchar();
                getchar(); // For \n
                break;
            case OP_OUT: {
                printf("%c\n", *arg_val(&op->arg1));

                break;
            }
        }

        (*ip)++;
    }
end:

    free(mem);

    return 0;
}

int main(int argc, char** argv) {
    //const char* file = "../out.rba";
    const char* file = "out.rba";

    Op_t* ops;

    if(load_ops(file, &ops) != 0) {
        fprintf(stderr, "Failed to load program\n");
        return 1;
    }

    interp(ops);

    free(ops);
}