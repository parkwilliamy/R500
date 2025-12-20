`timescale 1ns/1ps

module top_tb_xsim ();

    reg rst_n, clk;
    reg [27:0] clk_cycles;
    reg [12:0] retired_instructions, predictions_made, correct_predictions; 
    top DUT (
        .rst_n(rst_n),
        .clk(clk),
        .clk_cycles(clk_cycles),
        .retired_instructions(retired_instructions),
        .predictions_made(predictions_made),
        .correct_predictions(correct_predictions)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    initial begin

        $readmemh("C:/Users/parkw/DeltaRV/tb/prog/hex/loop.hex", DUT.INST1.mem, 0);

        rst_n = 0;
        #20;
        rst_n = 1;
        #1000;
        $finish;

    end
   

endmodule