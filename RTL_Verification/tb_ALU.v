// ============================================================================
// Testbench for 32-bit ALU (RV32I)
// Author: Prabhat Pandey
//
// Features:
//   ✔ FULL result + flag checking
//   ✔ Prints A, B, ALUControl, result, flags
//   ✔ Prints expected values
//   ✔ PASS / FAIL message per test
//   ✔ Global counters for passed/failed tests
//   ✔ Final verification report
// ============================================================================

`timescale 1ns/1ps

module tb_ALU;

    reg  [31:0] A, B;
    reg  [3:0]  ALUControl;
    wire        Carry, OverFlow, Zero, Negative;
    wire [31:0] Result;

    integer pass_count = 0;
    integer fail_count = 0;

    // -------------------------
    // Instantiate ALU
    // -------------------------
    ALU dut (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .Carry(Carry),
        .OverFlow(OverFlow),
        .Zero(Zero),
        .Negative(Negative),
        .Result(Result)
    );

    // ============================================================
    // Full Verification Task
    // ============================================================
    task check;
        input [31:0] exp_result;
        input        exp_carry;
        input        exp_overflow;
        input        exp_zero;
        input        exp_negative;
        input [255:0] msg;
        begin
            #1;

            $display("----------------------------------------------------------------");
            $display("TEST : %s", msg);
            $display("Inputs:");
            $display("   A          = %h", A);
            $display("   B          = %h", B);
            $display("   ALUControl = %b", ALUControl);

            $display("\nExpected:");
            $display("   Result     = %h", exp_result);
            $display("   Carry      = %b", exp_carry);
            $display("   OverFlow   = %b", exp_overflow);
            $display("   Zero       = %b", exp_zero);
            $display("   Negative   = %b", exp_negative);

            $display("\nGot:");
            $display("   Result     = %h", Result);
            $display("   Carry      = %b", Carry);
            $display("   OverFlow   = %b", OverFlow);
            $display("   Zero       = %b", Zero);
            $display("   Negative   = %b", Negative);

            if (Result     === exp_result &&
                Carry      === exp_carry &&
                OverFlow   === exp_overflow &&
                Zero       === exp_zero &&
                Negative   === exp_negative)
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
    // Testbench Stimulus
    // ============================================================
    initial begin
        $display("====================================================");
        $display(" ALU VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================\n");

        // ----------------------------------------------------------
        // ADD (0000)
        // ----------------------------------------------------------
        ALUControl = 4'b0000;

        A = 5; B = 7;
        check(12, 0, 0, 0, 0, "ADD basic");

        A = 32'hFFFFFFFF; B = 1;
        check(32'h00000000, 1, 0, 1, 0, "ADD wrap");

        A = 32'h7FFFFFFF; B = 1;
        check(32'h80000000, 0, 1, 0, 1, "ADD signed overflow");


        // ----------------------------------------------------------
        // SUB (0001)
        // ----------------------------------------------------------
        ALUControl = 4'b0001;

        A = 20; B = 7;
        check(13, 1, 0, 0, 0, "SUB basic");

        A = 7; B = 20;
        check(32'hfffffff3, 0, 0, 0, 1, "SUB negative result");

        A = 32'h80000000; B = 1;
        check(32'h7fffffff, 1, 1, 0, 0, "SUB signed overflow");


        // ----------------------------------------------------------
        // AND (0010)
        // ----------------------------------------------------------
        ALUControl = 4'b0010;

        A = 32'hF0F0F0F0; B = 32'h0FF00FF0;
        check(32'h00F000F0, 0, 0, 0, 0, "AND test");


        // ----------------------------------------------------------
        // OR (0011)
        // ----------------------------------------------------------
        ALUControl = 4'b0011;

        A = 32'hA5A5A5A5; B = 32'h0F0F0F0F;
        check(32'hAFAFAFAF, 0, 0, 0, 1, "OR test");


        // ----------------------------------------------------------
        // XOR (0100)
        // ----------------------------------------------------------
        ALUControl = 4'b0100;

        A = 32'hAAAAAAAA; B = 32'h55555555;
        check(32'hFFFFFFFF, 0, 0, 0, 1, "XOR test");


        // ----------------------------------------------------------
        // SLT (0101)
        // ----------------------------------------------------------
        ALUControl = 4'b0101;

        A = -5; B = 5;
        check(1, 0, 0, 0, 0, "SLT -5 < 5");

        A = 5; B = -5;
        check(0, 0, 0, 1, 0, "SLT 5 < -5");

        A = 32'h80000000; B = 0;
        check(1, 0, 0, 0, 0, "SLT negative min < 0");


        // ----------------------------------------------------------
        // SLTU (0110)
        // ----------------------------------------------------------
        ALUControl = 4'b0110;

        A = 1; B = 32'hFFFFFFFF;
        check(1, 0, 0, 0, 0, "SLTU 1 < max");

        A = 32'hFFFFFFFF; B = 1;
        check(0, 0, 0, 1, 0, "SLTU max < 1");

        A = 32'h80000000; B = 32'h7FFFFFFF;
        check(0, 0, 0, 1, 0, "SLTU unsigned compare");


        // ----------------------------------------------------------
        // SLL (0111)
        // ----------------------------------------------------------
        ALUControl = 4'b0111;

        A = 1; B = 5;
        check(32'h20, 0, 0, 0, 0, "SLL 1<<5");

        A = 32'hF0000000; B = 4;
        check(32'h00000000, 0, 0, 1, 0, "SLL overflow shift");


        // ----------------------------------------------------------
        // SRL (1000)
        // ----------------------------------------------------------
        ALUControl = 4'b1000;

        A = 32'h80000000; B = 31;
        check(1, 0, 0, 0, 0, "SRL logical right");

        A = 32'hFFFFFFFF; B = 4;
        check(32'h0FFFFFFF, 0, 0, 0, 0, "SRL shift");


        // ----------------------------------------------------------
        // SRA (1001)
        // ----------------------------------------------------------
        ALUControl = 4'b1001;

        A = -1; B = 4;
        check(32'hFFFFFFFF, 0, 0, 0, 1, "SRA arithmetic");

        A = 32'h80000000; B = 31;
        check(32'hFFFFFFFF, 0, 0, 0, 1, "SRA sign extend");


        // ----------------------------------------------------------
        // Zero Flag Test
        // ----------------------------------------------------------
        ALUControl = 4'b0000;

        A = 10; B = -10;
        check(0, 1, 0, 1, 0, "Zero flag test");


        // ============================================================
        // FINAL VERIFICATION REPORT
        // ============================================================
        $display("\n====================================================");
        $display(" ALU VERIFICATION REPORT");
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
