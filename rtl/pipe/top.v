`timescale 1ns/1ps

module top (
    input clk, rst_n_mem, rst_n_cpu, rst_clk, mem_control, RX,
    output TX,
    output [15:0] led
);

    wire [3:0] wea, web;
    wire [15:0] addra, addrb; // 32 KB for IMEM and DMEM total
    wire [15:0] addra_cpu, addrb_cpu;
    wire [15:0] addra_mem, addrb_mem;
    wire [31:0] doa, dob; // Port A is IMEM, Port B is DMEM
    wire [31:0] dia, dib;
    
    wire [15:0] row_a, row_b;
    
    // mem_control determines what device has control of BRAM addressing, 0 is CPU, 1 is MemAccess for reading/writing RAM
    
    assign row_a = mem_control ? addra_mem >> 2 : addra_cpu >> 2;
    assign row_b = mem_control ? addrb_mem >> 2 : addrb_cpu >> 2;
  
    wire clk_out1;
    
    clk_wiz_0 INST1 (
        
      // Clock out ports  
      .clk_out1(clk_out1),
      // Status and control signals               
      .reset(rst_clk), 
      .locked(),
     // Clock in ports
      .clk_in1(clk)
    );
    
    // byte addressable memory that uses the nearest word as an index
    blk_mem_gen_0 INST2 ( 
        .clka(clk_out1),
        .clkb(clk_out1),
        .wea(wea),
        .web(web),
        .addra(row_a[12:0]),
        .addrb(row_b[12:0]),
        .dina(dia),
        .dinb(dib),
        .douta(doa),
        .doutb(dob)
    );
    

    CPU INST3 (
        .clk(clk_out1),
        .rst_n(rst_n_cpu),
        .doa(doa),
        .dob(dob),
        .addra(addra_cpu),
        .addrb(addrb_cpu),
        .web(web),
        .dib(dib)
    );

    wire TX_enable, byte_done;
    wire [7:0] TX_data, RX_data;
    
    assign led[15:2] = addra_cpu[15:2];
    assign led[1] = byte_done;
    assign led[0] = TX_enable;

    (* DONT_TOUCH = "yes" *) UART INST4 (
        .clk(clk_out1),
        .rst_n(rst_n_mem),
        .RX(RX),
        .TX_enable(TX_enable),
        .TX_data(TX_data),
        .TX(TX),
        .byte_done(byte_done),
        .RX_data(RX_data)
    );
    
    (* DONT_TOUCH = "yes" *) MemAccess INST5 (
        .clk(clk_out1),
        .rst_n(rst_n_mem),
        .byte_done(byte_done),
        .RX_data(RX_data),
        .dob(dob),
        .TX_enable(TX_enable),
        .addra(addra_mem),
        .addrb(addrb_mem),
        .wea(wea),
        .dia(dia),
        .TX_data(TX_data)
    );


endmodule