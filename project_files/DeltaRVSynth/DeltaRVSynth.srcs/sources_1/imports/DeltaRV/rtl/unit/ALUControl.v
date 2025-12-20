`timescale 1ns/1ps

module ALUControl(
    input [6:0] funct7,
    input [2:0] funct3,
    input [1:0] ALUOp,
    input regbit,
    output reg [3:0] field
);

    always @(*) begin
    
        field = 4'b0000;

        case (ALUOp)

            0: begin

                if (regbit) field = {funct7[5], funct3}; // R-type format
                else begin // I-type format

                    if (funct3 == 3'b001 || funct3 == 3'b101) field = {funct7[5], funct3}; 
                    else field = {1'b0, funct3};

                end

            end
            1: field = 4'b0000; 
            2: field = 4'b1000;

        endcase


    end

endmodule