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
//   IMPORTANT (Physical Design Version):
//   - This version is written to be synthesis-friendly for RTL-to-GDS
//     flows (OpenLane / Yosys).
//   - Therefore, it DOES NOT use $readmemh or any file-based memory
//     initialization, because that is simulation-only and not ASIC-real.
//
//   The memory is modeled as a ROM-like array with combinational read.
//
// Key Points:
//   - Instructions are 32-bit wide (one word)
//   - RISC-V instructions are always 4-byte aligned
//   - Therefore, the memory is indexed using addr[31:2] (word address)
//
// Behavior:
//   - Combinational read: instr updates immediately with addr changes
//   - No write port (ROM behavior for instruction memory)
//
// Notes:
//   - In real silicon, IMEM would be a ROM / SRAM / instruction cache.
//   - In OpenLane demo flows, this can synthesize into a large mux/flop
//     structure unless replaced by a macro.
//
// Revision History:
//   - 17-Feb-2026 : Removed $readmemh for synthesis / physical design.
//   - 14-Feb-2026 : Initial version
//=====================================================================

module imem #(
    parameter MEM_DEPTH_WORDS = 1024                   // Total words in IMEM
)(
    input  wire [31:0] addr,                           // Byte address from PC
    output wire [31:0] instr                           // 32-bit instruction output
);

    //=================================================================
    // Instruction Memory Storage
    //=================================================================
    // Each entry is one 32-bit RISC-V instruction word.
    //=================================================================
    reg [31:0] mem [0:MEM_DEPTH_WORDS-1];

    //=================================================================
    // Optional: Default initialization to NOPs (synthesis-friendly)
    //=================================================================
    // NOTE:
    // - This is not how ASIC ROM works in real silicon.
    // - But it avoids X-propagation in simulation.
    // - It is also accepted by most synthesis tools.
    //
    // NOP in RV32I = addi x0, x0, 0 = 32'h00000013
    //=================================================================
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH_WORDS; i = i + 1)
            mem[i] = 32'h0000_0013;
    end

    //=================================================================
    // Address Mapping (Word Addressing)
    //=================================================================
    // Index = PC / 4 = addr[31:2]
    // We keep only the lower bits required to index MEM_DEPTH_WORDS.
    //=================================================================
    wire [$clog2(MEM_DEPTH_WORDS)-1:0] word_index;
    assign word_index = addr[($clog2(MEM_DEPTH_WORDS)+1):2];

    //=================================================================
    // Combinational Read Output
    //=================================================================
    assign instr = mem[word_index];

endmodule
