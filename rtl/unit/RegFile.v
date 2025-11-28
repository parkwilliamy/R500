`timescale 1ns/1ps

module RegFile (
    input clk, RegWrite,
    input [4:0] rs1, rs2, rd,
    input [31:0] rd_write_data,
    output [31:0] rs1_data, rs2_data 
);

    reg [31:0] reg_file [31:0];

    assign rs1_data = reg_file[rs1];
    assign rs2_data = reg_file[rs2];
    assign rd_data = reg_file[rd];

    integer i;

    initial begin

        for (i = 0; i < 32; i = i+1) begin
            reg_file[i] = 0;
        end

    end

    always @(posedge clk) begin

        if (rd > 0 && RegWrite) reg_file[rd] <= rd_write_data; // ensure address written to is from 1-31 and RegWrite is HIGH
        
    end
    


endmodule