`timescale 1ns/1ps

module BTB (
    input clk, rst_n, write, ID_Branch,
    input [31:0] IF_pc, ID_pc,
    input [31:0] pc_imm_in, // Computed branch target address to write to BTB during ID
    output reg [31:0] pc_imm_out, // Branch target address to read from BTB in IF
    output hit, // 0 if branch target address wasn't found for a given branch instruction, 1 otherwise
    output reg IF_Branch, IF_Jump // These signals indicate whether the fetched target address was for a branch or jump instruction
);

    // 2-way set associative cache
    localparam NUM_OF_LINES = 32, 
                LINES_PER_SET = 2, 
                TAG_WIDTH = 26, 
                SET_ID_WIDTH = 4,
                LINE_WIDTH = 61;

    reg [LINE_WIDTH-1:0] branch_target_buffer [NUM_OF_LINES-1:0]; // Line = tag + pc_imm + branch bit + valid bit + FIFO bit

    // For Branch bit, 0 means jump, 1 means branch
    // For Valid bit, 1 means the pc_imm value is valid
    // For FIFO bit, 1 means the line came in first

    // Tags, Sets, and Lines are split into IF and ID signals because the BTB can be used in both IF and ID stages
    // BTB is read in IF, written in ID

    wire [TAG_WIDTH-1:0] IF_tag, ID_tag;
    wire [SET_ID_WIDTH-1:0] IF_set_id, ID_set_id;
    wire [4:0] IF_line_id1, IF_line_id2, ID_line_id1, ID_line_id2;

    assign IF_tag = IF_pc[31:6];
    assign IF_set_id = IF_pc[5:2];
    assign IF_line_id1 = IF_set_id*LINES_PER_SET;
    assign IF_line_id2 = IF_line_id1+1;

    assign ID_tag = ID_pc[31:6];
    assign ID_set_id = ID_pc[5:2];
    assign ID_line_id1 = ID_set_id*LINES_PER_SET;
    assign ID_line_id2 = ID_line_id1+1;

    wire IF_branch1, IF_branch2, IF_valid1, IF_valid2, IF_fifo1, IF_fifo2;
    assign IF_branch1 = branch_target_buffer[IF_line_id1][2];
    assign IF_branch2 = branch_target_buffer[IF_line_id2][2];
    assign IF_valid1 = branch_target_buffer[IF_line_id1][1];
    assign IF_valid2 = branch_target_buffer[IF_line_id2][1];
    assign IF_fifo1 = branch_target_buffer[IF_line_id1][0];
    assign IF_fifo2 = branch_target_buffer[IF_line_id2][0];

    wire ID_branch1, ID_branch2, ID_valid1, ID_valid2, ID_fifo1, ID_fifo2;
    assign ID_branch1 = branch_target_buffer[ID_line_id1][2];
    assign ID_branch2 = branch_target_buffer[ID_line_id2][2];
    assign ID_valid1 = branch_target_buffer[ID_line_id1][1];
    assign ID_valid2 = branch_target_buffer[ID_line_id2][1];
    assign ID_fifo1 = branch_target_buffer[ID_line_id1][0];
    assign ID_fifo2 = branch_target_buffer[ID_line_id2][0];

    wire [TAG_WIDTH-1:0] IF_tag1, IF_tag2;
    assign IF_tag1 = branch_target_buffer[IF_line_id1][LINE_WIDTH-1:32+3];
    assign IF_tag2 = branch_target_buffer[IF_line_id2][LINE_WIDTH-1:32+3];

    wire [31:0] pc_imm1, pc_imm2;
    assign pc_imm1 = branch_target_buffer[IF_line_id1][LINE_WIDTH-TAG_WIDTH-1:3];
    assign pc_imm2 = branch_target_buffer[IF_line_id2][LINE_WIDTH-TAG_WIDTH-1:3];
    
    wire set_full;
    assign set_full = ID_valid1 && ID_valid2;

    assign hit = ((IF_tag1 == IF_tag && IF_valid1) || (IF_tag2 == IF_tag && IF_valid2));
    

    // =============================== BTB Reads ================================

    always @ (*) begin

        IF_Branch = 0;
        IF_Jump = 0;
        pc_imm_out = 0;

        // If tag matches and valid bit is 1
        if (IF_tag1 == IF_tag && IF_valid1) begin
            
            if (!IF_branch1) begin

                IF_Branch = 0;
                IF_Jump = 1;

            end

            else begin

                IF_Branch = 1;
                IF_Jump = 0;

            end

            pc_imm_out = pc_imm1;

        end

        if (IF_tag2 == IF_tag && IF_valid2) begin
            
            if (!IF_branch2) begin

                IF_Branch = 0;
                IF_Jump = 1;

            end

            else begin

                IF_Branch = 1;
                IF_Jump = 0;

            end

            pc_imm_out = pc_imm2;

        end
        
    end


    // =============================== BTB Writes ================================

    // Cache writes to the first invalid line it finds, otherwise, replace the oldest line (FIFO bit of 1)

    integer i;

    always @ (posedge clk) begin

        if (!rst_n) begin

            for (i = 0; i < NUM_OF_LINES; i = i+1) begin

                branch_target_buffer[i] <= 61'h4; // Initialize branch bit to 1, valid bit to 0, FIFO bit to 0

            end

        end

        else begin 

            if (write) begin   

                // If data is invalid (i.e. after a reset) or set is full and current line is the oldest
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