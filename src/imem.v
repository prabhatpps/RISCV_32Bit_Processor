//=====================================================================
// File        : imem.v
// Author      : Prabhat Pandey
// Created On  : 14-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : imem
// Description :
//   This module implements Instruction Memory (IMEM) for an RV32
//   single-cycle RISC-V processor.
//
//   The instruction memory is modeled as a ROM-like array initialized
//   using $readmemh from a HEX file.
//
//   Key Points:
//   - Instructions are 32-bit wide (one word)
//   - RISC-V instructions are always 4-byte aligned
//   - Therefore, the memory is indexed using addr[31:2] (word address)
//
// Behavior:
//   - Combinational read: instr updates immediately with addr changes
//   - No write port (ROM behavior for instruction memory)
//
// Notes:
//   - This is perfect for simulation and FPGA-style ROM.
//   - For ASIC, IMEM would be replaced by a real ROM or instruction cache.
//
// File Format for $readmemh:
//   Each line should contain ONE 32-bit instruction in HEX.
//   Example (program.hex):
//      00000013   // NOP  (addi x0, x0, 0)
//      00100093   // addi x1, x0, 1
//
// Revision History:
//   - 14-Feb-2026 : Initial version
//=====================================================================

module imem #(
    parameter MEM_DEPTH_WORDS = 1024,                  // Total words in IMEM
    parameter MEM_INIT_FILE   = "program.hex"          // HEX file for initialization
)(
    input  wire [31:0] addr,                           // Byte address from PC
    output wire [31:0] instr                           // 32-bit instruction output
);

    //=================================================================
    // Instruction Memory Storage
    //=================================================================
    // Each entry is one 32-bit RISC-V instruction word.
    // MEM_DEPTH_WORDS = number of 32-bit words.
    //=================================================================
    reg [31:0] mem [0:MEM_DEPTH_WORDS-1];

    //=================================================================
    // Memory Initialization
    //=================================================================
    // Loads instruction words from a hex file at simulation start.
    // If file is missing, IMEM will contain X/unknown values.
    //=================================================================
    initial begin
        $readmemh(MEM_INIT_FILE, mem);
    end

    //=================================================================
    // Address Mapping (Word Addressing)
    //=================================================================
    // RISC-V instructions are 4-byte aligned.
    // So:
    //   PC = byte address
    //   Index = PC / 4 = PC[31:2]
    //=================================================================
    wire [$clog2(MEM_DEPTH_WORDS)-1:0] word_index;
    assign word_index = addr[31:2];

    //=================================================================
    // Combinational Read Output
    //=================================================================
    // Reads instruction directly from memory.
    // No clock required (ROM-like).
    //=================================================================
    assign instr = mem[word_index];

endmodule
