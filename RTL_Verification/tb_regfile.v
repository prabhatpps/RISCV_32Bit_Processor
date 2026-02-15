//=====================================================================
// File        : tb_regfile.v
// Author      : Prabhat Pandey
// Created On  : 13-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_regfile
// Description :
//   Fully self-checking testbench for regfile.v
//
//   Verification Targets:
//     1) Two combinational read ports work correctly
//     2) One synchronous write port works correctly
//     3) Writes occur ONLY on posedge clk
//     4) Writes ignored when rd = x0
//     5) Reads from x0 always return 0
//     6) Multiple sequential writes update correct registers
//
// Verification Features:
//   - Fully self-checking
//   - Input print for every test (including write signals)
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test case
//   - Global counters for total/pass/fail
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_regfile ./src/regfile.v ./RTL_Verification/tb_regfile.v
//   vvp ./Verification_Results/result_tb_regfile
//=====================================================================

`timescale 1ns/1ps

module tb_regfile;

    //=============================================================
    // DUT Signals
    //=============================================================
    reg         clk;
    reg         we;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;
    reg  [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    regfile dut (
        .clk (clk),
        .we  (we),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (wd),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    //=============================================================
    // Global Verification Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //=============================================================
    // Clock Generation (10ns period)
    //=============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //=============================================================
    // Task: Divider
    //=============================================================
    task print_divider;
        begin
            $display("----------------------------------------------------------------");
        end
    endtask

    //=============================================================
    // Task: Apply Read Addresses (Combinational)
    //=============================================================
    task apply_reads;
        input [4:0] rs1_in;
        input [4:0] rs2_in;
        begin
            rs1 = rs1_in;
            rs2 = rs2_in;
            #1; // combinational settle time
        end
    endtask

    //=============================================================
    // Task: Run a PURE Read Check Test (No Write)
    //=============================================================
    task run_read_test;
        input [8*60:1] test_name;
        input [4:0]    rs1_in;
        input [4:0]    rs2_in;
        input [31:0]   exp_rd1;
        input [31:0]   exp_rd2;

        reg [31:0] got1;
        reg [31:0] got2;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Ensure no write happening during a pure read test
            we = 1'b0;
            rd = 5'd0;
            wd = 32'h0000_0000;

            // Apply read indices
            apply_reads(rs1_in, rs2_in);

            got1 = rd1;
            got2 = rd2;

            // Print Inputs
            $display("Inputs:");
            $display("   we   = %0d", we);
            $display("   rd   = x%0d", rd);
            $display("   wd   = %08h", wd);
            $display("   rs1  = x%0d", rs1_in);
            $display("   rs2  = x%0d", rs2_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   rd1  = %08h", exp_rd1);
            $display("   rd2  = %08h", exp_rd2);

            // Print Got
            $display("");
            $display("Got:");
            $display("   rd1  = %08h", got1);
            $display("   rd2  = %08h", got2);

            // Compare
            if ((got1 === exp_rd1) && (got2 === exp_rd2)) begin
                passed_tests = passed_tests + 1;
                $display("STATUS: PASS");
            end
            else begin
                failed_tests = failed_tests + 1;
                $display("STATUS: FAIL");
            end

            print_divider();
            $display("");
        end
    endtask

    //=============================================================
    // Task: Run a WRITE + READBACK Test
    //=============================================================
    // This is the main verification style:
    //   1) Apply write signals (we, rd, wd)
    //   2) Commit on posedge clk
    //   3) Read back using rs1/rs2
    //   4) Compare expected vs got
    //=============================================================
    task run_write_read_test;
        input [8*60:1] test_name;

        // Write signals
        input          we_in;
        input [4:0]    rd_in;
        input [31:0]   wd_in;

        // Read signals
        input [4:0]    rs1_in;
        input [4:0]    rs2_in;

        // Expected outputs
        input [31:0]   exp_rd1;
        input [31:0]   exp_rd2;

        reg [31:0] got1;
        reg [31:0] got2;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply write inputs
            we = we_in;
            rd = rd_in;
            wd = wd_in;

            // Apply read addresses (before write commits)
            apply_reads(rs1_in, rs2_in);

            // Commit write on posedge
            @(posedge clk);
            #1;

            // Read again after write
            apply_reads(rs1_in, rs2_in);

            got1 = rd1;
            got2 = rd2;

            // Print Inputs
            $display("Inputs:");
            $display("   we   = %0d", we_in);
            $display("   rd   = x%0d", rd_in);
            $display("   wd   = %08h", wd_in);
            $display("   rs1  = x%0d", rs1_in);
            $display("   rs2  = x%0d", rs2_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   rd1  = %08h", exp_rd1);
            $display("   rd2  = %08h", exp_rd2);

            // Print Got
            $display("");
            $display("Got:");
            $display("   rd1  = %08h", got1);
            $display("   rd2  = %08h", got2);

            // Compare
            if ((got1 === exp_rd1) && (got2 === exp_rd2)) begin
                passed_tests = passed_tests + 1;
                $display("STATUS: PASS");
            end
            else begin
                failed_tests = failed_tests + 1;
                $display("STATUS: FAIL");
            end

            print_divider();
            $display("");
        end
    endtask

    //=============================================================
    // Main Test Sequence
    //=============================================================
    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init inputs
        we  = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd  = 5'd0;
        wd  = 32'h0000_0000;

        $display("====================================================");
        $display(" REGFILE VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // TEST 1: x0 reads always 0 (initial)
        //=========================================================
        run_read_test("x0 must always read 0 (initial)", 5'd0, 5'd0,
                      32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // TEST 2: Write x1 and read back
        //=========================================================
        run_write_read_test("Write x1=0x11111111, read x1",
                            1'b1, 5'd1, 32'h1111_1111,
                            5'd1, 5'd0,
                            32'h1111_1111, 32'h0000_0000);

        //=========================================================
        // TEST 3: Write x2 and read both ports (x1, x2)
        //=========================================================
        run_write_read_test("Write x2=0x22222222, read x1 and x2",
                            1'b1, 5'd2, 32'h2222_2222,
                            5'd1, 5'd2,
                            32'h1111_1111, 32'h2222_2222);

        //=========================================================
        // TEST 4: Write disabled must NOT update x3
        //=========================================================
        run_write_read_test("Write disabled (we=0), x3 must remain 0",
                            1'b0, 5'd3, 32'h3333_3333,
                            5'd3, 5'd0,
                            32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // TEST 5: Write to x0 ignored
        //=========================================================
        run_write_read_test("Write to x0 ignored, x0 must stay 0",
                            1'b1, 5'd0, 32'hFFFF_FFFF,
                            5'd0, 5'd1,
                            32'h0000_0000, 32'h1111_1111);

        //=========================================================
        // TEST 6: Overwrite x1
        //=========================================================
        run_write_read_test("Overwrite x1 with 0xAAAAAAAA",
                            1'b1, 5'd1, 32'hAAAA_AAAA,
                            5'd1, 5'd2,
                            32'hAAAA_AAAA, 32'h2222_2222);

        //=========================================================
        // TEST 7: Back-to-back writes (x4 then x5)
        //=========================================================
        run_write_read_test("Write x4=0x44444444, read x4",
                            1'b1, 5'd4, 32'h4444_4444,
                            5'd4, 5'd0,
                            32'h4444_4444, 32'h0000_0000);

        run_write_read_test("Write x5=0x55555555, read x4 and x5",
                            1'b1, 5'd5, 32'h5555_5555,
                            5'd4, 5'd5,
                            32'h4444_4444, 32'h5555_5555);

        //=========================================================
        // TEST 8: Same-cycle behavior (post-clock correctness)
        //=========================================================
        run_write_read_test("Write x6=0x66666666, read x6",
                            1'b1, 5'd6, 32'h6666_6666,
                            5'd6, 5'd0,
                            32'h6666_6666, 32'h0000_0000);

        //=========================================================
        // TEST 9: Final x0 check after many writes
        //=========================================================
        run_read_test("Final x0 check (must still be 0)", 5'd0, 5'd6,
                      32'h0000_0000, 32'h6666_6666);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" REGFILE VERIFICATION REPORT");
        $display("====================================================");
        $display("   Total Tests   : %0d", total_tests);
        $display("   Passed        : %0d", passed_tests);
        $display("   Failed        : %0d", failed_tests);
        $display("====================================================");

        if (failed_tests == 0) begin
            $display("STATUS: ALL TESTS PASSED");
        end
        else begin
            $display("STATUS: SOME TESTS FAILED");
        end

        $display("====================================================");
        $display("");

        $finish;
    end

endmodule
