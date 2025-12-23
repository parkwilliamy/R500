`timescale 1ns/1ps

module StallUnit (
    input EX_MemRead, ID_MemWrite,
    input [4:0] EX_rd, ID_rs1, ID_rs2,
    input [2:0] ID_ValidReg,
    output reg Stall
);

    always @ (*) begin

        if (EX_MemRead && !ID_MemWrite) begin

            Stall = (EX_rd != 0) && (((EX_rd == ID_rs1) && ID_ValidReg[1])) || ((EX_rd == ID_rs2) && ID_ValidReg[2]); // Detect a load-use hazard

        end

        else Stall = 0;

    end


endmodule