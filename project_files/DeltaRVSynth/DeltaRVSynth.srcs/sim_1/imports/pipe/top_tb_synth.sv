`timescale 1ns/1ps

module top_tb_synth ();

    reg rst_n, clk, led;
    
    top DUT (
        .rst_n(rst_n),
        .clk(clk),
        .led(led)
    );
    
    integer i;

    // Clock generation
    initial begin
        clk = 0;
        forever #8.75 clk = ~clk;  // 57.14 MHz
    end

    initial begin

        rst_n = 0;
        #20;
        rst_n = 1;
        #1000;
/*
        $display("Displaying Regfile Entries");

        for (i = 0; i < 32; i = i+1) begin
            $display(DUT.INST4.reg_file[i]);
        end
*/
        $finish;

    end
   

endmodule