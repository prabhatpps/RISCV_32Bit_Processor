## Appendix A: Instruction Encoding Reference

### R-Type Format
```
31        25 24    20 19    15 14    12 11     7 6      0
┌───────────┬────────┬────────┬────────┬────────┬────────┐
│  funct7   │   rs2  │   rs1  │ funct3 │   rd   │ opcode │
└───────────┴────────┴────────┴────────┴────────┴────────┘
    7 bits     5 bits   5 bits   3 bits   5 bits   7 bits
```

**Examples:**
- ADD:  `funct7=0000000, funct3=000, opcode=0110011`
- SUB:  `funct7=0100000, funct3=000, opcode=0110011`
- SLL:  `funct7=0000000, funct3=001, opcode=0110011`

### I-Type Format
```
31                    20 19    15 14    12 11     7 6      0
┌────────────────────────┬────────┬────────┬────────┬────────┐
│       imm[11:0]        │   rs1  │ funct3 │   rd   │ opcode │
└────────────────────────┴────────┴────────┴────────┴────────┘
       12 bits              5 bits   3 bits   5 bits   7 bits
```

**Examples:**
- ADDI: `funct3=000, opcode=0010011`
- LW:   `funct3=010, opcode=0000011`
- JALR: `funct3=000, opcode=1100111`

### S-Type Format
```
31        25 24    20 19    15 14    12 11     7 6      0
┌───────────┬────────┬────────┬────────┬────────┬────────┐
│ imm[11:5] │   rs2  │   rs1  │ funct3 │imm[4:0]│ opcode │
└───────────┴────────┴────────┴────────┴────────┴────────┘
    7 bits     5 bits   5 bits   3 bits   5 bits   7 bits
```

**Example:**
- SW: `funct3=010, opcode=0100011`

### B-Type Format
```
    31    30      25 24    20 19    15 14    12 11     8    7    6         0
┌────────┬──────────┬────────┬────────┬────────┬────────┬───────┬───────────┐
│imm[12] │ imm[10:5]│   rs2  │   rs1  │ funct3 │imm[4:1]│imm[11]│  opcode   │
└────────┴──────────┴────────┴────────┴────────┴────────┴───────┴───────────┘

```

**Examples:**
- BEQ:  `funct3=000, opcode=1100011`
- BLT:  `funct3=100, opcode=1100011`
- BGEU: `funct3=111, opcode=1100011`

### U-Type Format
```
31                                   12 11     7 6      0
┌──────────────────────────────────────┬────────┬────────┐
│           imm[31:12]                 │   rd   │ opcode │
└──────────────────────────────────────┴────────┴────────┘
              20 bits                     5 bits   7 bits
```

**Examples:**
- LUI:   `opcode=0110111`
- AUIPC: `opcode=0010111`

### J-Type Format
```
    31    30          21   20    19                12 11     7 6      0
┌────────┬──────────────┬───────┬────────────────────┬────────┬────────┐
│imm[20] │  imm[10:1]   │imm[11]│   imm[19:12]       │   rd   │ opcode │
└────────┴──────────────┴───────┴────────────────────┴────────┴────────┘

```

**Example:**
- JAL: `opcode=1101111`

---

## Appendix B: Control Signal Truth Table

Complete control signal generation for all instruction types:

| Instruction | Opcode  | ALUOp | ALUSrc | MemRead | MemWrite | RegWrite | WBSel | Branch | Jump | JALR | use_pc_as_alu_a |
|-------------|---------|-------|--------|---------|----------|----------|-------|--------|------|------|-----------------|
| ADD         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SUB         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| AND         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| OR          | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| XOR         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLL         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SRL         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SRA         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLT         | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLTU        | 0110011 | 10    | 0      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| ADDI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| ANDI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| ORI         | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| XORI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLLI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SRLI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SRAI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLTI        | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| SLTIU       | 0010011 | 11    | 1      | 0       | 0        | 1        | 000   | 0      | 0    | 0    | 0               |
| LW          | 0000011 | 00    | 1      | 1       | 0        | 1        | 001   | 0      | 0    | 0    | 0               |
| SW          | 0100011 | 00    | 1      | 0       | 1        | 0        | xxx   | 0      | 0    | 0    | 0               |
| BEQ         | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| BNE         | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| BLT         | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| BGE         | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| BLTU        | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| BGEU        | 1100011 | 01    | 0      | 0       | 0        | 0        | xxx   | 1      | 0    | 0    | 0               |
| JAL         | 1101111 | 00    | 0      | 0       | 0        | 1        | 010   | 0      | 1    | 0    | 0               |
| JALR        | 1100111 | 00    | 1      | 0       | 0        | 1        | 010   | 0      | 0    | 1    | 0               |
| LUI         | 0110111 | 00    | 0      | 0       | 0        | 1        | 011   | 0      | 0    | 0    | 0               |
| AUIPC       | 0010111 | 00    | 1      | 0       | 0        | 1        | 100   | 0      | 0    | 0    | 1               |

---

## Appendix C: Sample Test Program

**Assembly Code (test_program.s):**

```assembly
# RV32I Test Program (Decoded from Given Machine Code)
# Tests: arithmetic, logic, shifts, load/store, branches, jumps

.text
.globl _start

_start:

    # NOP (Pipeline alignment / safe start)
    addi x0, x0, 0          # No operation

    # Test 1: Basic Arithmetic
    addi x1, x0, 10         # x1 = 10
    addi x2, x0, 20         # x2 = 20
    add  x3, x1, x2         # x3 = x1 + x2 = 30
    sub  x4, x1, x2         # x4 = x1 - x2 = -10

    # Test 2: Logical Operations
    andi x5, x7, 0xFF       # x5 = x7 & 0xFF (mask lower 8 bits)
    ori  x6, x2, 0xF0       # x6 = x2 | 0xF0
    xori x7, x5, 0x55       # x7 = x5 ^ 0x55

    # Test 3: Shifts
    slli x8, x1, 2          # x8 = x1 << 2
    srli x9, x3, 1          # x9 = x3 >> 1 (logical)

    # Test 4: Set Less Than
    slti  x10, x1, 15       # x10 = 1 if x1 < 15 else 0
    sltu  x11, x2, x25      # x11 = 1 if x2 < x25 (unsigned)

    # Test 5: Load/Store
    sw   x3, 0(x0)          # Store x3 at memory address 0
    lw   x12, 0(x0)         # Load from memory address 0 into x12

    # Test 6: Branch
    beq  x3, x12, jump_label  # Branch if equal
    addi x13, x0, 99        # Executed only if branch NOT taken

jump_label:

    # Test 7: Jump and Link
    jal  x15, next_section  # x15 = return address

next_section:

    # Test 8: Upper Immediate Instructions
    lui   x14, 0x12345      # x14 = 0x12345000
    auipc x16, 0            # x16 = current PC

    # End of Tests
    addi x17, x0, 1         # Success flag = 1

infinite_loop:
    beq x0, x0, infinite_loop   # Infinite loop
```

**Machine Code (program.hex):**

```
00000013
00a00093
01400113
002081b3
40208233
0ff3f293
0f016313
0552c393
00209413
0011d493
00f0a513
019135b3
00302023
00002603
00c18463
06300693
008007ef
12345737
00000817
00100893
fe0006e3
```

---

**Last Updated:** February 16, 2026