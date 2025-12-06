`timescale 1ns/1ps

module BTB (
    input clk, rst_n, write, ID_Branch, ID_Jump,
    input [31:0] IF2_pc, ID_pc,
    input [31:0] pc_imm_in,
    output reg [31:0] pc_imm_out,
    output hit,
    output reg IF2_Branch, IF2_Jump
);

    // 2-way set associative cache
    localparam NUM_OF_LINES = 32, 
                LINES_PER_SET = 2, 
                TAG_WIDTH = 26, 
                SET_ID_WIDTH = 4,
                LINE_WIDTH = 61;

    reg [LINE_WIDTH-1:0] branch_target_buffer [NUM_OF_LINES-1:0]; // width = tag_bits + pc_imm + branch bit + valid bit + FIFO bit

    wire [TAG_WIDTH-1:0] IF2_tag, ID_tag;
    wire [SET_ID_WIDTH-1:0] IF2_set_id, ID_set_id;
    wire [4:0] IF2_line_id1, IF2_line_id2, ID_line_id1, ID_line_id2;

    assign IF2_tag = IF2_pc[31:6];
    assign IF2_set_id = IF2_pc[5:2];
    assign IF2_line_id1 = IF2_set_id*LINES_PER_SET;
    assign IF2_line_id2 = IF2_line_id1+1;

    assign ID_tag = ID_pc[31:6];
    assign ID_set_id = ID_pc[5:2];
    assign ID_line_id1 = ID_set_id*LINES_PER_SET;
    assign ID_line_id2 = ID_line_id1+1;

    // For Branch bit, 0 means jump, 1 means branch
    // For Valid bit, 1 means the pc_imm value is valid
    // For FIFO bit, 1 means the line came in first

    wire IF2_branch1, IF2_branch2, IF2_valid1, IF2_valid2, IF2_fifo1, IF2_fifo2;
    assign IF2_branch1 = branch_target_buffer[IF2_line_id1][2];
    assign IF2_branch2 = branch_target_buffer[IF2_line_id2][2];
    assign IF2_valid1 = branch_target_buffer[IF2_line_id1][1];
    assign IF2_valid2 = branch_target_buffer[IF2_line_id2][1];
    assign IF2_fifo1 = branch_target_buffer[IF2_line_id1][0];
    assign IF2_fifo2 = branch_target_buffer[IF2_line_id2][0];

    wire ID_branch1, ID_branch2, ID_valid1, ID_valid2, ID_fifo1, ID_fifo2;
    assign ID_branch1 = branch_target_buffer[ID_line_id1][2];
    assign ID_branch2 = branch_target_buffer[ID_line_id2][2];
    assign ID_valid1 = branch_target_buffer[ID_line_id1][1];
    assign ID_valid2 = branch_target_buffer[ID_line_id2][1];
    assign ID_fifo1 = branch_target_buffer[ID_line_id1][0];
    assign ID_fifo2 = branch_target_buffer[ID_line_id2][0];

    wire [TAG_WIDTH-1:0] IF2_tag1, IF2_tag2;
    assign IF2_tag1 = branch_target_buffer[IF2_line_id1][LINE_WIDTH-1:32+3];
    assign IF2_tag2 = branch_target_buffer[IF2_line_id2][LINE_WIDTH-1:32+3];

    wire [31:0] pc_imm1, pc_imm2;
    assign pc_imm1 = branch_target_buffer[IF2_line_id1][LINE_WIDTH-TAG_WIDTH-1:3];
    assign pc_imm2 = branch_target_buffer[IF2_line_id2][LINE_WIDTH-TAG_WIDTH-1:3];
    
    wire set_full;
    assign set_full = ID_valid1 && ID_valid2;

    assign hit = ((IF2_tag1 == IF2_tag && IF2_valid1) || (IF2_tag2 == IF2_tag && IF2_valid2));

    // BTB reads

    always @ (*) begin

        IF2_Branch = 0;
        IF2_Jump = 0;
        pc_imm_out = 0;

        // if tag matches and valid bit is 1
        if (IF2_tag1 == IF2_tag && IF2_valid1) begin
            
            if (!IF2_branch1) begin

                IF2_Branch = 0;
                IF2_Jump = 1;

            end

            else begin

                IF2_Branch = 1;
                IF2_Jump = 0;

            end

            pc_imm_out = pc_imm1;

        end

        if (IF2_tag2 == IF2_tag && IF2_valid2) begin
            
            if (!IF2_branch2) begin

                IF2_Branch = 0;
                IF2_Jump = 1;

            end

            else begin

                IF2_Branch = 1;
                IF2_Jump = 0;

            end

            pc_imm_out = pc_imm2;

        end
        
    end

    integer i;

    // BTB writes

    always @ (posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            for (i = 0; i < NUM_OF_LINES; i = i+1) begin

                branch_target_buffer[i] = 4; // set branch bit to 1 by default

            end

        end

        else begin 

            if (write) begin   

                // if data is invalid (ie after a reset) or set is full and current line was the first to come in
                if (!ID_valid1 || set_full && ID_fifo1) begin

                    branch_target_buffer[ID_line_id2][0] <= 1;
                    branch_target_buffer[ID_line_id1] <= {ID_tag, pc_imm_in, ID_Branch, 1'b1, 1'b0}; 

                end

                else if (!ID_valid2 || set_full && ID_fifo2) begin

                    branch_target_buffer[ID_line_id1][0] <= 1;
                    branch_target_buffer[ID_line_id2] <= {ID_tag, pc_imm_in, ID_Branch, 1'b1, 1'b0}; 

                end

            end
            
        end


    end


endmodule