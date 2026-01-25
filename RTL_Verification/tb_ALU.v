`timescale 1ns/1ps

module tb_ALU;

    // DUT inputs
    reg  [31:0] A, B;
    reg  [2:0]  ALUControl;

    // DUT outputs
    wire        Carry, OverFlow, Zero, Negative;
    wire [31:0] Result;

    // Reference signals
    reg  [32:0] ref_addsub;
    reg  [31:0] ref_result;
    reg         ref_carry, ref_overflow, ref_zero, ref_negative;

    integer i;

    // ------------------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // Reference Model (pure Verilog)
    // ------------------------------------------------------------
    always @(*) begin
        ref_result   = 32'd0;
        ref_carry    = 1'b0;
        ref_overflow = 1'b0;

        case (ALUControl)

            3'b000: begin // ADD
                ref_addsub = {1'b0, A} + {1'b0, B};
                ref_result = ref_addsub[31:0];
                ref_carry  = ref_addsub[32];
                ref_overflow = (~(A[31] ^ B[31])) & (A[31] ^ ref_result[31]);
            end

            3'b001: begin // SUB
                ref_addsub = {1'b0, A} - {1'b0, B};
                ref_result = ref_addsub[31:0];
                ref_carry  = ref_addsub[32];
                ref_overflow = (A[31] ^ B[31]) & (A[31] ^ ref_result[31]);
            end

            3'b010: ref_result = A & B; // AND
            3'b011: ref_result = A | B; // OR

            3'b101: begin // SLT (signed)
                if ($signed(A) < $signed(B))
                    ref_result = 32'd1;
                else
                    ref_result = 32'd0;
            end

            default: ref_result = 32'd0;
        endcase

        ref_zero     = (ref_result == 32'd0);
        ref_negative = ref_result[31];
    end

    // ------------------------------------------------------------
    // Checker
    // ------------------------------------------------------------
    task check;
    begin
        if (Result   !== ref_result   ||
            Carry    !== ref_carry    ||
            OverFlow !== ref_overflow ||
            Zero     !== ref_zero     ||
            Negative !== ref_negative) begin

            $display("ERROR DETECTED");
            $display("A=%0d  B=%0d  ALUControl=%b",
                     $signed(A), $signed(B), ALUControl);
            $display("Expected: R=%h C=%b O=%b Z=%b N=%b",
                     ref_result, ref_carry, ref_overflow,
                     ref_zero, ref_negative);
            $display("Got     : R=%h C=%b O=%b Z=%b N=%b",
                     Result, Carry, OverFlow,
                     Zero, Negative);
            $stop;
        end
    end
    endtask

    // ------------------------------------------------------------
    // Test Sequence
    // ------------------------------------------------------------
    initial begin
        $display("==== ALU VERIFICATION START ====");

        // Directed tests
        A = 0; B = 0; ALUControl = 3'b000; #5; check();
        A = 32'h7fffffff; B = 1; ALUControl = 3'b000; #5; check(); // ADD overflow
        A = 32'h80000000; B = 1; ALUControl = 3'b001; #5; check(); // SUB overflow
        A = 5; B = 10; ALUControl = 3'b101; #5; check();           // SLT = 1
        A = 10; B = 5; ALUControl = 3'b101; #5; check();           // SLT = 0

        // Random tests
        for (i = 0; i < 5000; i = i + 1) begin
            A = $random; B = $random; ALUControl = 3'b000; #1; check(); // ADD
            A = $random; B = $random; ALUControl = 3'b001; #1; check(); // SUB
            A = $random; B = $random; ALUControl = 3'b010; #1; check(); // AND
            A = $random; B = $random; ALUControl = 3'b011; #1; check(); // OR
            A = $random; B = $random; ALUControl = 3'b101; #1; check(); // SLT
        end

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
