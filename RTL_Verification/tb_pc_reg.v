//=====================================================================
// File        : tb_pc_reg.v
// Author      : Prabhat Pandey
// Created On  : 12-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : tb_pc_reg
// Description :
//   Self-checking testbench for the pc_reg module.
//
//   What is tested:
//     1) Reset behavior:
//        - When rst_n = 0, pc_current must become 0x00000000.
//     2) Normal PC update behavior:
//        - On every rising edge of clk, pc_current must take pc_next.
//     3) Multiple sequential updates:
//        - Ensures the register correctly updates over several cycles.
//
//   Testbench Features:
//     - PASS/FAIL counters
//     - Detailed prints for each test case
//     - Final verification summary report
//
// Notes:
//   - This testbench uses an active-low asynchronous reset.
//   - All checks are performed slightly after the clock edge to avoid
//     race conditions in simulation.
//=====================================================================

`timescale 1ns/1ps

module tb_pc_reg;

    //=============================================================
    // DUT Signals
    //=============================================================
    reg         clk;
    reg         rst_n;
    reg  [31:0] pc_next;
    wire [31:0] pc_current;

    //=============================================================
    // Pass/Fail Counters
    //=============================================================
    integer pass_count;
    integer fail_count;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    pc_reg dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    //=============================================================
    // Clock Generation
    //  - 10ns clock period => 100 MHz (just for simulation)
    //=============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //=============================================================
    // Task: CHECK
    // Purpose:
    //   Compares expected vs actual values and updates counters.
    //=============================================================
    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [1023:0] testname;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s | Expected = 0x%08h, Got = 0x%08h",
                         testname, expected, actual);
            end
            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s | Expected = 0x%08h, Got = 0x%08h",
                         testname, expected, actual);
            end
        end
    endtask

    //=============================================================
    // Test Sequence
    //=============================================================
    initial begin
        // Initialize counters
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst_n   = 1'b0;
        pc_next = 32'h0000_0000;

        $display("====================================================");
        $display(" TB START : pc_reg");
        $display("====================================================");

        //=========================================================
        // TEST 1: Reset should clear PC to 0
        //=========================================================
        $display("\n[TEST 1] Reset behavior check");

        // Keep reset asserted for some time
        #2;
        check(32'h0000_0000, pc_current, "Reset asserted => PC must be 0");

        //=========================================================
        // Release reset and apply first pc_next
        //=========================================================
        $display("\n[TEST 2] PC update after reset release");

        pc_next = 32'h0000_0004;
        rst_n   = 1'b1;   // Release reset

        // Wait for rising edge, then check
        @(posedge clk);
        #1;
        check(32'h0000_0004, pc_current, "PC loads 0x00000004 after posedge");

        //=========================================================
        // TEST 3: Multiple sequential updates
        //=========================================================
        $display("\n[TEST 3] Multiple sequential PC updates");

        pc_next = 32'h0000_0008;
        @(posedge clk);
        #1;
        check(32'h0000_0008, pc_current, "PC loads 0x00000008");

        pc_next = 32'h0000_000C;
        @(posedge clk);
        #1;
        check(32'h0000_000C, pc_current, "PC loads 0x0000000C");

        pc_next = 32'h0000_0010;
        @(posedge clk);
        #1;
        check(32'h0000_0010, pc_current, "PC loads 0x00000010");

        //=========================================================
        // TEST 4: Assert reset in the middle (async reset check)
        //=========================================================
        $display("\n[TEST 4] Asynchronous reset during operation");

        pc_next = 32'hDEAD_BEEF;

        // Assert reset asynchronously (not aligned to clock)
        #3;
        rst_n = 1'b0;
        #1;
        check(32'h0000_0000, pc_current, "Async reset => PC must immediately become 0");

        // Release reset again and update PC
        rst_n = 1'b1;
        pc_next = 32'h0000_0020;

        @(posedge clk);
        #1;
        check(32'h0000_0020, pc_current, "After reset release => PC loads 0x00000020");

        //=========================================================
        // Final Report
        //=========================================================
        $display("\n====================================================");
        $display(" TB RESULT : pc_reg");
        $display("====================================================");
        $display(" Total PASS = %0d", pass_count);
        $display(" Total FAIL = %0d", fail_count);

        if (fail_count == 0) begin
            $display(" STATUS     = ALL TESTS PASSED");
        end
        else begin
            $display(" STATUS     = SOME TESTS FAILED");
        end

        $display("====================================================\n");

        $finish;
    end

endmodule
