`timescale 1ns/1ps

module ALU (
    input [31:0] op1, op2,
    input [3:0] field, // funct7[5]/0 + funct3 (only funct7[5] for certain instructions)
    output reg [31:0] ALU_result,
    output zero, sign, overflow,
    output reg carry
);

    localparam [3:0] // different fields for ALU operations
        ADD = 4'b0000,
        SUB = 4'b1000,
        AND = 4'b0111,
        OR  = 4'b0110,
        XOR = 4'b0100,
        SLL = 4'b0001,
        SRL = 4'b0101,
        SRA = 4'b1101,
        SLT = 4'b0010,
        SLTU = 4'b0011;

    assign zero = (ALU_result == 0);
    assign sign = ($signed(ALU_result) < 0);
    assign overflow = (op1[31] != op2[31]) && (ALU_result[31] != op1[31]); // detects overflow for subtraction used in branch decisions

    always @(*) begin
    
        ALU_result = 0;
        carry = 0;

        case (field) 

            ADD: {carry, ALU_result} = op1+op2;
            SUB: {carry, ALU_result} = op1-op2;
            AND: ALU_result = op1&op2;
            OR: ALU_result = op1|op2;
            XOR: ALU_result = op1^op2;
            SLL: ALU_result = op1<<op2[4:0];
            SRL: ALU_result = op1>>op2[4:0];
            SRA: ALU_result = $signed(op1)>>>op2[4:0];
            SLT: ALU_result = {31'b0, $signed(op1)<$signed(op2)};
            SLTU: ALU_result = {31'b0, op1<op2};

        endcase
        
    end


endmodule