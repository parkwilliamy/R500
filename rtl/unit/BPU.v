`timescale 1ns/1ps

module BPU (
    input Branch, zero, sign, overflow, carry,
    input [2:0] funct3,
    output reg branch_taken
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

    end
    
endmodule