`timescale 1ns/1ps

module BRU (
    input [1:0] EX_branch_prediction,
    input EX_Branch, zero, sign, overflow, carry,
    input [2:0] funct3,
    output reg [1:0] prediction_status, // 0 is predict not taken, taken - 1 is predict taken, not taken - 2 is predict correctly
);

    always @(*) begin

        branch_taken = 0;

        if (Branch) begin
                
                case (funct3) 
                    
                    3'b000: branch_taken = zero; // BGE
                    3'b001: branch_taken = ~zero; // BNE
                    3'b100: branch_taken = sign^overflow; // BLT
                    3'b101: branch_taken = ~(sign^overflow); // BGE
                    3'b110: branch_taken = carry; // BLTU
                    3'b111: branch_taken = ~carry; // BGEU
                    
                endcase


        end

        if (EX_Branch) begin

            if (((EX_branch_prediction == 2'b00 || EX_branch_prediction == 2'b01) && branch_taken)) begin

                prediction_status = 0;

            end

            else if (((EX_branch_prediction == 2'b10 || EX_branch_prediction == 2'b11) && !branch_taken)) begin

                prediction_status = 1;

            end

            else prediction_status = 2;

        end

    end
    
endmodule