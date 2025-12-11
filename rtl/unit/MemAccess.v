`timescale 1ns/1ps

module MemAccess (
    input clk, rst_n, byte_done,
    input [7:0] RX_data,
    input [31:0] dob,
    output reg TX_enable,
    output reg [15:0] addra, addrb
    output reg [3:0] wea,
    output reg [31:0] dia,
    output reg [7:0] TX_data
);

    localparam ADDR_WIDTH = 13;
    localparam IDLE = 3'b000, WRITE = 3'b001, READ_1 = 3'b010, READ_2 = 3'b011, READ_3 = 3'b100;
    reg [2:0] current_state, next_state;

    reg [55:0] write_frame;
    reg [31:0] read_frame;
    reg [2:0] msgidx;
    reg [15:0] ADDR_LOW, ADDR_HIGH, word_idx;

    integer i;

    always @ (posedge clk) begin

        if (!rst_n) begin

            current_state <= IDLE;

            for (i=0; i < 8; i = i+1) begin

                write_frame[i] <= 0;

            end

            for (i=0; i < 4; i = i+1) begin

                read_frame[i] <= 0;

            end

            msgidx <= 0;
            word_idx <= 0;
            TX_enable <= 0;
            TX_data <= 0;
            addra <= 0;
            addrb <= 0;

        end

        else begin

            current_state <= next_state;

            case (current_state)

                IDLE: begin
                    
                    msgidx <= 0;
                    word_idx <= 0;
                    TX_enable <= 0;
                    TX_data <= 0;
                    addra <= 0;
                    addrb <= 0;
                    
                end

                WRITE: begin

                    if (msgidx == 6) begin

                        addra <= write_frame[ADDR_WIDTH-1:0];
                        wea <= write_frame[19:16];
                        dia <= write_frame[55:24];
                        TX_enable <= 1;

                    end

                    else msgidx <= msgidx+1;

                    write_frame <= {RX_data, write_frame[55:8]};

                end

                READ_1: begin

                    if (msgidx == 3) begin

                        ADDR_LOW <= read_frame[ADDR_WIDTH-1:0];
                        ADDR_HIGH <= read_frame[ADDR_WIDTH-1+16:16];
                        addrb <= read_frame[ADDR_WIDTH-1:0];

                    end

                    else msgidx <= msgidx+1;

                    read_frame[msgidx] <= {RX_data, read_frame[31:8]};

                end

                READ_2: begin

                    word_idx <= (word_idx+1)%4; // used to loop between 0-3 and select parts of data word to transmit
                    TX_data <= dob[7+8*word_idx -: 8];

                end

                READ_3: begin

                    if (byte_done && word_idx == 0) addrb <= addrb+4; // once a word is finished transmitting

                end

            endcase

        end

    end

    // STATE TRANSITION LOGIC

    always @ (*) begin

        case(current_state) 

            IDLE: begin

                if (RX_data == 8'h0F) next_state = WRITE;
                else if (RX_data == 8'hFF) next_state = READ_1;
                else next_state = IDLE;

            end

            WRITE: begin

                if (msgidx == 6) next_state = IDLE;
                else next_state = WRITE;

            end

            READ_1: begin

                if (msgidx == 3) next_state = READ_2;
                else next_state = READ_1;

            end

            READ_2: next_state = READ_3;

            READ_3: begin

                if (byte_done) begin

                    if (addrb == ADDR_HIGH-4) next_state = IDLE; // if last word was transmitted
                    else next_state = READ_2; // if data still being transmitted from BRAM

                end

                else next_state = READ_3; // wait until UART module indicates it is finished sending a byte to host pc

            end


        endcase

    end



endmodule