`timescale 1ns/1ps

module ImmGen (
    input [31:0] instruction,
    output reg [31:0] imm
);

    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [11:0] intimm1; // 12-bit immediate
    reg [19:0] intimm2; // 20-bit immediate
    reg [31:0] imm1;
    reg [31:0] imm2;
    reg [31:0] imm3;
    reg [31:0] imm4;

    localparam [6:0] // opcodes for different instruction types
        OP_I = 7'b0010011,
        OP_I_LD = 7'b0000011,
        OP_I_FENCE = 7'b0001111,
        OP_I_JALR = 7'b1100111,
        OP_S = 7'b0100011,
        OP_B = 7'b1100011,
        OP_U_LUI = 7'b0110111,
        OP_U_AUIPC = 7'b0010111,
        OP_J = 7'b1101111;

    always @(*) begin

        opcode = instruction[6:0];
        funct3 = instruction[14:12]; // used for I-type instructions

        case (opcode)

            OP_I, OP_I_LD, OP_I_FENCE, OP_I_JALR: begin
                intimm1 = (opcode == OP_I && (funct3 == 3'b001 || funct3 == 3'b101)) ? {7'b0000000, instruction[24:20]} : instruction[31:20];
                intimm2 = 0;
            end
            OP_S: begin
                intimm1 = {instruction[31:25], instruction[11:7]};
                intimm2 = 0;
            end
            OP_B: begin
                intimm1 = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
                intimm2 = 0;
            end
            OP_U_LUI, OP_U_AUIPC: begin
                intimm1 = 0;
                intimm2 = instruction[31:12];
            end
            OP_J: begin
                intimm1 = 0;
                intimm2 = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
            end
            default: begin 
                intimm1 = 0; // only for R-type format
                intimm2 = 0;
            end

        endcase

        imm1 = {{20{intimm1[11]}}, intimm1};
        imm2 = {{11{intimm2[19]}}, intimm2, 1'b0};
        imm3 = {intimm2, 12'b0};
        imm4 = {{19{intimm1[11]}}, intimm1, 1'b0};

        case (opcode)

            OP_J: imm = imm2;
            OP_U_LUI, OP_U_AUIPC: imm = imm3;
            OP_B: imm = imm4;
            default: imm = imm1;

        endcase
    

    end

endmodule