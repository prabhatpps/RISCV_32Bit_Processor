//=====================================================================
// File        : dmem.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : dmem
// Description :
//   This module implements Data Memory (DMEM) for an RV32I single-cycle
//   processor.
//
//   Supported operations:
//     - LW : Load word (32-bit read)
//     - SW : Store word (32-bit write)
//
//   IMPORTANT (Physical Design Version - Option B):
//   - This version is kept single-cycle friendly.
//   - Read is combinational so that LW completes in one cycle.
//   - Write is synchronous on posedge clk.
//
//   Physical Design Notes:
//   - $readmemh is removed (simulation-only).
//   - Out-of-range checks are removed (they create unnecessary logic).
//   - Memory indexing uses a clean, fixed-width word index.
//   - This will synthesize into mux + flop structures (not a true SRAM).
//
// Interface:
//   Inputs:
//     - clk       : clock (writes occur on posedge)
//     - mem_read  : when 1, read_data is valid (combinational)
//     - mem_write : when 1, write occurs on posedge clk
//     - addr      : 32-bit byte address (from ALU)
//     - write_data: 32-bit data to store (from rs2)
//
//   Outputs:
//     - read_data : 32-bit data loaded from memory
//
// Memory Organization:
//   - Word-addressed internally.
//   - Uses addr[31:2] as the word index (aligned accesses).
//
// Revision History:
//   - 17-Feb-2026 : Updated for synthesis / physical design:
//                   - Removed $readmemh
//                   - Made read synchronous
//                   - Cleaned indexing
//   - 16-Feb-2026 : Initial version
//=====================================================================

module dmem #(
    parameter DEPTH = 256                // Number of 32-bit words
)(
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,             // Byte address
    input  wire [31:0] write_data,       // Data to store
    output wire [31:0] read_data         // Combinational read output
);

    //=================================================================
    // Memory array (word-addressed)
    //=================================================================
    reg [31:0] mem [0:DEPTH-1];

    //=================================================================
    // Default initialization (synthesis-friendly)
    //=================================================================
    // NOTE:
    // - In ASIC, SRAM contents are not guaranteed after power-up.
    // - This is included mainly to avoid X propagation in simulation.
    //=================================================================
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h0000_0000;
    end

    //=================================================================
    // Word index extraction (clean width)
    //=================================================================
    // addr is byte address.
    // word_index = addr / 4.
    // Keep only bits required for DEPTH.
    //=================================================================
    wire [$clog2(DEPTH)-1:0] word_index;
    assign word_index = addr[($clog2(DEPTH)+1):2];

    //=================================================================
    // Combinational read (single-cycle LW support)
    //=================================================================
    assign read_data = (mem_read) ? mem[word_index] : 32'h0000_0000;

    //=================================================================
    // Synchronous write (posedge)
    //=================================================================
    always @(posedge clk) begin
        if (mem_write) begin
            mem[word_index] <= write_data;
        end
    end

endmodule