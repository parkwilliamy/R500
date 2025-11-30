`timescale 1ns/1ps

module Fetch(
    input Branch, branch_taken, Jump, ALUSrc,
    input [31:0] pc, pc_imm, rs1_imm,
    output reg [31:0] next_pc,
    output reg ID_Flush, EX_Flush
);

    always @ (*) begin

        ID_Flush = 0;
        EX_Flush = 0;
        
        // Branch Instruction Logic
        if (Branch && branch_taken) begin

            next_pc = pc_imm;
            ID_Flush = 1;
            EX_Flush = 1;

        end
        // Jump Instruction Logic
        else if (Jump) begin 

            ID_Flush = 1;
            if (ALUSrc == 0) next_pc = pc_imm; // JAL
            else begin
                
                next_pc = rs1_imm & 32'hFFFFFFFE; // JALR, clear lsb to ensure word alignment
                EX_Flush = 1;

            end

        end
        else next_pc = pc+4;

    end


endmodule