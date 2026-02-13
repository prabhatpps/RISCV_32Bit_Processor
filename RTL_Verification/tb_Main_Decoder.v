// ============================================================================
// Testbench for Main Decoder (RV32I - Minimal Subset)
// Author: Prabhat Pandey
//
// This testbench verifies:
//   - RegWrite
//   - ImmSrc
//   - ALUSrc
//   - MemWrite
//   - ResultSrc
//   - Branch
//   - ALUOp
//
// It covers all opcode cases implemented in the current Main_Decoder.
// ============================================================================

`timescale 1ns/1ps

module tb_Main_Decoder;

    // -----------------------------
    // DUT Inputs
    // -----------------------------
    reg [6:0] Op;

    // -----------------------------
    // DUT Outputs
    // -----------------------------
    wire       RegWrite;
    wire [1:0] ImmSrc;
    wire       ALUSrc;
    wire       MemWrite;
    wire [1:0] ResultSrc;
    wire       Branch;
    wire [1:0] ALUOp;

    // -----------------------------
    // Counters
    // -----------------------------
    integer pass_count = 0;
    integer fail_count = 0;

    // -----------------------------
    // Instantiate DUT
    // -----------------------------
    Main_Decoder dut (
        .Op(Op),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    // ============================================================
    // Full Check Task
    // ============================================================
    task check;
        input [6:0]  exp_op;
        input        exp_RegWrite;
        input [1:0]  exp_ImmSrc;
        input        exp_ALUSrc;
        input        exp_MemWrite;
        input        exp_ResultSrc;
        input        exp_Branch;
        input [1:0]  exp_ALUOp;
        input [255:0] msg;
        begin
            Op = exp_op;
            #1;

            $display("----------------------------------------------------------------");
            $display("TEST : %s", msg);
            $display("Inputs:");
            $display("   Op = %b", Op);

            $display("\nExpected:");
            $display("   RegWrite  = %b", exp_RegWrite);
            $display("   ImmSrc    = %b", exp_ImmSrc);
            $display("   ALUSrc    = %b", exp_ALUSrc);
            $display("   MemWrite  = %b", exp_MemWrite);
            $display("   ResultSrc = %b", exp_ResultSrc);
            $display("   Branch    = %b", exp_Branch);
            $display("   ALUOp     = %b", exp_ALUOp);

            $display("\nGot:");
            $display("   RegWrite  = %b", RegWrite);
            $display("   ImmSrc    = %b", ImmSrc);
            $display("   ALUSrc    = %b", ALUSrc);
            $display("   MemWrite  = %b", MemWrite);
            $display("   ResultSrc = %b", ResultSrc);
            $display("   Branch    = %b", Branch);
            $display("   ALUOp     = %b", ALUOp);

            if (RegWrite  === exp_RegWrite &&
                ImmSrc    === exp_ImmSrc   &&
                ALUSrc    === exp_ALUSrc   &&
                MemWrite  === exp_MemWrite &&
                ResultSrc === exp_ResultSrc&&
                Branch    === exp_Branch   &&
                ALUOp     === exp_ALUOp)
            begin
                $display("STATUS: PASS");
                pass_count = pass_count + 1;
            end
            else begin
                $display("STATUS: FAIL");
                fail_count = fail_count + 1;
            end

            $display("----------------------------------------------------------------\n");
        end
    endtask


    // ============================================================
    // Testcases
    // ============================================================
    initial begin
        $display("====================================================");
        $display(" MAIN DECODER VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================\n");

        // ----------------------------------------------------------
        // LOAD (0000011)
        // Expected:
        //   RegWrite  = 1
        //   ImmSrc    = 00 (I-type)
        //   ALUSrc    = 1
        //   MemWrite  = 0
        //   ResultSrc = 1 (from memory)
        //   Branch    = 0
        //   ALUOp     = 00 (ADD)
        // ----------------------------------------------------------
        check(7'b0000011, 1, 2'b00, 1, 0, 1, 0, 2'b00, "LOAD (LW)");

        // ----------------------------------------------------------
        // STORE (0100011)
        // Expected:
        //   RegWrite  = 0
        //   ImmSrc    = 01 (S-type)
        //   ALUSrc    = 1
        //   MemWrite  = 1
        //   ResultSrc = 0 (don't care)
        //   Branch    = 0
        //   ALUOp     = 00 (ADD)
        // ----------------------------------------------------------
        check(7'b0100011, 0, 2'b01, 1, 1, 0, 0, 2'b00, "STORE (SW)");

        // ----------------------------------------------------------
        // R-TYPE (0110011)
        // Expected:
        //   RegWrite  = 1
        //   ImmSrc    = 00
        //   ALUSrc    = 0
        //   MemWrite  = 0
        //   ResultSrc = 0 (from ALU)
        //   Branch    = 0
        //   ALUOp     = 10 (funct decode)
        // ----------------------------------------------------------
        check(7'b0110011, 1, 2'b00, 0, 0, 0, 0, 2'b10, "R-TYPE ALU");

        // ----------------------------------------------------------
        // BRANCH (1100011)
        // Expected:
        //   RegWrite  = 0
        //   ImmSrc    = 10 (B-type)
        //   ALUSrc    = 0
        //   MemWrite  = 0
        //   ResultSrc = 0
        //   Branch    = 1
        //   ALUOp     = 01 (branch compare)
        // ----------------------------------------------------------
        check(7'b1100011, 0, 2'b10, 0, 0, 0, 1, 2'b01, "BRANCH");

        // ----------------------------------------------------------
        // ILLEGAL / UNSUPPORTED OPCODE
        // Expected:
        //   Everything default safe
        // ----------------------------------------------------------
        check(7'b1111111, 0, 2'b00, 0, 0, 0, 0, 2'b00, "ILLEGAL opcode");

        // ============================================================
        // FINAL REPORT
        // ============================================================
        $display("\n====================================================");
        $display(" MAIN DECODER VERIFICATION REPORT");
        $display("====================================================");
        $display("   Total Tests   : %0d", pass_count + fail_count);
        $display("   Passed        : %0d", pass_count);
        $display("   Failed        : %0d", fail_count);
        $display("====================================================");

        if (fail_count == 0)
            $display("STATUS: ALL TESTS PASSED");
        else
            $display("STATUS: SOME TESTS FAILED");

        $display("====================================================\n");

        $finish;
    end

endmodule
