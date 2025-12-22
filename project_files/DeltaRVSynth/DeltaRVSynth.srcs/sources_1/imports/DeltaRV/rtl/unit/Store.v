`timescale 1ns/1ps

module Store (
    input MemWrite,
    input [31:0] addrb, rs2_data, clk_cycles, invalid_clk_cycles, retired_instructions, correct_predictions, total_predictions,
    input [2:0] funct3,
    output reg [3:0] web,
    output reg [31:0] dib
);

    wire [1:0] byte_offset;
    assign byte_offset = addrb % 4;

    localparam CLK_CYCLE_ADDR = 32'h5000, INVALID_CLK_CYCLE_ADDR = 32'h5004, RETIRED_INSTRUCTIONS_ADDR = 32'h5008, CORRECT_PREDICTIONS_ADDR = 32'h500C, TOTAL_PREDICTIONS_ADDR = 32'h5010;

    reg [31:0] final_data;

    always @ (*) begin

        web = 0;
        dib = 0;

        case (addrb) 

            CLK_CYCLE_ADDR: final_data = clk_cycles;
            INVALID_CLK_CYCLE_ADDR: final_data = invalid_clk_cycles;
            RETIRED_INSTRUCTIONS_ADDR: final_data = retired_instructions;
            CORRECT_PREDICTIONS_ADDR: final_data = correct_predictions;
            TOTAL_PREDICTIONS_ADDR: final_data = total_predictions;
            default: final_data = rs2_data;

        endcase

        if (MemWrite) begin

                case (funct3) 

                    3'b000: begin // SB
                        
                        web = (4'b0001 << byte_offset);
                        dib[7+8*byte_offset -: 8] = final_data[7:0]; 

                    end

                    3'b001: begin // SH

                        web = (4'b0011 << byte_offset);
                        dib[15+8*byte_offset -: 16] = final_data[15:0]; 
                    
                    end

                    3'b010: begin // SW

                        web = 4'b1111;
                        dib = final_data;

                    end
                
                endcase
             
        end

    end


endmodule