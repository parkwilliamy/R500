`timescale 1ns/1ps

module MemAccess (
    input clk, rst_n, byte_done,
    input [7:0] RX_data, // Received data from sender
    input [31:0] dob,
    output reg TX_enable, // Indicates when data can be transmitted over TX
    output reg [15:0] addra, addrb,
    output reg [3:0] wea,
    output reg [31:0] dia,
    output reg [7:0] TX_data // Data to transmit over TX
);

    localparam ADDR_WIDTH = 16;
    localparam IDLE = 3'b000, WRITE_1 = 3'b001, WRITE_2 = 3'b010, READ_1 = 3'b011, READ_2 = 3'b100, READ_3 = 3'b101, READ_4 = 3'b110, READ_5 = 3'b111;
    reg [2:0] current_state, next_state;

    // Buffers to hold bytes until message can be processed
    reg [55:0] write_frame;
    reg [31:0] read_frame;

    reg [2:0] msgidx; // Byte index used during data reception on RX
    reg [1:0] word_idx; // Word index used during BRAM data transmission on TX
    reg [15:0] ADDR_HIGH; // Stores last address to read data from in a read message

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

                // Pack bytes into write frame

                WRITE_1: begin

                    if (byte_done) begin

                        msgidx <= msgidx+1;
                        write_frame <= {RX_data, write_frame[55:8]};

                    end

                end

                // Process write message and set BRAM inputs accordingly

                WRITE_2: begin

                    addra <= write_frame[ADDR_WIDTH-1:0];
                    wea <= write_frame[19:16];
                    dia <= write_frame[55:24];

                end

                // Pack bytes into read frame

                READ_1: begin

                    if (byte_done) begin

                        msgidx <= msgidx+1;
                        read_frame <= {RX_data, read_frame[31:8]};

                    end

                end

                // Process read message, set BRAM address with ADDR_LOW, and store ADDR_HIGH for later

                READ_2: begin

                    ADDR_HIGH <= read_frame[ADDR_WIDTH-1:0];
                    addrb <= read_frame[ADDR_WIDTH-1+16:16]; // ADDR_LOW
                    

                end

                // Begin BRAM data transmission over TX

                READ_4: begin

                    TX_data <= dob[7:0];
                    word_idx <= word_idx+1;
                    TX_enable <= 1;

                end
                    
                // Continue BRAM data transmission over TX until data from ADDR_HIGH is transmitted

                READ_5: begin

                    if (byte_done) begin

                        word_idx <= (word_idx+1)%4; // used to loop between 0-3 and select parts of data word to transmit
                        if (addrb != ADDR_HIGH+4) TX_data <= dob[7+8*word_idx -: 8];
                        else TX_enable <= 0;
                        if (word_idx == 3) addrb <= addrb+4;

                    end

                end

               
            endcase

        end

    end

    // State Transition Logic

    always @ (*) begin

        case(current_state) 

            IDLE: begin

                if (RX_data == 8'h0F && byte_done) next_state = WRITE_1;
                else if (RX_data == 8'hFF && byte_done) next_state = READ_1;
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

            READ_3: begin // This is a buffer state to allow BRAM 1 clock cycle to output data at the address previously set in the READ_2 state

                next_state = READ_4;

            end

            READ_4: begin

                next_state = READ_5;

            end

            READ_5: begin
                
                // If address is beyond ADDR_HIGH and last data byte is done transmitting
                if (addrb == ADDR_HIGH+4 && byte_done) next_state = IDLE;
                else next_state = READ_5;

            end

        endcase

    end



endmodule