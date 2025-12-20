`timescale 1ns/1ps

class BRAMInputs;

    rand logic [31:0] addra, addrb, dia, dib;

    constraint addr_space {
        addra inside {[0:32'h00005000]};
        addrb inside {[32'h00005000:32'h00008000]};
    }

    constraint addr_alignment {
        addra % 4 == 0;
        addrb % 4 == 0;
    }

endclass

module BRAM_tb;

    bit clk;
    bit [3:0] wea, web;
    logic [31:0] addra, addrb, dia, dib, doa, dob;

    BRAM DUT ( 
        .clk(clk),
        .wea(wea),
        .web(web),
        .addra(addra),
        .addrb(addrb),
        .dia(dia),
        .dib(dib),
        .doa(doa),
        .dob(dob)
    );

    BRAMInputs BRAMTest = new;

    always #5 clk = ~clk;

    /* Test Plan

    - individual reads on ports
    - dual reads on ports
    Test byte, halfword, and word writes
    - individual writes on ports 
    - dual writes on ports

    */

    integer i;

    initial begin

        clk = 0;

        $display("READ on port A");

        wea = 0;
        web = 0;

        repeat (5) begin

            BRAMTest.randomize();
            addra = BRAMTest.addra;
            #10;
            $display("Address A: %0h, Data A: %0h", addra, doa);
            assert(doa == addra >> 2);

        end

        $display("READ on port B");

        repeat (5) begin

            BRAMTest.randomize();
            addrb = BRAMTest.addrb;
            #10;
            $display("Address B: %0h, Data B: %0h", addrb, dob);
            assert(dob == addrb >> 2);

        end

        $display("Dual Read");

        repeat (5) begin

            BRAMTest.randomize();
            addra = BRAMTest.addra;
            addrb = BRAMTest.addrb;
            #10;
            $display("Address A: %0h, Data A: %0h", addra, doa);
            $display("Address B: %0h, Data B: %0h", addrb, dob);
            assert(doa == addra >> 2);
            assert(dob == addrb >> 2);

        end

        $display("WRITE on port A");

        for (i = 0; i < 3; i = i+1) begin

            web = 0;

            case (i)

                0: wea = 4'b0001;
                1: wea = 4'b0011;
                2: wea = 4'b1111;

            endcase
            
            repeat (5) begin

                BRAMTest.randomize();
                addra = BRAMTest.addra;
                dia = BRAMTest.dia;
                #20;
                $display("Address A: %0h, Data Write A: %0h, Data Read A: %0h", addra, dia, doa);
                if (i == 0) assert(doa[7:0] == dia[7:0]);
                else if (i == 1) assert(doa[15:0] == dia[15:0]);
                else if (i == 2) assert(doa == dia);

            end

        end

        for (i = 0; i < 3; i = i+1) begin

            wea = 0;

            case (i)

                0: web = 4'b0001;
                1: web = 4'b0011;
                2: web = 4'b1111;

            endcase
            
            repeat (5) begin

                BRAMTest.randomize();
                addrb = BRAMTest.addrb;
                dib = BRAMTest.dib;
                #20;
                $display("Address B: %0h, Data Write B: %0h, Data Read B: %0h", addrb, dib, dob);
                if (i == 0) assert(dob[7:0] == dib[7:0]);
                else if (i == 1) assert(dob[15:0] == dib[15:0]);
                else if (i == 2) assert(dob == dib);

            end

        end

        $display("Dual Write");

        for (i = 0; i < 3; i = i+1) begin

            case (i) 

                0: begin
                    wea = 4'b0001;
                    web = 4'b0001;
                end
                1: begin
                    wea = 4'b0011;
                    web = 4'b0011;
                end
                2: begin
                    wea = 4'b1111;
                    web = 4'b1111;
                end

            endcase

            repeat (5) begin

                BRAMTest.randomize();
                addra = BRAMTest.addra;
                dia = BRAMTest.dia;
                addrb = BRAMTest.addrb;
                dib = BRAMTest.dib;
                #20;
                $display("Address A: %0h, Data Write A: %0h, Data Read A: %0h", addra, dia, doa);
                $display("Address B: %0h, Data Write B: %0h, Data Read B: %0h", addrb, dib, dob);
                if (i == 0) begin
                    assert(doa[7:0] == dia[7:0]);
                    assert(dob[7:0] == dib[7:0]);
                end
                else if (i == 1) begin
                    assert(doa[15:0] == dia[15:0]);
                    assert(dob[15:0] == dib[15:0]);
                end
                else if (i == 2) begin
                    assert(doa == dia);
                    assert(dob == dib);
                end

            end

        end


        $finish;

    

    end



endmodule