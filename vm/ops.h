#ifndef VM_OPS_H
#define VM_OPS_H

typedef enum Opcode {
    OP_BR = 0,
    OP_ADD1,
    OP_ADD2,
    OP_LD,
    OP_ST,
    OP_JSR,
    OP_AND,
    OP_LDR,
    OP_STR,
    OP_RTI,
    OP_NOT,
    OP_LDI,
    OP_STI,
    OP_JMP,
    OP_NOOP,
    OP_LEA,
    OP_TRAP,
    OP_PUSH,
    OP_POP,
    OP_HALT
} Opcode_t;

typedef enum Register {
    R0 = 0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    RPC,
    RCND,
    RSP,
    RBP,
    RCNT
} Register_t;

typedef enum Trap {
    TRP_IN_U16 = 0,
    TRP_OUT_U16
} Trap_t;

#endif
