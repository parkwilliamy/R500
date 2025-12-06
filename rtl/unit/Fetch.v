`timescale 1ns/1ps

module Fetch(
    input [1:0] IF2_branch_prediction, ID_branch_prediction, prediction_status, 
    input IF2_BTBhit, ID_BTBhit, IF2_Branch, IF2_Jump, ID_Branch, EX_Branch, ID_Jump, EX_Jump, ID_ALUSrc, EX_ALUSrc,
    input [31:0] IF1_pc, IF2_pc_imm, EX_pc_4, ID_pc_imm, EX_pc_imm, rs1_imm,
    output [31:0] IF1_pc_4,
    output reg [31:0] next_pc,
    output reg IF2_Flush, ID_Flush, EX_Flush
);

    assign IF1_pc_4 = IF1_pc+4;

    always @ (*) begin

        IF2_Flush = 0;
        ID_Flush = 0;
        EX_Flush = 0;
        next_pc = IF1_pc_4;

        if (IF2_BTBhit) begin

            if (IF2_Branch) begin

                if (IF2_branch_prediction == 2'b10 || IF2_branch_prediction == 2'b11) next_pc = IF2_pc_imm;

            end

            else if (IF2_Jump) next_pc = IF2_pc_imm;
            
        end

        if ((ID_Branch || ID_Jump) && !ID_BTBhit) begin

            if (ID_Branch) begin

                if (ID_branch_prediction == 2'b10 || ID_branch_prediction == 2'b11) begin

                    next_pc = ID_pc_imm;
                    IF2_Flush = 1;
                    ID_Flush = 1;

                end

            end

            // Jump Instruction Logic
            else if (ID_Jump && ID_ALUSrc == 0) begin 

                next_pc = ID_pc_imm; // JAL
                IF2_Flush = 1;
                ID_Flush = 1;
                
            end

        end

        if (EX_Branch) begin

            case (prediction_status)

                0: begin

                    next_pc = EX_pc_imm;
                    IF2_Flush = 1;
                    ID_Flush = 1;
                    EX_Flush = 1;

                end

                1: begin

                    next_pc = EX_pc_4;
                    IF2_Flush = 1;
                    ID_Flush = 1;

                end

            endcase

        end

        else if (EX_Jump && EX_ALUSrc != 0) begin
            
            IF2_Flush = 1;
            ID_Flush = 1;
            EX_Flush = 1;
            next_pc = rs1_imm & 32'hFFFFFFFE; // JALR, clear lsb to ensure word alignment
            
        end

    end


endmodule