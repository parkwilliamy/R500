`timescale 1ns/1ps

module top_tb_xsim ();

    reg rst_n, clk; 
    top DUT (.rst_n(rst_n), .clk(clk));

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    initial begin

        $readmemh("C:/Users/parkw/DeltaRV/tb/prog/hex/JALR.hex", DUT.INST1.mem, 0);

        rst_n = 0;
        #20;
        rst_n = 1;
        #1000;
        $finish;

    end
   

endmodule