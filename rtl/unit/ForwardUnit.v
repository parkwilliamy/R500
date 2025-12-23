`timescale 1ns/1ps

module ForwardUnit (
    input [31:0] MEM_ALU_result, MEM_pc_4, MEM_pc_imm, WB_rd_write_data,
    input [1:0] MEM_RegSrc,
    input [4:0] EX_rs1, EX_rs2, MEM_rs2, MEM_rd, WB_rd,
    input [2:0] EX_ValidReg, MEM_ValidReg, WB_ValidReg,
    input MEM_MemRead, MEM_MemWrite, WB_MemRead,
    output EX_rs1_fwd, EX_rs2_fwd, MEM_rs2_fwd, // These signals indicate if one or more of these pipeline registers need data forwarded to them
    output reg [31:0] EX_rs1_fwd_data, EX_rs2_fwd_data, MEM_rs2_fwd_data // Data to forward to respective pipeline registers
);

    wire EX_rs1_MEM_fwd, EX_rs2_MEM_fwd, EX_rs1_WB_fwd, EX_rs2_WB_fwd;
    reg [31:0] MEM_rd_write_data;

    // Instructions will always have the most recent data forwarded to them (i.e., prioritize MEM data over WB)
    assign EX_rs1_MEM_fwd = (EX_rs1 == MEM_rd) && (EX_ValidReg[1] && MEM_ValidReg[0]) && !MEM_MemRead; // MEM -> EX rd to rs1 forward
    assign EX_rs2_MEM_fwd = (EX_rs2 == MEM_rd) && (EX_ValidReg[2] && MEM_ValidReg[0]) && !MEM_MemRead; // MEM -> EX rd to rs2 forward
    assign EX_rs1_WB_fwd = (EX_rs1 == WB_rd) && (EX_ValidReg[1] && WB_ValidReg[0]); // WB -> EX rd to rs1 forward
    assign EX_rs2_WB_fwd = (EX_rs2 == WB_rd) && (EX_ValidReg[2] && WB_ValidReg[0]); // WB -> EX rd to rs2 forward
    assign MEM_rs2_WB_fwd = (MEM_rs2 == WB_rd) && (MEM_MemWrite && WB_MemRead) && (MEM_ValidReg[2] && WB_ValidReg[0]); // WB -> MEM rd to rs2 forward (for load-stores)
    
    assign EX_rs1_fwd = (EX_rs1_MEM_fwd || EX_rs1_WB_fwd) && (EX_rs1 != 0);
    assign EX_rs2_fwd = (EX_rs2_MEM_fwd || EX_rs2_WB_fwd) && (EX_rs2 != 0);
    assign MEM_rs2_fwd = MEM_rs2_WB_fwd && MEM_rs2 != 0;

    always @ (*) begin
    
        MEM_rd_write_data = 0;

        // For MEM -> EX forwards, must decide what data to write back to EX
        case (MEM_RegSrc)

            0: MEM_rd_write_data = MEM_ALU_result;
            2: MEM_rd_write_data = MEM_pc_imm;
            3: MEM_rd_write_data = MEM_pc_4;

        endcase

        // rs1 MEM -> EX forwards
        if (EX_rs1_MEM_fwd) EX_rs1_fwd_data = MEM_rd_write_data;
        else EX_rs1_fwd_data = 0;

        // rs1 WB -> EX forwards
        if (EX_rs1_WB_fwd) begin
            if (EX_rs1_MEM_fwd) begin
                if (MEM_rd != WB_rd) EX_rs1_fwd_data = WB_rd_write_data; // MEM priority forwarding
                else EX_rs1_fwd_data = MEM_rd_write_data;
            end
            else EX_rs1_fwd_data = WB_rd_write_data;
        end

        // rs2 MEM -> EX forwards
        if (EX_rs2_MEM_fwd) EX_rs2_fwd_data = MEM_rd_write_data;
        else EX_rs2_fwd_data = 0;

        // rs2 WB -> EX forwards
        if (EX_rs2_WB_fwd) begin
            if (EX_rs2_MEM_fwd) begin
                if (MEM_rd != WB_rd) EX_rs2_fwd_data = WB_rd_write_data; // MEM priority forwarding
                else EX_rs2_fwd_data = MEM_rd_write_data;
            end
            else EX_rs2_fwd_data = WB_rd_write_data;
        end

        // rs2 WB -> MEM forwards
        if (MEM_rs2_WB_fwd) MEM_rs2_fwd_data = WB_rd_write_data;
        else MEM_rs2_fwd_data = 0;

    end


endmodule