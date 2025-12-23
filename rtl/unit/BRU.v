`timescale 1ns/1ps

module BRU (
    input [1:0] EX_branch_prediction,
    input EX_Branch, zero, sign, overflow, carry,
    input [2:0] funct3,
    output branch_taken,
    output reg [1:0] prediction_status // 0 is predict not taken, taken - 1 is predict taken, not taken - 2 is predict not taken, not taken - 3 is predict taken, taken
);

    reg branch_taken_inter;
    assign branch_taken = branch_taken_inter;
    

    always @(*) begin

        branch_taken_inter = 0;
        prediction_status = 0;

        if (EX_Branch) begin
                
                case (funct3) 
                    
                    3'b000: branch_taken_inter = zero; // BGE
                    3'b001: branch_taken_inter = ~zero; // BNE
                    3'b100: branch_taken_inter = sign^overflow; // BLT
                    3'b101: branch_taken_inter = ~(sign^overflow); // BGE
                    3'b110: branch_taken_inter = carry; // BLTU
                    3'b111: branch_taken_inter = ~carry; // BGEU
                    
                endcase
        
            if (((EX_branch_prediction == 2'b00 || EX_branch_prediction == 2'b01) && branch_taken_inter)) begin

                prediction_status = 0;

            end

            else if (((EX_branch_prediction == 2'b10 || EX_branch_prediction == 2'b11) && !branch_taken_inter)) begin

                prediction_status = 1;

            end

            else if (((EX_branch_prediction == 2'b00 || EX_branch_prediction == 2'b01) && !branch_taken_inter)) begin

                prediction_status = 2;

            end

            else if (((EX_branch_prediction == 2'b10 || EX_branch_prediction == 2'b11) && branch_taken_inter)) begin

                prediction_status = 3;

            end
           
        end
      
    end
    
endmodule