`timescale 1ns/1ps

class LSUInputs;

    rand logic [31:0] addrb_byte, addrb_hw, addrb_word, DMEM_word, rs2_data;

    constraint addr_space {
        addrb_byte inside {[32'h00005000:32'h00008000]};
        addrb_hw inside {[32'h00005000:32'h00007FFE]};
        addrb_word inside {[32'h00005000:32'h00007FFC]};
    }

    constraint addr_alignment {
        addrb_hw % 2 == 0;
        addrb_word % 4 == 0;
    }


endclass

module LSU_tb;

    bit MemWrite, MemRead;
    bit [31:0] addrb, DMEM_word, rs2_data;
    bit [2:0] funct3;
    logic [3:0] web;
    logic [31:0] dib, DMEM_result;

    LSU DUT (
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .addrb(addrb),
        .DMEM_word(DMEM_word), 
        .rs2_data(rs2_data),
        .funct3(funct3),
        .web(web),
        .dib(dib),
        .DMEM_result(DMEM_result)
    );

    wire [1:0] byte_offset;
    assign byte_offset = addrb % 4;
    wire [31:0] DMEM_shifted_word; // for loads
    assign DMEM_shifted_word = DMEM_word >> 8*byte_offset;

    LSUInputs LSUTest = new;

    /* Test Plan

    * ALL INPUTS ARE ALIGNED BASED ON THEIR INSTRUCTION TYPE

    1) Load Tests

    - data must be written accordingly based on funct3 (byte, halfword, word)

    2) Store Tests

    - web must be written accordingly based on funct3 (byte, halfword, word)

    */


    initial begin

        $display("==================================================================");

        $display("LOAD TESTS");

        $display("==================================================================");

        $display("Load Byte");

        MemRead = 1;
        MemWrite = 0;
        funct3 = 3'b000;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_byte;
            DMEM_word = LSUTest.DMEM_word;
            #5;
            $display("addrb: %08h, DMEM_word: %08h, DMEM_result: %08h", addrb, DMEM_word, DMEM_result);
            assert(DMEM_result[7:0] == DMEM_word[7+8*byte_offset -: 8]);

        end

        $display("Load Byte Unsigned");

        funct3 = 3'b0100;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_byte;
            DMEM_word = LSUTest.DMEM_word;
            #5;
            $display("addrb: %08h, DMEM_word: %08h, DMEM_result: %08h", addrb, DMEM_word, DMEM_result);
            assert(DMEM_result[7:0] == DMEM_word[7+8*byte_offset -: 8]);

        end

        $display("Load Halfword");

        funct3 = 3'b001;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_hw;
            DMEM_word = LSUTest.DMEM_word;
            #5;
            $display("addrb: %08h, DMEM_word: %08h, DMEM_result: %08h", addrb, DMEM_word, DMEM_result);
            assert(DMEM_result[15:0] == DMEM_word[15+8*byte_offset -: 16]);

        end

        $display("Load Halfword Unsigned");

        funct3 = 3'b0101;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_hw;
            DMEM_word = LSUTest.DMEM_word;
            #5;
            $display("addrb: %08h, DMEM_word: %08h, DMEM_result: %08h", addrb, DMEM_word, DMEM_result);
            assert(DMEM_result[15:0] == DMEM_word[15+8*byte_offset -: 16]);

        end

        $display("Load Word");

        funct3 = 3'b010;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_word;
            DMEM_word = LSUTest.DMEM_word;
            #5;
            $display("addrb: %08h, DMEM_word: %08h, DMEM_result: %08h", addrb, DMEM_word, DMEM_result);
            assert(DMEM_result == DMEM_word);

        end

        $display("==================================================================");

        $display("STORE TESTS");

        $display("==================================================================");

        $display("Store Byte");

        MemRead = 0;
        MemWrite = 1;
        funct3 = 3'b000;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_byte;
            rs2_data = LSUTest.rs2_data;
            #5;
            $display("addrb: %08h, rs2_data: %08h, web: %04b, dib: %08h", addrb, rs2_data, web, dib);
            assert(dib[7+8*byte_offset -: 8] == rs2_data[7:0]);
            assert(web == 4'b0001 << byte_offset);

        end

        $display("Store Halfword");

        funct3 = 3'b001;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_hw;
            rs2_data = LSUTest.rs2_data;
            #5;
            $display("addrb: %08h, rs2_data: %08h, web: %04b, dib: %08h", addrb, rs2_data, web, dib);
            assert(dib[15+8*byte_offset -: 16] == rs2_data[15:0]);
            assert(web == 4'b0011 << byte_offset);

        end

        $display("Store Word");

        MemRead = 0;
        MemWrite = 1;
        funct3 = 3'b010;

        repeat (5) begin

            LSUTest.randomize();
            addrb = LSUTest.addrb_word;
            rs2_data = LSUTest.rs2_data;
            #5;
            $display("addrb: %08h, rs2_data: %08h, web: %04b, dib: %08h", addrb, rs2_data, web, dib);
            assert(dib == rs2_data);
            assert(web == 4'b1111);

        end

        $display("Tests Finished!");
    
        $finish;
    

    end



endmodule