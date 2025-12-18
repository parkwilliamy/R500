`timescale 1ns/1ps

module BRAM (
    input clk,
    input [3:0] wea,
    input [3:0] web,
    // byte addresses
    input [31:0] addra, 
    input [31:0] addrb,
    input [31:0] dia,
    input [31:0] dib,
    output reg [31:0] doa,
    output reg [31:0] dob
);

    /* Simulation Memory (2 MB)
    localparam IMEM_START = 32'h00000000,
               IMEM_END   = 32'h00200000,
               DMEM_START = 32'h00200000,
               DMEM_END   = 32'h00250000;
    */
    
    // Synthesis Memory (32 KB)
    localparam IMEM_START = 32'h00000000,
               IMEM_END   = 32'h00005000,
               DMEM_START = 32'h00005000,
               DMEM_END   = 32'h00008000;
    

    reg [31:0] mem [IMEM_START/4:DMEM_END/4-1];
    integer i;
    wire [31:0] row_a, row_b;
    assign row_a = addra >> 2;
    assign row_b = addrb >> 2;
    
    initial begin

        for (i=0; i<DMEM_END/4; i=i+1) begin

            mem[i] = i;

        end

    end
    
    always @ (posedge clk) begin // READ FIRST MODE
        
        for (i = 0; i < 4; i = i+1) begin
            if (wea[i]) mem[row_a][8*i +:8] <= dia[8*i +:8];
        end
        doa <= mem[row_a];

        for (i = 0; i < 4; i = i+1) begin
            if (web[i]) mem[row_b][8*i +:8] <= dib[8*i +:8];
        end
        dob <= mem[row_b];

    end

endmodule