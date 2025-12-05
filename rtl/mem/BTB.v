`timescale 1ns/1ps

module BTB (
    input clk, rst_n, write,
    input [12:0] pc,
    input [31:0] pc_imm_in
    output reg [31:0] pc_imm_out,
    output hit
);

    // 2-way set associative cache
    localparam NUM_OF_LINES = 32, 
                LINES_PER_SET = 2, 
                TAG_WIDTH = 9, 
                SET_ID_WIDTH = 4,
                LINE_WIDTH = 43

    reg [LINE_WIDTH-1:0] branch_target_buffer [NUM_OF_LINES-1:0] // width = tag_bits + pc_imm + valid bit + FIFO bit

    wire [TAG_WIDTH-1:0] tag;
    wire [SET_ID_WIDTH-1:0] set_id;
    wire [4:0] line_id1, line_id2;

    assign tag = pc[12:4];
    assign set_id = pc[3:0];
    assign line_id1 = set_id*LINES_PER_SET;
    assign line_id2 = line_id1+1;

    // For Valid bit, 1 means the pc_imm value is valid
    // For FIFO bit, 1 means the line came in first

    wire valid1, valid2, fifo1, fifo2;
    assign valid1 = branch_target_buffer[line_id1][1];
    assign valid2 = branch_target_buffer[line_id2][1];
    assign fifo1 = branch_target_buffer[line_id1][0];
    assign fifo2 = branch_target_buffer[line_id2][0];

    wire [8:0] tag1, tag2;
    assign tag1 = branch_target_buffer[line_id1][LINE_WIDTH-1:32+2];
    assign tag2 = branch_target_buffer[line_id2][LINE_WIDTH-1:32+2];

    wire [31:0] pc_imm1, pc_imm2;
    assign pc_imm1 = branch_target_buffer[line_id1][LINE_WIDTH-TAG_WIDTH-1:2];
    assign pc_imm2 = branch_target_buffer[line_id2][LINE_WIDTH-TAG_WIDTH-1:2];
    
    wire set_full;
    assign set_full = valid1 && valid2;

    assign hit = (tag1 == tag && valid1) || (tag2 == tag && valid2);

    // BTB reads

    always @ (*) begin

        // if tag matches and valid bit is 1
        if (tag1 == tag && valid1) pc_imm_out = pc_imm1;
        if (tag2 == tag && valid2) pc_imm_out = pc_imm2;
        
    end

    integer i;

    // BTB writes

    always @ (posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < NUM_OF_LINES; i = i+1) begin

                branch_target_buffer[i] = 0;

            end

        end

        else begin 

            if (write) begin   

                // if data is invalid (ie after a reset) or set is full and current line was the first to come in
                if (!valid1 || set_full && fifo1) begin

                    if (!valid1) branch_target_buffer[line_id1][1] <= 1;
                    
                    branch_target_buffer[line_id1][0] <= 0;
                    branch_target_buffer[line_id2][0] <= 1;
                    pc_imm1 <= pc_imm_in; 

                end

                if (!valid2 || set_full && fifo2) begin

                    if (!valid2) branch_target_buffer[line_id2][1] <= 1;
                    
                    branch_target_buffer[line_id1][0] <= 1;
                    branch_target_buffer[line_id2][0] <= 0;
                    pc_imm1 <= pc_imm_in; 

                end

            end
            
        end


    end


endmodule