// ======================================================================
// 32-bit ALU
// Supported ALUControl operations:
//   3'b000 : ADD  --- Result = A + B
//   3'b001 : SUB  --- Result = A - B
//   3'b010 : AND  --- Result = A & B
//   3'b011 : OR   --- Result = A | B
//   3'b101 : SLT  --- Result = (A < B) ? 1 : 0  (signed comparison)
//
// Status flags:
//   Carry     --- Valid only for ADD/SUB
//   OverFlow  --- Valid only for ADD/SUB (signed overflow)
//   Zero      --- High when Result == 0
//   Negative  --- Sign bit of Result
// ======================================================================

module ALU (
    input  [31:0] A, B,          // ALU input operands
    input  [2:0]  ALUControl,    // Operation selector
    output        Carry,         // Carry-out flag (ADD/SUB only)
    output        OverFlow,      // Signed overflow flag (ADD/SUB only)
    output        Zero,          // Zero flag (Result == 0)
    output        Negative,      // Sign bit flag (MSB of Result)
    output [31:0] Result         // Final ALU result output
);

    // Internal wires
    wire        carry_out;        // Carry-out from adder/subtractor
    wire [31:0] addsub_result;    // Result of ADD or SUB

    // Detect arithmetic operations
    wire is_add = (ALUControl == 3'b000);
    wire is_sub = (ALUControl == 3'b001);

    // ----------------------------------------------------------------------
    // ADD / SUB block:
    //   ALUControl[0] = 0 --- Perform A + B
    //   ALUControl[0] = 1 --- Perform A - B = A + (~B + 1)
    //
    // The adder runs for every ALUControl value; however its result is used
    // only when performing ADD or SUB.
    // ----------------------------------------------------------------------
    assign {carry_out, addsub_result} =
        (ALUControl[0] == 1'b0) ? (A + B) :
                                  (A - B);


    // ----------------------------------------------------------------------
    // Main Result MUX:
    // Selects output based on ALUControl encoding.
    //
    // SLT uses the sign bit of (A - B):
    //   If A - B < 0 --- addsub_result[31] = 1 --- SLT output = 1
    // ----------------------------------------------------------------------
    assign Result =
        (ALUControl == 3'b000) ? addsub_result :                       // ADD
        (ALUControl == 3'b001) ? addsub_result :                       // SUB
        (ALUControl == 3'b010) ? (A & B)        :                      // AND
        (ALUControl == 3'b011) ? (A | B)        :                      // OR
        (ALUControl == 3'b101) ? {{31{1'b0}}, addsub_result[31]} :     // SLT (signed)
                                 32'b0;                                // Default

    // ----------------------------------------------------------------------
    // Overflow Detection (Signed Addition/Subtraction)
    //
    // Signed overflow rules:
    //
    // ADD overflow:
    //   Occurs when A and B share the same sign, but Result differs.
    //
    // SUB overflow:
    //   Occurs when A and B have opposite signs, and Result differs from A.
    //
    // These expressions implement the standard two's complement overflow rules.
    // Overflow is valid ONLY for ADD and SUB.
    // ----------------------------------------------------------------------
    wire overflow_add = (~(A[31] ^ B[31])) & (A[31] ^ addsub_result[31]);
    wire overflow_sub = ( A[31] ^ B[31])  & (A[31] ^ addsub_result[31]);

    assign OverFlow =
        is_add ? overflow_add :
        is_sub ? overflow_sub :
                 1'b0;

    // ----------------------------------------------------------------------
    // Carry Flag:
    //   - carry_out is meaningful only for ADD and SUB.
    //   - For logical operations, carry_out is irrelevant and must be masked.
    // ----------------------------------------------------------------------
    assign Carry = (is_add | is_sub) ? carry_out : 1'b0;

    // ----------------------------------------------------------------------
    // Zero Flag:
    // Asserted when Result == 0.
    // Implemented using reduction NOR (~|Result).
    // ----------------------------------------------------------------------
    assign Zero = ~|Result;

    // ----------------------------------------------------------------------
    // Negative Flag:
    // Simply the MSB of the Result, indicating signed negativity.
    // ----------------------------------------------------------------------
    assign Negative = Result[31];

endmodule
