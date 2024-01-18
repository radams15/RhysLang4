#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

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
    int size = 126;

    FILE* fh = fopen(file, "r");

    if(fh == NULL) {
        fprintf(stderr, "Failed to open file '%s'\n", file);
        return 1;
    }


    uint16_t* raw = malloc(size * sizeof(uint16_t));
    for(int i=0 ; i<size ; i+=2) {
        raw[i] = read_word(fh);
        printf("%04x\n", raw[i]);
    }

    free(raw);

    fclose(fh);
}