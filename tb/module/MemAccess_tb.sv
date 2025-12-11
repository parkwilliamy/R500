`timescale 1ns/1ps

class MemAccessInputs;

    rand logic [15:0] addra, ADDR_LOW, ADDR_HIGH;
    rand logic [3:0] wea;
    rand logic [31:0] dia;

    constraint addr_alignment {
        addra % 4 == 0;
        ADDR_LOW % 4 == 0;
        ADDR_HIGH % 4 == 0;
    }

    constraint addr_space {
        addra inside {[16'h0000:16'h8000-4]};
        ADDR_LOW inside {[16'h0000:16'h8000-4]};
        ADDR_HIGH inside {[ADDR_LOW:16'h8000-4]};
    }

endclass

module MemAccess_tb;

    bit clk, rst_n, byte_done;
    bit [7:0] RX_data;
    bit [31:0] dob;
    logic TX_enable;
    bit [15:0] addra, addrb;
    bit [3:0] wea;
    bit [31:0] dia;
    logic [7:0] TX_data;
    logic [15:0] ADDR_LOW, ADDR_HIGH;

    MemAccess DUT (
        .clk(clk), 
        .rst_n(rst_n), 
        .byte_done(byte_done),
        .RX_data(RX_data),
        .dob(dob),
        .TX_enable(TX_enable),
        .addra(addra), 
        .addrb(addrb),
        .wea(wea),
        .dia(dia),
        .TX_data(TX_data)
    );

    bit [3:0] web;
    bit [31:0] doa;
    bit [31:0] dib;

    BRAM INST1 ( 
        .clk(clk),
        .wea(wea),
        .web(web),
        .addra(addra),
        .addrb(addrb),
        .dia(dia),
        .dib(dib),
        .doa(doa),
        .dob(dob)
    );

    logic TX, RX;

    UART INST2 (
        .clk(clk), 
        .rst_n(rst_n), 
        .RX(RX), 
        .TX_enable(TX_enable),
        .TX_data(TX_data),
        .TX(TX), 
        .byte_done(byte_done),
        .RX_data(RX_data)
    );

    MemAccessInputs MemAccessTest = new;

    always #17.5 clk = ~clk;

    /* Test Plan

    Write Messages (verify if addra, wea, and dia are set accordingly)
    1) Send Random Single Frames, ie only write to one addr with random data

    Read Messages (verify if memory regions are being written to correctly)
    1) Send Frame with ADDR_LOW = ADDR_HIGH
    2) Send Frame with 0 <= ADDR_LOW <= ADDR_HIGH

    */

    integer i; 

    initial begin 

        clk = 0;
        RX = 1;

        rst_n = 0;
        #37;
        rst_n = 1;

        #42.5

        $display("================================= WRITE Tests ===================================\n");

        repeat (10) begin

            MemAccessTest.randomize();
            send_write_frame(MemAccessTest.addra, MemAccessTest.wea, MemAccessTest.dia);
            $display("addra: %04h, wea: %04b, dia: %04h", MemAccessTest.addra, MemAccessTest.wea, MemAccessTest.dia);

        end

        $display("================================= READ Tests ===================================\n");

        
        ADDR_LOW = 16'h5000;
        ADDR_HIGH = 16'h500C;
        $display("ADDR_LOW: %04h, ADDR_HIGH: %04h", ADDR_LOW, ADDR_HIGH);
        send_read_frame(ADDR_LOW, ADDR_HIGH);

        #200000;

        $display("Tests Done!");

        $finish;

    end

    task automatic send_uart(input [7:0] data);

        RX = 0; // start bit
        #1000; // 1 baud time assuming 1Mb/s
        
        for (i=0; i < 8; i = i+1) begin

            RX = data[i];
            #1000;

        end

        RX = 1; // stop bit
        #1000;

    endtask

    task send_write_frame(input [15:0] addra, input [3:0] wea, input [31:0] data);

        send_uart(8'h0F); // start byte for WRITE mode
        send_uart(addra[7:0]);
        send_uart({addra[15:8]});
        send_uart({4'b0, wea});
        send_uart(data[7:0]);
        send_uart(data[15:8]);
        send_uart(data[23:16]);
        send_uart(data[31:24]);

    endtask

    task send_read_frame(input [15:0] ADDR_LOW, input [15:0] ADDR_HIGH);

        send_uart(8'hFF); // start byte for WRITE mode
        send_uart(ADDR_HIGH[7:0]);
        send_uart(ADDR_HIGH[15:8]);
        send_uart(ADDR_LOW[7:0]);
        send_uart(ADDR_LOW[15:8]);
        

    endtask


endmodule



