#define OP_NOOP 0x00
#define OP_PUSH 0x01
#define OP_CLEAR 0x02
#define OP_DROP 0x03
#define OP_LDVAL 0x04
#define OP_LDADDR 0x05
#define OP_LDLREF 0x06
#define OP_LDGLOB 0x07
#define OP_LDLOCL 0x08
#define OP_STGLOB 0x09
#define OP_STLOCL 0x0a
#define OP_STINDR 0x0b
#define OP_STINDB 0x0c
#define OP_INCGLOB 0x0d
#define OP_INCLOCL 0x0e
#define OP_INCR 0x0f
#define OP_STACK 0x10
#define OP_UNSTACK 0x11
#define OP_LOCLVEC 0x12
#define OP_GLOBVEC 0x13
#define OP_INDEX 0x14
#define OP_DEREF 0x15
#define OP_INDXB 0x16
#define OP_DREFB 0x17
#define OP_CALL 0x18
#define OP_CALR 0x19
#define OP_JUMP 0x1a
#define OP_RJUMP 0x1b
#define OP_JMPFALSE 0x1c
#define OP_JMPTRUE 0x1d
#define OP_FOR 0x1e
#define OP_FORDOWN 0x1f
#define OP_MKFRAME 0x20
#define OP_DELFRAME 0x21
#define OP_RET 0x22
#define OP_HALT 0x23
#define OP_NEG 0x24
#define OP_INV 0x25
#define OP_LOGNOT 0x26
#define OP_ADD 0x27
#define OP_SUB 0x28
#define OP_MUL 0x29
#define OP_DIV 0x2a
#define OP_MOD 0x2b
#define OP_AND 0x2c
#define OP_OR 0x2d
#define OP_XOR 0x2e
#define OP_SHL 0x2f
#define OP_SHR 0x30
#define OP_EQ 0x31
#define OP_NE 0x32
#define OP_LT 0x33
#define OP_GT 0x34
#define OP_LE 0x35
#define OP_GE 0x36
#define OP_UMUL 0x37
#define OP_UDIV 0x38
#define OP_ULT 0x39
#define OP_UGT 0x3a
#define OP_ULE 0x3b
#define OP_UGE 0x3c
#define OP_SKIP 0x3d
#define OP_POP 0x3e
#define OP_SCALL 0x3f

const char* lookup[] = {
    "NOOP",
    "PUSH",
    "CLEAR",
    "DROP",
    "LDVAL",
    "LDADDR",
    "LDLREF",
    "LDGLOB",
    "LDLOCL",
    "STGLOB",
    "STLOCL",
    "STINDR",
    "STINDB",
    "INCGLOB",
    "INCLOCL",
    "INCR",
    "STACK",
    "UNSTACK",
    "LOCLVEC",
    "GLOBVEC",
    "INDEX",
    "DEREF",
    "INDXB",
    "DREFB",
    "CALL",
    "CALR",
    "JUMP",
    "RJUMP",
    "JMPFALSE",
    "JMPTRUE",
    "FOR",
    "FORDOWN",
    "MKFRAME",
    "DELFRAME",
    "RET",
    "HALT",
    "NEG",
    "INV",
    "LOGNOT",
    "ADD",
    "SUB",
    "MUL",
    "DIV",
    "MOD",
    "AND",
    "OR",
    "XOR",
    "SHL",
    "SHR",
    "EQ",
    "NE",
    "LT",
    "GT",
    "LE",
    "GE",
    "UMUL",
    "UDIV",
    "ULT",
    "UGT",
    "ULE",
    "UGE",
    "SKIP",
    "POP",
    "SCALL"
};
