//=====================================================================
// File        : regfile.v
// Author      : Prabhat Pandey
// Created On  : 13-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : regfile
// Description :
//   This module implements the RISC-V integer register file for RV32.
//
//   RISC-V RV32 register file properties:
//     - 32 registers, each 32-bit wide
//     - Two combinational read ports (rs1, rs2)
//     - One synchronous write port (rd)
//     - Register x0 is hardwired to zero (reads always return 0,
//       writes to x0 are ignored)
//
// Interface:
//   Inputs:
//     - clk        : clock for synchronous write
//     - we         : write enable
//     - rs1, rs2   : source register indices
//     - rd         : destination register index
//     - wd         : write data
//
//   Outputs:
//     - rd1        : read data for rs1
//     - rd2        : read data for rs2
//
// Behavior:
//   - Reads are combinational (asynchronous):
//       rd1 = regs[rs1], rd2 = regs[rs2]
//   - Writes happen on rising edge of clk when we=1 and rd != 0.
//   - x0 always stays 0.
//
// Notes:
//   - This is the standard regfile style used in most single-cycle CPUs.
//   - For ASIC, this would map to a multiport SRAM/register array.
//   - No reset is required (RISC-V does not require registers to reset),
//     but x0 is always forced to 0.
//
// Revision History:
//   - 13-Feb-2026 : Initial version
//=====================================================================

module regfile (
    input  wire        clk,      // Clock input (positive-edge triggered)
    input  wire        we,       // Write enable
    input  wire [4:0]  rs1,      // Source register 1 index
    input  wire [4:0]  rs2,      // Source register 2 index
    input  wire [4:0]  rd,       // Destination register index
    input  wire [31:0] wd,       // Write data
    output wire [31:0] rd1,      // Read data from rs1
    output wire [31:0] rd2       // Read data from rs2
);

    //=================================================================
    // Register Storage
    //=================================================================
    // regs[0]  = x0 (hardwired zero)
    // regs[1]  = x1
    // ...
    // regs[31] = x31
    //=================================================================
    reg [31:0] regs [0:31];

    integer i;

    //=================================================================
    // Optional Initialization (Simulation Friendly)
    //=================================================================
    // For simulation, it's useful to initialize regs to 0 so you don't
    // see X values everywhere.
    //
    // This is NOT required for synthesis, but it is harmless in most
    // FPGA flows. In ASIC, initialization is typically not supported.
    //=================================================================
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'h0000_0000;
        end
    end

    //=================================================================
    // Combinational Read Ports
    //=================================================================
    // RISC-V rule:
    //   Reading x0 always returns 0.
    //=================================================================
    assign rd1 = (rs1 == 5'd0) ? 32'h0000_0000 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'h0000_0000 : regs[rs2];

    //=================================================================
    // Synchronous Write Port
    //=================================================================
    // Write occurs on posedge clk when:
    //   - we = 1
    //   - rd != 0 (ignore writes to x0)
    //
    // Also we enforce regs[0] = 0 always.
    //=================================================================
    always @(posedge clk) begin
        if (we && (rd != 5'd0)) begin
            regs[rd] <= wd;
        end

        // Enforce x0 = 0 always (safety net)
        regs[0] <= 32'h0000_0000;
    end

endmodule
