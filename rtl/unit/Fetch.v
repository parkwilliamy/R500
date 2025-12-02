`timescale 1ns/1ps

module Fetch(
    input [1:0] ID_branch_prediction, prediction_status, 
    input ID_Branch, ID_Jump, EX_Jump, ID_ALUSrc, EX_ALUSrc,
    input [31:0] pc, ID_pc_imm, EX_pc_imm, rs1_imm,
    output reg [31:0] next_pc,
    output reg ID_Flush, EX_Flush
);

    wire [31:0] pc_4;
    assign pc_4 = pc+4;

    always @ (*) begin

        ID_Flush = 0;
        EX_Flush = 0;

        if (ID_Branch) begin

            if (ID_branch_prediction == 2'b10 || ID_branch_prediction == 2'b11) begin

                next_pc = ID_pc_imm;
                ID_Flush = 1;

            end

        end

        // Jump Instruction Logic
        else if (ID_Jump && ID_ALUSrc == 0) begin 

            ID_Flush = 1;
            next_pc = ID_pc_imm; // JAL

        end

        else next_pc = pc_4;

        if (EX_Branch) begin

            case (prediction_status)

                0: begin

                    next_pc = EX_pc_imm;
                    ID_Flush = 1;
                    EX_Flush = 1;

                end

                1: begin

                    next_pc = EX_pc+4;
                    ID_Flush = 1;

                end

            endcase

        end

        else if (EX_Jump && EX_ALUSrc != 0) begin
            
            ID_Flush = 1;
            EX_Flush = 1;
            next_pc = rs1_imm & 32'hFFFFFFFE; // JALR, clear lsb to ensure word alignment
            
        end

        else next_pc = pc_4;

    end


endmodule