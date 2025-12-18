`timescale 1ns/1ps

module MemAccess (
    input clk, rst_n, byte_done,
    input [7:0] RX_data,
    input [31:0] dob,
    output reg TX_enable,
    output reg [15:0] addra, addrb,
    output reg [3:0] wea,
    output reg [31:0] dia,
    output reg [7:0] TX_data
);

    localparam ADDR_WIDTH = 16;
    localparam IDLE = 3'b000, WRITE_1 = 3'b001, WRITE_2 = 3'b010, READ_1 = 3'b011, READ_2 = 3'b100, READ_3 = 3'b101, READ_4 = 3'b110, READ_5 = 3'b111;
    reg [2:0] current_state, next_state;

    reg [55:0] write_frame;
    reg [31:0] read_frame;
    reg [2:0] msgidx;
    reg [15:0] ADDR_HIGH;
    reg [1:0] word_idx;

    always @ (posedge clk) begin

        if (!rst_n) begin

            current_state <= IDLE;
            write_frame <= 0;
            read_frame <= 0;
            msgidx <= 0;
            word_idx <= 0;
            TX_enable <= 0;
            TX_data <= 0;
            addra <= 0;
            addrb <= 0;
            wea <= 0;
            dia <= 0;
            ADDR_HIGH <= 16'h7ffc;

        end

        else begin

            current_state <= next_state;

            case (current_state)

                IDLE: begin
                    
                    write_frame <= 0;
                    read_frame <= 0;
                    msgidx <= 0;
                    word_idx <= 0;
                    TX_enable <= 0;
                    TX_data <= 0;
                    addra <= 0;
                    addrb <= 0;
                    wea <= 0;
                    dia <= 0;
                    
                end

                WRITE_1: begin

                    if (byte_done) begin

                        msgidx <= msgidx+1;
                        write_frame <= {RX_data, write_frame[55:8]};

                    end

                end

                WRITE_2: begin

                    addra <= write_frame[ADDR_WIDTH-1:0];
                    wea <= write_frame[19:16];
                    dia <= write_frame[55:24];

                end

                READ_1: begin

                    if (byte_done) begin

                        msgidx <= msgidx+1;
                        read_frame <= {RX_data, read_frame[31:8]};

                    end

                end

                READ_2: begin

                    ADDR_HIGH <= read_frame[ADDR_WIDTH-1:0];
                    addrb <= read_frame[ADDR_WIDTH-1+16:16]; // ADDR_LOW
                    

                end

                READ_4: begin

                    TX_data <= dob[7:0];
                    word_idx <= word_idx+1;
                    TX_enable <= 1;

                end
                    

                READ_5: begin

                    if (byte_done) begin

                        word_idx <= (word_idx+1)%4; // used to loop between 0-3 and select parts of data word to transmit
                        if (addrb != ADDR_HIGH+4) TX_data <= dob[7+8*word_idx -: 8];
                        if (word_idx == 3) addrb <= addrb+4;

                    end

                end

               
            endcase

        end

    end

    // STATE TRANSITION LOGIC

    always @ (*) begin

        case(current_state) 

            IDLE: begin

                if (RX_data == 8'h0F) next_state = WRITE_1;
                else if (RX_data == 8'hFF) next_state = READ_1;
                else next_state = IDLE;

            end

            WRITE_1: begin

                if (msgidx == 6 && byte_done) next_state = WRITE_2;
                else next_state = WRITE_1;

            end

            WRITE_2: begin

                next_state = IDLE;

            end

            READ_1: begin

                if (msgidx == 3 && byte_done) next_state = READ_2;
                else next_state = READ_1;

            end

            READ_2: begin

                next_state = READ_3;

            end

            READ_3: begin

                next_state = READ_4;

            end

            READ_4: begin

                next_state = READ_5;

            end

            READ_5: begin
                
                if (addrb == ADDR_HIGH+4 && byte_done) next_state = IDLE;
                else next_state = READ_5;

            end

        endcase

    end



endmodule