// ======================================================================
// Testbench for 32-bit ALU (RV32I)
// Author: Prabhat Pandey
// ======================================================================

`timescale 1ns/1ps

module tb_ALU;

    reg  [31:0] A, B;
    reg  [3:0]  ALUControl;
    wire        Carry, OverFlow, Zero, Negative;
    wire [31:0] Result;

    // Instantiate ALU
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

    // Task to check results
    task check;
        input [31:0] exp;
        input [255:0] msg;
        begin
            #1;
            if (Result === exp)
                $display("PASS: %-25s | A=%h B=%h Result=%h", msg, A, B, Result);
            else
                $display("FAIL: %-25s | A=%h B=%h Expected=%h Got=%h",
                         msg, A, B, exp, Result);
        end
    endtask

    initial begin
        $display("====================================================");
        $display(" ALU TEST STARTED — Author: Prabhat Pandey");
        $display("====================================================");

        // ==========================================================
        // ADD (0000)
        // ==========================================================
        ALUControl = 4'b0000;

        A = 32'd5;   B = 32'd7;   check(32'd12, "ADD basic");
        A = 32'hFFFFFFFF; B = 32'd1; check(32'h00000000, "ADD wrap");
        A = 32'h7FFFFFFF; B = 32'd1; check(32'h80000000, "ADD signed overflow");

        // ==========================================================
        // SUB (0001)
        // ==========================================================
        ALUControl = 4'b0001;

        A = 32'd20; B = 32'd7;  check(32'd13, "SUB basic");
        A = 32'd7;  B = 32'd20; check(32'hfffffff3, "SUB negative result");  // FIXED
        A = 32'h80000000; B = 32'd1; check(32'h7fffffff, "SUB signed overflow");

        // ==========================================================
        // AND (0010)
        // ==========================================================
        ALUControl = 4'b0010;

        A = 32'hF0F0F0F0; B = 32'h0FF00FF0; check(32'h00F000F0, "AND test");

        // ==========================================================
        // OR (0011)
        // ==========================================================
        ALUControl = 4'b0011;

        A = 32'hA5A5A5A5; B = 32'h0F0F0F0F; check(32'hAFAFAFAF, "OR test");  // FIXED

        // ==========================================================
        // XOR (0100)
        // ==========================================================
        ALUControl = 4'b0100;

        A = 32'hAAAAAAAA; B = 32'h55555555; check(32'hFFFFFFFF, "XOR test");

        // ==========================================================
        // SLT (0101) signed
        // ==========================================================
        ALUControl = 4'b0101;

        A = -5; B = 5;       check(32'd1, "SLT -5 < 5");
        A = 5;  B = -5;      check(32'd0, "SLT 5 < -5");
        A = 32'h80000000; B = 0; check(32'd1, "SLT negative min < 0");

        // ==========================================================
        // SLTU (0110) unsigned
        // ==========================================================
        ALUControl = 4'b0110;

        A = 32'h00000001; B = 32'hFFFFFFFF; check(32'd1, "SLTU 1 < max");
        A = 32'hFFFFFFFF; B = 32'h00000001; check(32'd0, "SLTU max < 1");
        A = 32'h80000000; B = 32'h7FFFFFFF; check(32'd0, "SLTU unsigned compare");

        // ==========================================================
        // SLL (0111)
        // ==========================================================
        ALUControl = 4'b0111;

        A = 32'h00000001; B = 32'd5; check(32'h00000020, "SLL 1<<5");
        A = 32'hF0000000; B = 32'd4; check(32'h00000000, "SLL overflow shift");

        // ==========================================================
        // SRL (1000)
        // ==========================================================
        ALUControl = 4'b1000;

        A = 32'h80000000; B = 32'd31; check(32'h00000001, "SRL logical right");
        A = 32'hFFFFFFFF; B = 32'd4;  check(32'h0FFFFFFF, "SRL shift");

        // ==========================================================
        // SRA (1009)
        // ==========================================================
        ALUControl = 4'b1001;

        A = -32'd1; B = 32'd4; check(32'hFFFFFFFF, "SRA arithmetic");
        A = 32'h80000000; B = 32'd31; check(32'hFFFFFFFF, "SRA sign extend");

        // ==========================================================
        // Zero flag test
        // ==========================================================
        ALUControl = 4'b0000; // ADD
        A = 32'd10; B = -32'd10; check(32'd0, "Zero flag test");

        $display("====================================================");
        $display(" ALU TEST FINISHED");
        $display("====================================================");

        $finish;
    end

endmodule
