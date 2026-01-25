// ======================================================================
// 32-bit ALU for RV32I
// Author: Prabhat Pandey
// 
// Description:
//   This ALU implements all arithmetic, logical, shift, and comparison
//   operations required for the base RV32I instruction set. It is fully
//   synthesizable and suitable for pipeline or single-cycle RISC-V cores.
//
//   Supported Operations (ALUControl):
//     0000 : ADD   (A + B)
//     0001 : SUB   (A - B)
//     0010 : AND   (A & B)
//     0011 : OR    (A | B)
//     0100 : XOR   (A ^ B)
//     0101 : SLT   (signed  A < B)
//     0110 : SLTU  (unsigned A < B)
//     0111 : SLL   (A << shamt)
//     1000 : SRL   (A >> shamt)  Logical
//     1001 : SRA   (A >>> shamt) Arithmetic
//
// Status Flags (similar to ARM/MIPS style flags):
//   Carry     - Carry-out from adder (ADD/SUB only)
//   OverFlow  - Signed overflow from ADD/SUB
//   Zero      - Asserted when Result == 0
//   Negative  - MSB of Result (signed indication)
//
// ======================================================================

module ALU (
    input  [31:0] A, B,
    input  [3:0]  ALUControl,     // 4-bit control to support 10+ operations
    output        Carry,
    output        OverFlow,
    output        Zero,
    output        Negative,
    output [31:0] Result
);

    // ================================================================
    // ADD / SUB Implementation (Two's Complement Arithmetic)
    // ================================================================
    //
    // In two’s complement, subtraction is implemented using:
    //     A - B = A + (~B + 1)
    //
    // We use a single adder that performs both ADD and SUB based on
    // ALUControl:
    //   ADD: adder = A + B
    //   SUB: adder = A + (~B) + 1
    //
    // The 33-bit adder provides us:
    //   - Lower 32 bits: arithmetic result
    //   - Bit [32]: carry-out (used for carry/borrow detection)
    //
    // Note: RISC-V does NOT use carry/borrow flags architecturally,
    // but we compute them for completeness and debugging.
    // ================================================================

    wire is_add = (ALUControl == 4'b0000);
    wire is_sub = (ALUControl == 4'b0001);

    // Full 33-bit adder to capture carry-out
    wire [32:0] adder =
        is_sub ? ({1'b0, A} + {1'b0, ~B} + 1'b1) :     // A - B
                 ({1'b0, A} + {1'b0,  B});             // A + B

    wire [31:0] addsub_result = adder[31:0];
    wire        carry_out      = adder[32];


    // ================================================================
    // Signed Overflow Detection
    // ================================================================
    //
    // Signed overflow occurs when:
    //
    //   ADD:
    //      A and B have same sign
    //      AND result has opposite sign from A
    //
    //   SUB:
    //      A and B have opposite signs
    //      AND result has opposite sign from A
    //
    // These are the canonical overflow equations for 2's complement.
    // ================================================================

    wire overflow_add = (~A[31] & ~B[31] &  addsub_result[31]) |
                        ( A[31] &  B[31] & ~addsub_result[31]);

    wire overflow_sub = (~A[31] &  B[31] &  addsub_result[31]) |
                        ( A[31] & ~B[31] & ~addsub_result[31]);

    wire overflow_flag = is_add ? overflow_add :
                         is_sub ? overflow_sub :
                         1'b0;


    // ================================================================
    // Shift Operations
    // ================================================================
    //
    // RISC-V shift amount = B[4:0]
    //
    //   SLL  : logical left shift
    //   SRL  : logical right shift (zero fill)
    //   SRA  : arithmetic right shift (sign-extended)
    //
    // >>> operator automatically performs sign-extension for arithmetic
    // shifts when operand is declared as signed.
    // ================================================================

    wire [4:0] shamt = B[4:0];

    wire [31:0] sll_result = A << shamt;
    wire [31:0] srl_result = A >> shamt;
    wire [31:0] sra_result = $signed(A) >>> shamt;


    // ================================================================
    // Comparison Operations (SLT / SLTU)
    // ================================================================
    //
    // SLT (signed comparison):
    //     result = (signed(A) < signed(B)) ? 1 : 0
    //
    // SLTU (unsigned comparison):
    //     result = (A < B) ? 1 : 0
    //
    // These correspond exactly to RISC-V SLT and SLTU instructions.
    // ================================================================

    wire slt_result  = ($signed(A) < $signed(B));
    wire sltu_result = (A < B);


    // ================================================================
    // Main Operation MUX
    // ================================================================
    //
    // A single combinational always-block chooses the output based on
    // ALUControl. This block MUST remain purely combinational for
    // synthesis.
    //
    // Unsupported ALUControl results return X (debug-friendly).
    // ================================================================

    reg [31:0] result_reg;

    always @(*) begin
        case (ALUControl)
            4'b0000: result_reg = addsub_result;               // ADD
            4'b0001: result_reg = addsub_result;               // SUB
            4'b0010: result_reg = A & B;                       // AND
            4'b0011: result_reg = A | B;                       // OR
            4'b0100: result_reg = A ^ B;                       // XOR
            4'b0101: result_reg = {31'b0, slt_result};         // SLT  signed
            4'b0110: result_reg = {31'b0, sltu_result};        // SLTU unsigned
            4'b0111: result_reg = sll_result;                  // SLL
            4'b1000: result_reg = srl_result;                  // SRL
            4'b1001: result_reg = sra_result;                  // SRA
            default: result_reg = 32'hXXXXXXXX;                // Illegal op
        endcase
    end

    assign Result = result_reg;


    // ================================================================
    // FLAGS
    // ================================================================
    //
    // Carry:
    //   - Meaningful only for ADD and SUB.
    //
    // OverFlow:
    //   - Signed overflow flag, computed above.
    //
    // Zero:
    //   - True when Result == 0.
    //   - Implemented using reduction NOR (~|Result), synthesizable.
    //
    // Negative:
    //   - Sign bit of result (useful for debugging and branch logic).
    // ================================================================

    assign Carry    = (is_add | is_sub) ? carry_out : 1'b0;
    assign OverFlow = overflow_flag;
    assign Zero     = ~|result_reg;
    assign Negative = result_reg[31];

endmodule
