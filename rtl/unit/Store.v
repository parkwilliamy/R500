`timescale 1ns/1ps

module Store (
    input MemWrite,
    input [31:0] addrb, rs2_data,
    input [2:0] funct3,
    output reg [3:0] web,
    output reg [31:0] dib
);

    wire [1:0] byte_offset;
    assign byte_offset = addrb % 4;

    always @ (*) begin

        web = 0;
        dib = 0;

        if (MemWrite) begin

                case (funct3) 

                    3'b000: begin // SB
                        
                        web = (4'b0001 << byte_offset);
                        dib[7+8*byte_offset -: 8] = rs2_data[7:0]; 

                    end

                    3'b001: begin // SH

                        web = (4'b0011 << byte_offset);
                        dib[15+8*byte_offset -: 16] = rs2_data[15:0]; 
                    
                    end

                    3'b010: begin // SW

                        web = 4'b1111;
                        dib = rs2_data;

                    end
                
                endcase
             
        end

    end


endmodule