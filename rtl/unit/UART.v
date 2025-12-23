`timescale 1ns/1ps

module UART (
    input clk, rst_n, RX, TX_enable,
    input [7:0] TX_data,
    output reg TX, byte_done, // byte_done indicates when a byte is done being received on RX or transmitted on TX
    output reg [7:0] RX_data
);

    // This module assumes a baud rate of 1Mb/s with clock of 57MHz
    localparam MAX_COUNT = 56,
               IDLE = 3'b000, 
               START_RX = 3'b001, 
               START_TX = 3'b010, 
               DATA_RX = 3'b011,
               DATA_TX = 3'b100,
               STOP_RX = 3'b101,
               STOP_TX = 3'b110;

    reg [2:0] current_state, next_state;
    reg [5:0] baud_count; // Counter for sampling data on RX line or triggering baud tick on TX line
    reg [2:0] data_idx; // Index to track data bits during a transaction
    reg baud_tick;
    reg [7:0] data_buffer; // Shift register to hold sampled data from RX line

    reg [1:0] RX_buffer; // Holds sampled values of RX line to detect falling edge
    wire RX_negedge;
    assign RX_negedge = RX_buffer[1] && !RX_buffer[0];

    always @ (posedge clk) begin

        if (!rst_n) begin

            current_state <= 0;
            baud_count <= 0;
            data_idx <= 0;
            baud_tick <= 0;
            data_buffer <= 0;
            RX_buffer <= 0;
            RX_data <= 0;
            TX <= 1;
            byte_done <= 0;

        end

        else begin

            current_state <= next_state;
            RX_buffer <= {RX_buffer[0], RX};
            baud_count <= baud_count+1;

            case(current_state) 

                IDLE: begin

                    if (RX_negedge) baud_count <= 28; // START_RX baud counter from halfway for half baud tick
                    else if (TX_enable && baud_tick) begin

                        baud_count <= 0; // Reset baud count
                        baud_tick <= 0;
                        TX <= 0; // Set start bit
                        data_idx <= 0;

                    end

                    byte_done <= 0;
                    data_buffer <= 0;
                    

                end

                // RX LOGIC

                START_RX: begin

                    if (baud_tick) data_idx <= 0; // Reset index to 0 before transition to DATA_RX

                end

                DATA_RX: begin

                    if (baud_tick) begin

                        data_idx <= data_idx+1;
                        data_buffer <= {RX, data_buffer[7:1]};

                    end

                end

                STOP_RX: begin

                    if (baud_tick) begin
                        
                        RX_data <= data_buffer;
                        byte_done <= 1;

                    end

                end

                // TX LOGIC

                START_TX: begin

                    if (baud_tick) begin
                        
                        TX <= TX_data[data_idx];
                        data_idx <= data_idx+1;
                        
                    end

                end

                DATA_TX: begin

                    if (baud_tick) begin
                        
                        if (data_idx != 7) data_idx <= data_idx+1;
                        TX <= TX_data[data_idx];

                    end
                    
                end

                STOP_TX: begin

                    if (baud_tick) begin
                        
                        byte_done <= 1;
                        TX <= 1; // stop bit

                    end

                end

            endcase

            if (baud_count == MAX_COUNT-1) begin

                baud_tick <= 1;
                baud_count <= 0;

            end

            else baud_tick <= 0;

        end


    end

    // State Transition Logic

    always @ (*) begin
        
        next_state = IDLE;

        case (current_state) 
        
            IDLE: begin

                if (RX_negedge) next_state = START_RX;
                else if (TX_enable && baud_tick) next_state = START_TX;
                else next_state = IDLE;

            end

            START_RX: begin

                if (baud_tick) begin
                    
                    if (!RX) next_state = DATA_RX;
                    else next_state = IDLE;

                end

                else next_state = START_RX;
                    
            end

            START_TX: begin

                if (baud_tick) next_state = DATA_TX;
                else next_state = START_TX;

            end

            DATA_RX: begin

                if (baud_tick) begin
                    
                    if (data_idx == 7) next_state = STOP_RX;
                    else next_state = DATA_RX;

                end
                else next_state = DATA_RX;

            end

            DATA_TX: begin

                if (baud_tick && data_idx == 7) next_state = STOP_TX;
                else next_state = DATA_TX;


            end

            STOP_RX: begin

                if (baud_tick && RX) next_state = IDLE;
                else next_state = STOP_RX;

            end

            STOP_TX: begin

                if (baud_tick) next_state = IDLE;
                else next_state = STOP_TX;

            end

        endcase

    end



endmodule