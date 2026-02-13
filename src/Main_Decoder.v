// ======================================================================
// Main Decoder for RV32I
// Author: Prabhat Pandey
//
// Decodes opcode -> high level control signals
//
// Supported instruction groups:
//   - Loads      (LW)
//   - Stores     (SW)
//   - R-type     (ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA)
//   - I-type ALU (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI)
//   - Branch     (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//   - JAL, JALR
//   - LUI, AUIPC
//
// ResultSrc encoding:
//   00 -> ALUResult
//   01 -> MemReadData
//   10 -> PC+4   (for JAL/JALR)
//   11 -> Imm    (for LUI)
// ======================================================================

module Main_Decoder(
    input  [6:0] Op,

    output       RegWrite,
    output [1:0] ImmSrc,
    output       ALUSrc,
    output       MemWrite,
    output [1:0] ResultSrc,
    output       Branch,
    output [1:0] ALUOp,
    output       Jump
);

    // ----------------------------
    // Opcode values (RV32I)
    // ----------------------------
    localparam [6:0] OP_LOAD   = 7'b0000011; // LW
    localparam [6:0] OP_STORE  = 7'b0100011; // SW
    localparam [6:0] OP_RTYPE  = 7'b0110011; // ADD/SUB/...
    localparam [6:0] OP_ITYPE  = 7'b0010011; // ADDI/ANDI/...
    localparam [6:0] OP_BRANCH = 7'b1100011; // BEQ/BNE/...
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;

    // ----------------------------
    // RegWrite
    // ----------------------------
    assign RegWrite =
        (Op == OP_LOAD)  ||
        (Op == OP_RTYPE) ||
        (Op == OP_ITYPE) ||
        (Op == OP_JAL)   ||
        (Op == OP_JALR)  ||
        (Op == OP_LUI)   ||
        (Op == OP_AUIPC);

    // ----------------------------
    // ImmSrc
    //   00 -> I-type
    //   01 -> S-type
    //   10 -> B-type
    //   11 -> J/U type (depends on your ImmGen design)
    // ----------------------------
    assign ImmSrc =
        (Op == OP_STORE)  ? 2'b01 :
        (Op == OP_BRANCH) ? 2'b10 :
        (Op == OP_JAL)    ? 2'b11 :
        (Op == OP_LUI)    ? 2'b11 :
        (Op == OP_AUIPC)  ? 2'b11 :
                            2'b00;

    // ----------------------------
    // ALUSrc
    //   1 -> use immediate as ALU B input
    //   0 -> use register B
    // ----------------------------
    assign ALUSrc =
        (Op == OP_LOAD)  ||
        (Op == OP_STORE) ||
        (Op == OP_ITYPE) ||
        (Op == OP_JALR)  ||
        (Op == OP_AUIPC);

    // ----------------------------
    // MemWrite (stores only)
    // ----------------------------
    assign MemWrite = (Op == OP_STORE);

    // ----------------------------
    // ResultSrc
    //   00 -> ALU
    //   01 -> Mem
    //   10 -> PC+4
    //   11 -> Imm (LUI)
    // ----------------------------
    assign ResultSrc =
        (Op == OP_LOAD) ? 2'b01 :
        (Op == OP_JAL)  ? 2'b10 :
        (Op == OP_JALR) ? 2'b10 :
        (Op == OP_LUI)  ? 2'b11 :
                          2'b00;

    // ----------------------------
    // Branch
    // ----------------------------
    assign Branch = (Op == OP_BRANCH);

    // ----------------------------
    // Jump (JAL/JALR)
    // ----------------------------
    assign Jump = (Op == OP_JAL) || (Op == OP_JALR);

    // ----------------------------
    // ALUOp (goes to ALUControl decoder)
    // 00 -> ADD (loads/stores default)
    // 01 -> Branch compare operations
    // 10 -> R-type uses funct3/funct7
    // 11 -> I-type uses funct3/funct7(imm[30]) for shifts
    // ----------------------------
    assign ALUOp =
        (Op == OP_RTYPE) ? 2'b10 :
        (Op == OP_BRANCH)? 2'b01 :
        (Op == OP_ITYPE) ? 2'b11 :
                           2'b00;

endmodule
