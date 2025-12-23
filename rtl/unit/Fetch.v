`timescale 1ns/1ps

module Fetch (
    input [1:0] IF_branch_prediction, ID_branch_prediction, prediction_status, 
    input IF_BTBhit, ID_BTBhit, IF_Branch, IF_Jump, ID_Branch, EX_Branch, ID_Jump, EX_Jump, ID_ALUSrc, EX_ALUSrc,
    input [31:0] IF_pc, IF_pc_imm, EX_pc_4, ID_pc_imm, EX_pc_imm, rs1_imm,
    output [31:0] IF_pc_4,
    output reg [31:0] next_pc,
    output reg ID_Flush, EX_Flush
);

    assign IF_pc_4 = IF_pc+4; // This result is computed once in IF and used later in the pipeline if needed

    always @ (*) begin

        ID_Flush = 0;
        EX_Flush = 0;
        next_pc = IF_pc_4;

        // IF Branches/Jumps

        if (IF_BTBhit) begin // If target address found in BTB for given instruction

            if (IF_Branch) begin // Conditional branch based on prediction

                if (IF_branch_prediction == 2'b10 || IF_branch_prediction == 2'b11) next_pc = IF_pc_imm;

            end

            else if (IF_Jump) next_pc = IF_pc_imm; // Unconditional jump
            
        end

        // ID Branches/Jumps

        if ((ID_Branch || ID_Jump) && !ID_BTBhit) begin // If decoded instruction is a branch or jump and the BTB doesn't yet have the target address stored

            if (ID_Branch) begin

                if (ID_branch_prediction == 2'b10 || ID_branch_prediction == 2'b11) begin

                    next_pc = ID_pc_imm;
                    ID_Flush = 1; // 1 cycle penalty for ID branches

                end

            end

            // Jump Instruction Logic
            else if (ID_Jump && ID_ALUSrc == 0) begin // If decoded instruction is JAL (otherwise, JALR is resolved in EX)

                next_pc = ID_pc_imm; // JAL
                ID_Flush = 1; // 1 cycle penalty for ID jumps
                
            end

        end

        // EX Branches/Jumps

        if (EX_Branch) begin

            // Flush pipeline if prediction was incorrect

            case (prediction_status)

                0: begin

                    next_pc = EX_pc_imm;
                    ID_Flush = 1;
                    EX_Flush = 1;

                end

                1: begin

                    next_pc = EX_pc_4;
                    ID_Flush = 1;

                end

            endcase

        end

        else if (EX_Jump && EX_ALUSrc != 0) begin // JALR instruction
            
            ID_Flush = 1;
            EX_Flush = 1;
            next_pc = rs1_imm & 32'hFFFFFFFE; // JALR, clear lsb to ensure target address is word aligned
            
        end

    end


endmodule