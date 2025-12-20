`timescale 1ns/1ps

module WriteBack (
    input [31:0] ALU_result, pc_imm, pc_4,
    input [2:0] funct3,
    input [1:0] RegSrc,
    input [31:0] DMEM_word,
    output reg [31:0] rd_write_data
);

    wire [1:0] byte_offset;
    assign byte_offset = ALU_result % 4; // ALU_result is addrb (calculated addr)

    wire [31:0] DMEM_shifted_word; 
    assign DMEM_shifted_word = DMEM_word >> 8*byte_offset;

    reg [31:0] DMEM_result;

    always @ (*) begin
    
        DMEM_result = 32'b0;

        case (funct3) 
        
            3'b000: DMEM_result = {{24{DMEM_shifted_word[7]}}, DMEM_shifted_word[7:0]}; // LB
            3'b001: DMEM_result = {{16{DMEM_shifted_word[15]}}, DMEM_shifted_word[15:0]}; // LH
            3'b010: DMEM_result = DMEM_shifted_word; // LW
            3'b100: DMEM_result = {24'b0, DMEM_shifted_word[7:0]}; // LBU
            3'b101: DMEM_result = {16'b0, DMEM_shifted_word[15:0]}; // LHU

        endcase

        case (RegSrc) 

            0: rd_write_data = ALU_result;
            1: rd_write_data = DMEM_result;
            2: rd_write_data = pc_imm;
            3: rd_write_data = pc_4;

        endcase

    end


endmodule