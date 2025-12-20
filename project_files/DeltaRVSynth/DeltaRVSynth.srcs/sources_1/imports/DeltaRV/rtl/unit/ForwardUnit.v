`timescale 1ns/1ps

module ForwardUnit (
    input [31:0] MEM_ALU_result, MEM_pc_4, MEM_pc_imm, WB_rd_write_data,
    input [1:0] MEM_RegSrc,
    input [4:0] EX_rs1, EX_rs2, MEM_rs2, MEM_rd, WB_rd,
    input [2:0] EX_ValidReg, MEM_ValidReg, WB_ValidReg,
    input MEM_MemRead, MEM_MemWrite, WB_MemRead,
    output EX_rs1_fwd, EX_rs2_fwd, MEM_rs2_fwd,
    output reg [31:0] EX_rs1_fwd_data, EX_rs2_fwd_data, MEM_rs2_fwd_data
);

    wire EX_rs1_MEM_fwd, EX_rs2_MEM_fwd, EX_rs1_WB_fwd, EX_rs2_WB_fwd;
    reg [31:0] MEM_rd_write_data;

    assign EX_rs1_MEM_fwd = (EX_rs1 == MEM_rd) && (EX_ValidReg[1] && MEM_ValidReg[0]) && !MEM_MemRead;
    assign EX_rs2_MEM_fwd = (EX_rs2 == MEM_rd) && (EX_ValidReg[2] && MEM_ValidReg[0]) && !MEM_MemRead;
    assign EX_rs1_WB_fwd = (EX_rs1 == WB_rd) && (EX_ValidReg[1] && WB_ValidReg[0]);
    assign EX_rs2_WB_fwd = (EX_rs2 == WB_rd) && (EX_ValidReg[2] && WB_ValidReg[0]);
    assign MEM_rs2_WB_fwd = (MEM_rs2 == WB_rd) && (MEM_MemWrite && WB_MemRead) && (MEM_ValidReg[2] && WB_ValidReg[0]);
    
    assign EX_rs1_fwd = (EX_rs1_MEM_fwd || EX_rs1_WB_fwd) && (EX_rs1 != 0);
    assign EX_rs2_fwd = (EX_rs2_MEM_fwd || EX_rs2_WB_fwd) && (EX_rs2 != 0);
    assign MEM_rs2_fwd = MEM_rs2_WB_fwd && MEM_rs2 != 0;

    always @ (*) begin
    
        MEM_rd_write_data = 0;

        case (MEM_RegSrc)

            0: MEM_rd_write_data = MEM_ALU_result;
            2: MEM_rd_write_data = MEM_pc_imm;
            3: MEM_rd_write_data = MEM_pc_4;

        endcase

        if (EX_rs1_MEM_fwd) EX_rs1_fwd_data = MEM_rd_write_data;
        else EX_rs1_fwd_data = 0;
        if (EX_rs2_MEM_fwd) EX_rs2_fwd_data = MEM_rd_write_data;
        else EX_rs2_fwd_data = 0;

        if (EX_rs1_WB_fwd) begin
            if (EX_rs1_MEM_fwd) begin
                if (MEM_rd != WB_rd) EX_rs1_fwd_data = WB_rd_write_data;
                else EX_rs1_fwd_data = MEM_rd_write_data;
            end
            else EX_rs1_fwd_data = WB_rd_write_data;
        end

        if (EX_rs2_WB_fwd) begin
            if (EX_rs2_MEM_fwd) begin
                if (MEM_rd != WB_rd) EX_rs2_fwd_data = WB_rd_write_data;
                else EX_rs2_fwd_data = MEM_rd_write_data;
            end
            else EX_rs2_fwd_data = WB_rd_write_data;
        end

        if (MEM_rs2_WB_fwd) MEM_rs2_fwd_data = WB_rd_write_data;
        else MEM_rs2_fwd_data = 0;

    end


endmodule