#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>

#include "defs.h"

#ifdef DEBUG
#define dbprintf(...) \
    fprintf(stderr, __VA_ARGS__)
#else
#define dbprintf(...)
#endif

const uint16_t mem_size = 1024;

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
        "OP_NULL1",
        "OP_BRKPT",
        "OP_PUSH",
        "OP_POP",
        "OP_ENTER",
        "OP_LEAVE",
        "OP_CALL",
        "OP_BRLZ",
        "OP_BRGZ"
};

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

int read_arg(FILE* fh, Arg_t* arg) {
    dbprintf("Read arg from: %04lx => ", ftell(fh));

    if (fread(arg, sizeof(Arg_t), 1, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        return 1;
    }

    dbprintf("to %04lx (%02x)\n", ftell(fh), sizeof(Arg_t));

    return 0;
}

int read_op(FILE* fh, Op_t* op) {
    dbprintf("Read from: %04lx => ", ftell(fh));
    if (fread(op, sizeof(uint8_t), 2, fh) < 0) {
        fprintf(stderr, "Failed to read file\n");
        return 1;
    }

    dbprintf("to %04lx\n", ftell(fh));


    dbprintf("%d args\n", op->n_args);

    switch (op->n_args) {
        case 1:
            if(read_arg(fh, &op->arg1)) return 1;
            break;
        case 2:
            if(read_arg(fh, &op->arg1)) return 1;
            if(read_arg(fh, &op->arg2)) return 1;
            break;
        case 3:
            if(read_arg(fh, &op->arg1)) return 1;
            if(read_arg(fh, &op->arg2)) return 1;
            if(read_arg(fh, &op->arg3)) return 1;
            break;
        case 0:

        default:
            break;
    }

    return 0;
}

uint8_t load_ops(const char *file, Op_t **ops_ptr, uint16_t *mem) {
    FILE *fh = fopen(file, "r");
    if (fh == NULL) {
        fprintf(stderr, "Failed to open file '%s'\n", file);
        return 1;
    }

    uint16_t prog_size = read_word(fh);
    uint16_t data_size = read_word(fh);

    dbprintf("Data Length: %d\n", data_size);

    for (int i = 0; i <= data_size; i++) {
        int elem_size = read_word(fh);
        int addr = read_word(fh);

        dbprintf("\nData %d (%d) @ addr %d: \n", i, elem_size, addr);

        for (int x = 0; x < elem_size; x++) {
            if (fread(&mem[addr + x], sizeof(uint8_t), 1, fh) < 1) {
                fprintf(stderr, "Failed to read data\n");
                return 1;
            }
        }

        i += elem_size;
    }

    dbprintf("Program Length: %d\n", prog_size);

    Op_t *ops = malloc(prog_size * sizeof(Op_t));

    for (uint16_t i = 0; i < prog_size; i++) {
        memset(&ops[i], 0, sizeof(Op_t));

        if(read_op(fh, &ops[i])) {
            fprintf(stderr, "Failed to read op from file\n");
            return 1;
        }

        dbprintf("OP: %s (%02x)\n\n", opstrings[ops[i].code], ops[i].n_args);
    }
    fclose(fh);

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
    dbprintf("Interrupt: ");
    switch (num) {
        case IN:
            dbprintf("IN\n");
            regs[REG_A] = getchar();
            getchar(); // for \n
            break;
        case OUT:
            dbprintf("OUT\n");
            printf("%c", regs[REG_A]);
            break;

        case OUTI:
            dbprintf("OUTI\n");
            printf("%d", regs[REG_A]);
            break;

        case WRITE:
            dbprintf("WRITE\n");
            write(1, &mem[regs[REG_A]], regs[REG_B]);
            break;

        default:
            dbprintf("INVALID\n");
            fprintf(stderr, "Invalid interrupt: %02x\n", num);
            return 1;
    }

    return 0;
}

int interp(Op_t *prog, uint16_t *mem) {
    uint16_t regs[REG_TMP+1] = {0};
    uint16_t *ip = &regs[REG_IP];

    regs[REG_SP] = mem_size;
    regs[REG_BP] = mem_size;

    *ip = 0; // Entrypoint @ instruction 0

    uint16_t start_ip;
    while (1) {
        start_ip = *ip;
        Op_t *op = &prog[*ip];

        dbprintf("IP = %02x\n", *ip);

        switch (op->code) {
            case OP_HALT:
                dbprintf("HALT\n");
                goto end;
            case OP_MOVE:
                dbprintf("MOVE %d => %d\n", op->arg1.val, op->arg2.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2);
                break;
            case OP_ADD:
                dbprintf("ADD %d = %d + %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) + *arg_val(&op->arg3);
                break;
            case OP_SUB:
                dbprintf("SUB %d = %d - %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) - *arg_val(&op->arg3);
                break;
            case OP_MUL:
                dbprintf("MUL %d = %d * %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) * *arg_val(&op->arg3);
                break;
            case OP_DIV:
                dbprintf("DIV %d = %d / %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) / *arg_val(&op->arg3);
                break;
            case OP_SHR:
                dbprintf("SHR %d = %d >> %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) >> *arg_val(&op->arg3);
                break;
            case OP_SHL:
                dbprintf("SHL %d = %d << %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) << *arg_val(&op->arg3);
                break;
            case OP_NAND:
                dbprintf("NAND %d = %d NAND %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = !(*arg_val(&op->arg2) & *arg_val(&op->arg3));
                break;
            case OP_XOR:
                dbprintf("XOR %d = %d XOR %d\n", op->arg1.val, op->arg2.val, op->arg3.val);
                *arg_val(&op->arg1) = *arg_val(&op->arg2) ^ *arg_val(&op->arg3);
                break;
            case OP_BR:
                dbprintf("BR %d\n", op->arg1.val);
                *ip = *arg_val(&op->arg1);
                break;

            case OP_PUSH:
                dbprintf("PUSH %d\n", op->arg1.val);
                push(*arg_val(&op->arg1));
                break;
            case OP_POP:
                dbprintf("POP %d\n", op->arg1.val);
                pop(*arg_val(&op->arg1));
                break;


            case OP_BRZ:
                dbprintf("BRZ %d\n", op->arg1.val);
                if (regs[REG_TMP] == 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRNZ:
                dbprintf("BRNZ %d\n", op->arg1.val);
                if (regs[REG_TMP] != 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRGZ:
                dbprintf("BRGZ %d\n", op->arg1.val);
                if (((int16_t) regs[REG_TMP]) > 0)
                    *ip = *arg_val(&op->arg1);
                break;
            case OP_BRLZ:
                dbprintf("BRLZ %d\n", op->arg1.val);
                if (((int16_t) regs[REG_TMP]) < 0)
                    *ip = *arg_val(&op->arg1);
                break;


            case OP_INT:
                intr(*arg_val(&op->arg1), regs, mem);
                break;

            case OP_BRKPT:
                dbprintf("BRKPT\n");
                break;

            case OP_ENTER:
                dbprintf("ENTER\n");
                push(regs[REG_BP]);
                regs[REG_BP] = regs[REG_SP];
                break;

            case OP_LEAVE:
                dbprintf("LEAVE\n");
                regs[REG_SP] = regs[REG_BP];
                pop(regs[REG_BP]);
                break;

            case OP_CALL:
                dbprintf("CALL %02x\n", op->arg1.val);
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
    // const char *file = "./out.rba";

    dbprintf("Load file '%s'\n", file);

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