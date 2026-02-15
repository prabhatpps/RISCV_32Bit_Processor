//=====================================================================
// File        : imm_gen.v
// Author      : Prabhat Pandey
// Created On  : 13-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : imm_gen
// Description :
//   This module implements the Immediate Generator for an RV32I
//   single-cycle RISC-V processor.
//
//   RISC-V uses multiple instruction formats, and each format encodes
//   an immediate value differently. This module extracts the immediate
//   field from the 32-bit instruction and sign-extends it to 32 bits.
//
// Supported Immediate Formats (RV32I):
//   1) I-type (e.g., addi, lw, jalr)
//   2) S-type (e.g., sw)
//   3) B-type (e.g., beq, bne, blt, bge, bltu, bgeu)
//   4) U-type (e.g., lui, auipc)
//   5) J-type (e.g., jal)
//
// Output:
//   - imm_out: 32-bit sign-extended immediate for the instruction.
//
// Notes:
//   - For B-type and J-type, the immediate represents a byte offset,
//     so bit0 is always 0 (immediate is shifted left by 1).
//   - For U-type, the immediate is upper 20 bits shifted left by 12.
//   - The immediate selection is done using opcode.
//
// Why use opcode?
//   Because instruction format is uniquely determined by opcode.
//
// Revision History:
//   - 13-Feb-2026 : Initial version
//=====================================================================

module imm_gen (
    input  wire [31:0] instr,     // Full 32-bit instruction
    output reg  [31:0] imm_out     // Generated 32-bit immediate
);

    //=================================================================
    // Extract opcode for instruction format selection
    //=================================================================
    wire [6:0] opcode;
    assign opcode = instr[6:0];

    //=================================================================
    // Immediate Generation (Combinational)
    //=================================================================
    // Based on opcode, extract correct immediate bits and sign extend.
    //=================================================================
    always @(*) begin
        case (opcode)

            // ---------------------------------------------------------
            // I-type immediate (12-bit signed)
            // Used by:
            //   - OP-IMM (addi, andi, ori, xori, slti, sltiu, slli, srli, srai)
            //   - LOAD (lw)
            //   - JALR
            // ---------------------------------------------------------
            7'b0010011, // OP-IMM
            7'b0000011, // LOAD
            7'b1100111: // JALR
            begin
                // imm[11:0] = instr[31:20]
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            // ---------------------------------------------------------
            // S-type immediate (12-bit signed)
            // Used by:
            //   - STORE (sw)
            // ---------------------------------------------------------
            7'b0100011: begin
                // imm[11:5] = instr[31:25]
                // imm[4:0]  = instr[11:7]
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // ---------------------------------------------------------
            // B-type immediate (13-bit signed, shifted left by 1)
            // Used by:
            //   - BRANCH (beq, bne, blt, bge, bltu, bgeu)
            //
            // Encoding:
            //   imm[12]   = instr[31]
            //   imm[10:5] = instr[30:25]
            //   imm[4:1]  = instr[11:8]
            //   imm[11]   = instr[7]
            //   imm[0]    = 0
            // ---------------------------------------------------------
            7'b1100011: begin
                imm_out = {
                    {19{instr[31]}},   // sign extension
                    instr[31],         // imm[12]
                    instr[7],          // imm[11]
                    instr[30:25],      // imm[10:5]
                    instr[11:8],       // imm[4:1]
                    1'b0               // imm[0]
                };
            end

            // ---------------------------------------------------------
            // U-type immediate (upper 20 bits, shifted left by 12)
            // Used by:
            //   - LUI
            //   - AUIPC
            // ---------------------------------------------------------
            7'b0110111, // LUI
            7'b0010111: // AUIPC
            begin
                imm_out = {instr[31:12], 12'b0};
            end

            // ---------------------------------------------------------
            // J-type immediate (21-bit signed, shifted left by 1)
            // Used by:
            //   - JAL
            //
            // Encoding:
            //   imm[20]   = instr[31]
            //   imm[10:1] = instr[30:21]
            //   imm[11]   = instr[20]
            //   imm[19:12]= instr[19:12]
            //   imm[0]    = 0
            // ---------------------------------------------------------
            7'b1101111: begin
                imm_out = {
                    {11{instr[31]}},   // sign extension
                    instr[31],         // imm[20]
                    instr[19:12],      // imm[19:12]
                    instr[20],         // imm[11]
                    instr[30:21],      // imm[10:1]
                    1'b0               // imm[0]
                };
            end

            // ---------------------------------------------------------
            // Default case
            // ---------------------------------------------------------
            default: begin
                imm_out = 32'h0000_0000;
            end

        endcase
    end

endmodule
