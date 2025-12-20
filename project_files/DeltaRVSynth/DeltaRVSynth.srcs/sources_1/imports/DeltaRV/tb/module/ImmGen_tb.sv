`timescale 1ns/1ps

class ImmGeninputs;

    rand logic [31:7] upperinst; // non opcode part of instruction

endclass

module ImmGen_tb;

    logic [31:0] instruction;
    logic signed [11:0] imm1;
    logic signed [19:0] imm2;
    logic signed [31:0] eximm;
    ImmGen DUT(.instruction(instruction), .imm1(imm1), .imm2(imm2), .eximm(eximm));
    ImmGeninputs ImmGenTest = new;

    localparam [6:0] // opcodes for different instruction types
        OP_R = 7'b0110011,
        OP_I = 7'b0010011,
        OP_S = 7'b0100011,
        OP_B = 7'b1100011,
        OP_U = 7'b0110111,
        OP_J = 7'b1101111;

    logic [0:5][6:0] opcodes = '{OP_R, OP_I, OP_S, OP_B, OP_U, OP_J};

    initial begin

        $display("Testbench started!");

        for (int i = 0; i < 6; i++) begin

            $display("Opcode: %0b", opcodes[i]);

            repeat(5) begin

                ImmGenTest.randomize();
                instruction = {ImmGenTest.upperinst, opcodes[i]};
                #5;
                $display("Instruction: %0b, imm1: %0d, imm2: %0d, eximm: %0d", instruction, imm1, imm2, eximm);

            end

            $display("=============================================");

        end

        $display("I-type direct tests for shift instructions");

       ImmGenTest.randomize();
       ImmGenTest.upperinst[14:12] = 3'b001;
       instruction = {ImmGenTest.upperinst, OP_I};
       #5;
       $display("Instruction: %0b, imm1: %0d, imm2: %0d, eximm: %0d", instruction, imm1, imm2, eximm);

       $display("=============================================");

       ImmGenTest.randomize();
       ImmGenTest.upperinst[14:12] = 3'b101;
       instruction = {ImmGenTest.upperinst, OP_I};
       #5;
       $display("Instruction: %0b, imm1: %0d, imm2: %0d, eximm: %0d", instruction, imm1, imm2, eximm);

    $finish;

    end

    

endmodule