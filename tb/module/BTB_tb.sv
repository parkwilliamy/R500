`timescale 1ns/1ps

class BTBInputs;

    rand logic [31:0] pc, pc_imm_in;

    constraint addr_space {
        pc inside {[0:32'h00005000]};
        pc_imm_in inside {[0:32'h00005000]};
    }

    constraint addr_alignment {
        pc % 4 == 0;
        pc_imm_in % 4 == 0;
    }

endclass

module BTB_tb;

    bit clk, rst_n, write;
    logic [12:0] pc;
    logic [31:0] pc_imm_in, pc_imm_out;
    logic hit;

    BTB DUT (
        .clk(clk), 
        .rst_n(rst_n),
        .write(write),
        .pc(pc),
        .pc_imm_in(pc_imm_in),
        .pc_imm_out(pc_imm_out),
        .hit(hit)
    );

    BTBInputs BTBTest = new;

    always #5 clk = ~clk;

    /* Test Plan

    1) Half Full Cache
        - verify exactly one line has FIFO bit = 1 
        - valid line should have valid bit = 1, and vice versa

    2) Full Cache
        - verify exactly one line has FIFO bit = 1 
        - all lines have valid bit = 1
        - repeated writes to a set should always assert the other line's FIFO bit (ie the line you didn't write to)

    READS

    - ensure hit bit is asserted when cache contains tag
    - test reads using both tags in and out of the cache

    */

    integer i;

    initial begin

        clk = 0;
        rst_n = 0;
        write = 0;
        #20;
        rst_n = 1;

        $display("Half Full Cache Tests");

        write = 1;

        repeat (5) begin

            // fill every set halfway (1/2 lines)

            for (i=0; i < 16; i = i+1) begin

                BTBTest.randomize();
                pc = {i[3:0], i[3:0], i[3], i[3:0]};
                pc_imm_in = BTBTest.pc_imm_in;
                #10;

            end

            write = 0;

            for (i=0; i < 16; i = i+1) begin

                assert(DUT.branch_target_buffer[2*i][1] == 1 && DUT.branch_target_buffer[2*i][0] == 0);
                assert(DUT.branch_target_buffer[2*i+1][1] == 0 && DUT.branch_target_buffer[2*i+1][0] == 1);

            end
            
        end

        $display("\n");
        $display("=================================================================");
        $display("\n");

        $display("Full Cache Tests");

        rst_n = 0;
        write = 1;
        #20;
        rst_n = 1;

        repeat (5) begin

            for (i=0; i < 16; i = i+1) begin

                BTBTest.randomize();
                pc = {BTBTest.pc[12:4], i[3:0]};
                pc_imm_in = BTBTest.pc_imm_in;
                #10;

                BTBTest.randomize();
                pc = {BTBTest.pc[12:4], i[3:0]};
                pc_imm_in = BTBTest.pc_imm_in;
                #10;

            end

            write = 0;

            for (i=0; i < 16; i = i+1) begin

                assert(DUT.branch_target_buffer[2*i][1] == 1 && DUT.branch_target_buffer[2*i][0] == 1);
                assert(DUT.branch_target_buffer[2*i+1][1] == 1 && DUT.branch_target_buffer[2*i+1][0] == 0);

            end

            $display("Repeated Writes To Set");

            write = 1;

            BTBTest.randomize();
            pc = BTBTest.pc;

            repeat (20) begin

                BTBTest.randomize();
                pc_imm_in = BTBTest.randomize();
                #10;
                assert(DUT.branch_target_buffer[2*pc[3:0]][1] && DUT.branch_target_buffer[2*pc[3:0]+1][1] == 1);
                assert(DUT.branch_target_buffer[2*pc[3:0]][0] ^ DUT.branch_target_buffer[2*pc[3:0]+1][0] == 1);

            end

            write = 0;
            

        end

        $display("\n");
        $display("=================================================================");
        $display("\n");

        $display("Read Tests");

        $display("Empty Cache Reads");

        rst_n = 0;
        #20;
        rst_n = 1;

        repeat (5) begin

            BTBTest.randomize();
            pc = BTBTest.pc;
            #5;
            assert(hit == 0);

        end

        $display("Full Cache Reads");

        write = 1;

        for (i=0; i < 16; i = i+1) begin

            BTBTest.randomize();
            pc = {i[3:0], i[3:0], i[3], i[3:0]};
            pc_imm_in = BTBTest.pc_imm_in;
            #10;

            BTBTest.randomize();
            pc_imm_in = BTBTest.pc_imm_in;
            #10;

        end

        write = 0;

        for (i=0; i < 16; i = i+1) begin

            $display("Line %0d Data: %0h", 2*i, DUT.branch_target_buffer[2*i][33:2]);
            $display("Line %0d Data: %0h", 2*i+1, DUT.branch_target_buffer[2*i+1][33:2]);

        end

        pc = 0;
        #5;
        assert(hit == 1);

        BTBTest.randomize();
        pc = BTBTest.pc;
        #5;
        assert(hit == 0);

        pc = 545;
        #5;
        assert(hit == 1);

        BTBTest.randomize();
        pc = BTBTest.pc;
        #5;
        assert(hit == 0);

        pc = 6011;
        #5;
        assert(hit == 1);

        $finish;

    

    end



endmodule