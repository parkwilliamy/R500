`timescale 1ns/1ps

module ControlUnit (
    input [6:0] opcode,
    output reg [2:0] ValidReg,
    output reg [1:0] ALUOp, RegSrc,
    output reg ALUSrc, RegWrite, MemRead, MemWrite, Branch, Jump, Valid
    // ValidReg: {rs2, rs1, rd} are valid registers (validity is determined by instruction type, for example, only rs1 and rs2 valid in B-type instructions)
    // ALUOp: 0 -> Decode regbit, funct3 and funct7 in ALUControl, 1 -> ADD, 2 -> SUB
    // RegSrc: 0 -> ALU result, 1 -> data memory, 2 -> pc-imm adder, 3 -> next instruction address (pc+4)
    // ALUSrc: 0 -> Second operand is rs2, 1 -> second operand is sign extended immediate
    // RegWrite: 0 -> No writeback to RegFile, 1 -> writeback to RegFile
    // MemRead: 0 -> No read from data memory, 1 -> read from data memory into RegFile
    // MemWrite: 0 -> No write to data memory, 1 -> write to data memory 
    // Branch: 0 -> Instruction is not B-type, 1 -> instruction is B-type
    // Jump: 0 -> Instruction is not J-type, 1 -> instruction is J-type
    // Valid: 0 -> Instruction is not in RV32I, 1 -> instruction is in RV32I
);

    localparam [6:0] // Opcodes for different instruction types
        OP_R = 7'b0110011,
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

        ALUOp = 0;
        RegSrc = 0;
        ALUSrc = 0;
        RegWrite = 1;
        MemRead = 0;
        MemWrite = 0;
        Branch = 0;
        Jump = 0;
        Valid = 1;

        case (opcode)

            // Since default vals satisfy OP_R, there is no case for R-type instructions

            OP_R: ValidReg = 3'b111;

            OP_I: begin
                
                ALUSrc = 1;
                ValidReg = 3'b011;

            end

            OP_I_LD: begin
                
                ALUOp = 1;
                ALUSrc = 1;
                MemRead = 1;
                RegSrc = 1;
                ValidReg = 3'b011;
                
            end

            OP_I_JALR: begin

                ALUOp = 1;
                RegSrc = 3;
                ALUSrc = 1;
                Jump = 1;
                ValidReg = 3'b011;

            end
        
            OP_I_FENCE: begin

                RegWrite = 0;
                ValidReg = 3'b011;

            end

            OP_S: begin

                ALUOp = 1; 
                ALUSrc = 1;
                RegWrite = 0;
                MemWrite = 1;
                ValidReg = 3'b110;
                
            end

            OP_U_LUI: begin

                ALUOp = 1;
                ALUSrc = 1;
                ValidReg = 3'b001;

            end

            OP_U_AUIPC: begin
                
                RegSrc = 2;
                ValidReg = 3'b001;

            end

            OP_J: begin

                RegSrc = 3;
                Jump = 1;
                ValidReg = 3'b001;

            end

            OP_B: begin

                ALUOp = 2;
                RegWrite = 0;
                Branch = 1;
                ValidReg = 3'b110;

            end 

            default: begin

                RegWrite = 0;
                ValidReg = 0;
                Valid = 0;

            end
            
        endcase

    end

endmodule