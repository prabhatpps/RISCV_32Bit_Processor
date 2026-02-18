//=====================================================================
// File        : riscv32_singlecycle_top.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : riscv32_singlecycle_top
// Description :
//   ASIC / Physical-Design friendly top-level module for the RV32I
//   single-cycle CPU core.
//
//   This version is created specifically for RTL-to-GDS flow using
//   OpenLane / Sky130.
//
//   IMPORTANT CHANGE:
//   ------------------------------------------------------------
//   - IMEM and DMEM are removed from inside the core.
//   - Instruction input comes from external memory:
//         instr (input)
//   - Data memory interface is exposed as external ports:
//         mem_read, mem_write, mem_addr, mem_wdata, mem_rdata
//
//   This makes the CPU core synthesizable and realistic for ASIC,
//   because SRAM macros (or ROM) must be instantiated separately.
//
// Modules included:
//   - pc_reg
//   - decoder_controller
//   - regfile
//   - imm_gen
//   - alu_control
//   - alu
//   - branch_unit
//   - pc_next_logic
//   - wb_mux
//
// Notes:
//   - Single-cycle CPU: fetch/decode/execute/mem/wb in one cycle.
//   - This module assumes instruction is stable for the cycle.
//   - Reset clears PC and regfile.
//
// Revision History:
//   - 18-Feb-2026 : Completly removed memory blocks for a PD-friendly core top
//   - 17-Feb-2026 : Updated IMEM/DMEM integration for synthesis-friendly RTL
//   - 16-Feb-2026 : Corrected regfile + imm_gen port integration
//   - 16-Feb-2026 : Initial version
//=====================================================================

module riscv32_singlecycle_top (
    input  wire        clk,
    input  wire        rst_n,

    //=============================================================
    // Instruction Memory Interface (Read-only)
    //=============================================================
    output wire [31:0] imem_addr,     // address = PC
    input  wire [31:0] imem_rdata,    // instruction word from IMEM

    //=============================================================
    // Data Memory Interface (LW/SW)
    //=============================================================
    output wire        dmem_read_en,
    output wire        dmem_write_en,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata
);

    //=============================================================
    // 1) Program Counter (PC)
    //=============================================================
    wire [31:0] pc_current;
    wire [31:0] pc_next;

    pc_reg u_pc_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    //=============================================================
    // 2) Instruction Fetch (External IMEM)
    //=============================================================
    assign imem_addr = pc_current;

    wire [31:0] instr;
    assign instr = imem_rdata;

    //=============================================================
    // 3) Extract instruction fields
    //=============================================================
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    //=============================================================
    // 4) Controller (Main Decoder)
    //=============================================================
    wire        reg_write;
    wire [2:0]  wb_sel;

    wire        alu_src;
    wire [1:0]  alu_op;
    wire        use_pc_as_alu_a;

    wire        mem_read;
    wire        mem_write;

    wire        branch;
    wire        jump;
    wire        jalr;

    decoder_controller u_decoder_controller (
        .opcode           (opcode),
        .funct3           (funct3),
        .funct7           (funct7),

        .reg_write        (reg_write),
        .wb_sel           (wb_sel),

        .alu_src          (alu_src),
        .alu_op           (alu_op),
        .use_pc_as_alu_a  (use_pc_as_alu_a),

        .mem_read         (mem_read),
        .mem_write        (mem_write),

        .branch           (branch),
        .jump             (jump),
        .jalr             (jalr)
    );

    //=============================================================
    // 5) Register File
    //=============================================================
    wire [31:0] rs1_val;
    wire [31:0] rs2_val;
    wire [31:0] wb_data;

    regfile u_regfile (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (reg_write),
        .rs1   (rs1),
        .rs2   (rs2),
        .rd    (rd),
        .wd    (wb_data),
        .rd1   (rs1_val),
        .rd2   (rs2_val)
    );

    //=============================================================
    // 6) Immediate Generator
    //=============================================================
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;

    imm_gen u_imm_gen (
        .instr (instr),
        .imm_i (imm_i),
        .imm_s (imm_s),
        .imm_b (imm_b),
        .imm_u (imm_u),
        .imm_j (imm_j)
    );

    //=============================================================
    // 7) ALU Control
    //=============================================================
    wire [3:0] alu_ctrl;

    alu_control u_alu_control (
        .alu_op   (alu_op),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
    );

    //=============================================================
    // 8) ALU Operand Selection
    //=============================================================
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;

    assign alu_in_a = (use_pc_as_alu_a) ? pc_current : rs1_val;

    wire [31:0] selected_imm;
    assign selected_imm =
        (opcode == 7'b0100011) ? imm_s : // STORE
                                imm_i;  // LOAD, OP-IMM, JALR

    assign alu_in_b = (alu_src) ? selected_imm : rs2_val;

    //=============================================================
    // 9) ALU Execution
    //=============================================================
    wire [31:0] alu_result;
    wire        alu_zero;
    wire        alu_negative;
    wire        alu_carry;
    wire        alu_overflow;

    alu u_alu (
        .A          (alu_in_a),
        .B          (alu_in_b),
        .ALUControl (alu_ctrl),
        .Result     (alu_result),
        .Carry      (alu_carry),
        .OverFlow   (alu_overflow),
        .Zero       (alu_zero),
        .Negative   (alu_negative)
    );

    //=============================================================
    // 10) Branch Unit
    //=============================================================
    wire take_branch;

    branch_unit u_branch_unit (
        .funct3      (funct3),
        .rs1_val     (rs1_val),
        .rs2_val     (rs2_val),
        .take_branch (take_branch)
    );

    //=============================================================
    // 11) External DMEM wiring
    //=============================================================
    assign dmem_read_en  = mem_read;
    assign dmem_write_en = mem_write;
    assign dmem_addr     = alu_result;
    assign dmem_wdata    = rs2_val;

    wire [31:0] mem_data;
    assign mem_data = dmem_rdata;

    //=============================================================
    // 12) PC Next Logic
    //=============================================================
    wire [31:0] pc_plus4;

    pc_next_logic u_pc_next_logic (
        .pc_current  (pc_current),
        .rs1_val     (rs1_val),
        .imm_i       (imm_i),
        .imm_b       (imm_b),
        .imm_j       (imm_j),
        .branch      (branch),
        .take_branch (take_branch),
        .jump        (jump),
        .jalr        (jalr),
        .pc_next     (pc_next),
        .pc_plus4    (pc_plus4)
    );

    //=============================================================
    // 13) Writeback Mux
    //=============================================================
    wire [31:0] pc_plus_imm_u;
    assign pc_plus_imm_u = pc_current + imm_u;

    wb_mux u_wb_mux (
        .wb_sel      (wb_sel),
        .alu_result  (alu_result),
        .mem_data    (mem_data),
        .pc_plus4    (pc_plus4),
        .u_imm       (imm_u),
        .pc_plus_imm (pc_plus_imm_u),
        .wb_data     (wb_data)
    );

endmodule
