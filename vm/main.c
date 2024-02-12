#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

const uint16_t mem_size = 1024;

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
    OP_INT = 0xd,
    OP_NULL1 = 0xe,
    OP_BRKPT = 0xf,

    OP_PUSH = 0x10,
    OP_POP = 0x11,
    OP_ENTER = 0x12,
    OP_LEAVE = 0x13,
    OP_CALL = 0x14,

    OP_BRLZ = 0x15, // less than zero
    OP_BRGZ = 0x16, // greater than zero
} Opcode_t;

const char *opstrings[] = {
        "OP_HALT",
        "OP_MOVE",
        "OP_ADD",
        "OP_SUB",
        "OP_MUL",
        "OP_DIV",
        "OP_SHR",
        "OP_SHL",
        "OP_NAND",
        "OP_XOR",
        "OP_BR",
        "OP_BRZ",
        "OP_BRNZ",
        "OP_INT",
        "",
        "OP_BRKPT",
        "OP_PUSH",
        "OP_POP",
        "OP_ENTER",
        "OP_LEAVE",
        "OP_CALL",
        "OP_BRLZ",
        "OP_BRGZ"
};


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

typedef enum IntCode {
    IN = 0x0,
    OUT = 0x1,
    WRITE = 0x2,
    READ = 0x3,
    OUTI = 0x4
} IntCode_t;

typedef struct Arg {
    uint16_t val;
    int8_t offset;
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

int8_t get_offset(uint16_t in) {
    uint8_t negative = (uint8_t) (in >> 13) & 1;

    uint16_t without_reg = in >> 4;
    uint8_t abs_val = (uint8_t) without_reg;

    return abs_val * (negative ? -1 : 1);
}

int parse_arg(uint16_t in, Arg_t *arg) {
    if ((in >> 15) & 1) {
        arg->type = ARG_REG;
        arg->val = (uint8_t) (in & ~(1 << 15)) & ~(0b1111 << 4); // Only take first 4 bits
        arg->offset = get_offset(in);
    } else {
        arg->type = ARG_INT;
        arg->val = in;
        arg->offset = 0;
    }

    if ((in >> 14) & 1) {
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
        case OP_BRGZ:
        case OP_BRLZ:
        case OP_INT:
        case OP_PUSH:
        case OP_POP:
        case OP_CALL:
            return 1;

        default:
            return 0;
    }
}

int parse_op(const uint16_t *in, Op_t *op) {
    op->code = in[0];

    op->n_args = n_args(in[0]);

    if (op->n_args == 3) {
        parse_arg(in[1], &op->arg1);
        parse_arg(in[2], &op->arg2);
        parse_arg(in[3], &op->arg3);
    } else if (op->n_args == 2) {
        parse_arg(in[1], &op->arg1);
        parse_arg(in[2], &op->arg2);
    } else if (op->n_args == 1) {
        parse_arg(in[1], &op->arg1);
    }

    return 0;
}

uint16_t read_word(FILE *fh) {
    uint8_t a, b;

    if (fread(&a, sizeof(uint8_t), 1, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        exit(1);
    }

    if (fread(&b, sizeof(uint8_t), 1, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        exit(1);
    }

    return a | (b << 8);
}

uint8_t load_ops(const char *file, Op_t **ops_ptr, uint16_t *mem) {
    FILE *fh = fopen(file, "r");
    if (fh == NULL) {
        fprintf(stderr, "Failed to open file '%s'\n", file);
        return 1;
    }

    uint16_t size = read_word(fh);
    uint16_t data_size = read_word(fh);

    for (int i = 0; i < data_size; i++) {
        int elem_size = read_word(fh);
        int addr = read_word(fh);

        for (int x = 0; x < elem_size; x++)
            if (fread(&mem[addr + x], sizeof(uint8_t), 1, fh) < 1) {
                fprintf(stderr, "Failed to read data\n");
                return 1;
            }

        i += elem_size;
    }


    uint16_t *raw = malloc(size * sizeof(uint16_t));

    uint16_t in_op = 0;
    uint16_t n_ops = 0;
    for (uint16_t i = 0; i < size; i++) {
        raw[i] = read_word(fh);

        if (in_op <= 0) {
            in_op = n_args(raw[i]);
            n_ops++;
        } else {
            in_op--;
        }
    }
    fclose(fh);

    Op_t *ops = malloc(n_ops * sizeof(Op_t));

    uint16_t p = 0;
    uint16_t i = 0;
    while (p < size) {
        parse_op(&raw[p], &ops[i]);

        p += ops[i].n_args + 1;
        i++;
    }

    free(raw);

    *ops_ptr = ops;

    return 0;
}

// Gets the value in the argument, ignoring references
#define arg_raw(arg) ((arg)->type == ARG_REG? \
    &regs[(arg)->val] : &(arg)->val)

// Gets the value in the argument, returning memory pointers for references
#define arg_val(arg) ((arg)->addr? \
    &mem[*arg_raw(arg) + (arg)->offset] : arg_raw(arg))

#define push(a) mem[regs[REG_SP]] = a; regs[REG_SP]--

#define pop(a) regs[REG_SP]++; a = mem[regs[REG_SP]]


#define printstack(n) for(int i=0 ; i<n ; i++)printf("BP-%d = %d = %04x %s\n", i, regs[REG_BP]-i, mem[regs[REG_BP]-i], (regs[REG_BP]-i == regs[REG_SP]? "<= SP" : ""));
#define printstack_rev(n) for(int i=n ; i>=0 ; i--)printf("BP+%d = %d = %04x %s\n", i, regs[REG_BP]+i, mem[regs[REG_BP]+i], (regs[REG_BP]+i == regs[REG_SP]? "<= SP" : ""));

int intr(IntCode_t num, uint16_t *regs, uint16_t *mem) {
    switch (num) {
        case IN:
            regs[REG_A] = getchar();
            getchar(); // for \n
            break;
        case OUT:
            printf("%c", regs[REG_A]);
            break;

        case OUTI:
            printf("%d", regs[REG_A]);
            break;

        case WRITE:
            write(1, &mem[regs[REG_A]], regs[REG_B]);
            break;

        default:
            fprintf(stderr, "Invalid interrupt: %02x\n", num);
            return 1;
    }

    return 0;
}

int interp(Op_t *prog, uint16_t *mem) {
    uint16_t regs[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint16_t *ip = &regs[REG_IP];

    regs[REG_SP] = mem_size;
    regs[REG_BP] = mem_size;

    *ip = 0; // Entrypoint @ instruction 0

    uint16_t start_ip;
    while (1) {
        start_ip = *ip;
        Op_t *op = &prog[*ip];

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
                *arg_val(&op->arg1) = !(*arg_val(&op->arg2) & *arg_val(&op->arg3));
                break;
            case OP_XOR:
                *arg_val(&op->arg1) = *arg_val(&op->arg2) ^ *arg_val(&op->arg3);
                break;
            case OP_BR:
                *ip = *arg_val(&op->arg1);
                break;

            case OP_PUSH:
            push(*arg_val(&op->arg1));
                break;
            case OP_POP:
            pop(*arg_val(&op->arg1));
                break;


            case OP_BRZ:
                if (regs[REG_TMP] == 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRNZ:
                if (regs[REG_TMP] != 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRGZ:
                if (((int16_t) regs[REG_TMP]) > 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRLZ:
                if (((int16_t) regs[REG_TMP]) < 0)
                    *ip = *arg_val(&op->arg1);
                break;


            case OP_INT:
                intr(*arg_val(&op->arg1), regs, mem);
                break;

            case OP_BRKPT:
                break;

            case OP_ENTER:
            push(regs[REG_BP]);
                regs[REG_BP] = regs[REG_SP];
                break;

            case OP_LEAVE:
                regs[REG_SP] = regs[REG_BP];
                pop(regs[REG_BP]);
                break;

            case OP_CALL:
            push((*ip) + 1);
                *ip = *arg_val(&op->arg1);
                break;

            default:
                fprintf(stderr, "Invalid opcode: %02x\n", op->code);
                goto end;
        }

        if (start_ip == *ip) // If IP has not been modified, then increment it
            (*ip)++;
    }
    end:

    return 0;
}

int main(int argc, char **argv) {
    const char *file = "../out.rba";
    //const char* file = "out.rba";

    uint16_t *mem = calloc(mem_size, sizeof(uint16_t));

    Op_t *ops;

    if (load_ops(file, &ops, mem) != 0) {
        fprintf(stderr, "Failed to load program\n");
        return 1;
    }

    interp(ops, mem);

    free(ops);

    free(mem);
}