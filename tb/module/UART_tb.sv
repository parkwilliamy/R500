`timescale 1ns/1ps

class UARTInputs;

    rand logic [7:0] uart_data; 

endclass

module UART_tb;

    bit clk, rst_n, RX, TX_enable;
    bit [7:0] TX_data;
    logic TX, byte_done;
    logic [7:0] RX_data;
    logic [7:0] uart_data;

    UART DUT (
        .clk(clk), 
        .rst_n(rst_n), 
        .RX(RX), 
        .TX_enable(TX_enable),
        .TX_data(TX_data),
        .TX(TX), 
        .byte_done(byte_done),
        .RX_data(RX_data)
    );

    UARTInputs UARTTest = new;

    always #17.5 clk = ~clk;

    /* Test Plan

    RX Tests:

    1) Test Edge Cases (0x00, 0xFF)
    2) Test Random Bytes

    TX Tests:

    1) Same as RX

    */

    integer i;

    initial begin

        clk = 0;
        RX = 1; // initialize uart line to IDLE
        TX_enable = 0;
        TX_data = 0;

        rst_n = 0;
        #35;
        rst_n = 1;

        $display("================================= RX Tests ===================================\n");

        $display("Edge Cases\n");
        $display("Data: 0x00\n");

        #42.5;

        send_uart(8'h00);
        assert(RX_data == 8'h00);

        $display("Data: 0xFF\n");

        send_uart(8'hFF);
        assert(RX_data == 8'hFF);

        $display("Randomized Tests\n");

        repeat (5) begin

            UARTTest.randomize();
            uart_data = UARTTest.uart_data;
            send_uart(uart_data);
            assert(RX_data == uart_data);

        end

        $display("================================= TX Tests ===================================\n");

        TX_enable = 1;

        $display("Edge Cases\n");
        $display("Data: 0x00\n");

        TX_data = 8'h00;
        receive_uart(TX_data);
    
        $display("Data: 0xFF\n");
        
        TX_data = 8'hFF;
        receive_uart(TX_data);

        $display("Randomized Tests\n");

        repeat (5) begin

            UARTTest.randomize();
            TX_data = UARTTest.uart_data;
            receive_uart(TX_data);

        end

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

    task automatic receive_uart(input [7:0] data);

        @(negedge TX);

        #500; // wait half baud time for start bit sample

        assert(TX == 0);

        for (i=0; i<8; i = i+1) begin

            #1000;
            assert(TX == data[i]);

        end

        #1000;
        assert(TX == 1);

    endtask


endmodule


