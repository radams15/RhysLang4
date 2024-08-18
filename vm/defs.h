//
// Created by rhys on 03/08/24.
//

#ifndef DEFS_H
#define DEFS_H


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

typedef enum ArgType {
    ARG_REG = 0x0,
    ARG_INT = 0x1
} ArgType_t;

typedef enum Register {
    REG_A = 0x0,
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

typedef struct __attribute__((__packed__)) Arg {
    uint16_t val;
    int8_t offset;
    uint8_t type;
    uint8_t addr;
} Arg_t;

typedef struct __attribute__((__packed__)) Op {
    uint8_t code;
    uint8_t n_args;
    Arg_t arg1;
    Arg_t arg2;
    Arg_t arg3;
} Op_t;

#endif //DEFS_H
