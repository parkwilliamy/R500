`timescale 1ns/1ps

module CPU (
    input rst_n, clk,
    input [31:0] doa, dob,
    output [15:0] addra, addrb, 
    output [3:0] web, 
    output [31:0] dib 
);

    // ******************************** PIPELINE REGISTERS ******************************

    // IF

    reg [31:0] IF_pc;
    wire [31:0] next_pc;

    // ID

    reg [31:0] ID_pc, ID_pc_4;
    reg [7:0] ID_BHTaddr;
    reg [1:0] ID_branch_prediction;
    reg ID_BTBhit;
    
    // EX
    
    reg [3:0] EX_field;
    reg [2:0] EX_ValidReg, EX_funct3;
    reg [1:0] EX_ALUOp, EX_RegSrc, EX_branch_prediction;
    reg EX_ALUSrc, EX_RegWrite, EX_MemRead, EX_MemWrite, EX_Branch, EX_Jump;
    reg [31:0] EX_pc_4, EX_rs1_data, EX_rs2_data, EX_imm, EX_pc_imm;
    reg [4:0] EX_rs1, EX_rs2, EX_rd;
    reg [7:0] EX_BHTaddr;

    // MEM

    reg [31:0] MEM_pc_4;
    reg [2:0] MEM_funct3, MEM_ValidReg;
    reg [1:0] MEM_RegSrc; 
    reg MEM_MemRead, MEM_MemWrite, MEM_RegWrite;
    reg [31:0] MEM_pc_imm, MEM_ALU_result, MEM_rs2_data;
    reg [4:0] MEM_rs2, MEM_rd;

    // WB

    reg [31:0] WB_pc_imm, WB_pc_4, WB_ALU_result;
    reg [2:0] WB_funct3, WB_ValidReg;
    reg [1:0] WB_RegSrc; 
    reg WB_MemRead;
    reg WB_RegWrite;
    reg [4:0] WB_rd;


    // *********************************** MODULES **************************************
               
    // =============================== INSTRUCTION FETCH ================================

    wire [31:0] IF_pc_4, IF_pc_imm, ID_pc_wire, ID_pc_imm;
    wire IF_Branch, IF_Jump, ID_Branch, ID_Jump, BTBwrite, IF_BTBhit;

    reg [1:0] BHT [255:0];
    reg [7:0] gh;
    
    assign ID_pc_wire = ID_pc;

    wire [7:0] IF_BHTaddr;
    assign IF_BHTaddr = IF_pc[9:2] ^ gh;

    wire [1:0] IF_branch_prediction;
    assign IF_branch_prediction = BHT[IF_BHTaddr];

    BTB INST2 (
        .clk(clk), 
        .rst_n(rst_n),
        .write(BTBwrite),
        .ID_Branch(ID_Branch),
        .IF_pc(IF_pc),
        .ID_pc(ID_pc_wire),
        .pc_imm_in(ID_pc_imm),
        .pc_imm_out(IF_pc_imm),
        .hit(IF_BTBhit),
        .IF_Branch(IF_Branch),
        .IF_Jump(IF_Jump)
    );
    
    
    // =============================== INSTRUCTION DECODE ===============================

    wire [31:0] ID_instruction;

    wire [6:0] ID_opcode;
    wire [11:7] ID_rd;
    wire [14:12] ID_funct3;
    wire [19:15] ID_rs1;
    wire [24:20] ID_rs2;
    wire [31:25] ID_funct7;
    wire ID_Stall, ID_Flush;
    reg ID_PostFlush;

    assign ID_instruction = ID_PostFlush ? 0 : doa;
    assign ID_opcode = ID_instruction[6:0];
    assign ID_rd = ID_instruction[11:7];
    assign ID_funct3 = ID_instruction[14:12];
    assign ID_rs1 = ID_instruction[19:15];
    assign ID_rs2 = ID_instruction[24:20];
    assign ID_funct7 = ID_instruction[31:25];

    assign addra = ID_Stall ? ID_pc : IF_pc;
    
    wire [2:0] ID_ValidReg;
    wire [1:0] ID_ALUOp, ID_RegSrc; 
    wire ID_ALUSrc, ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Valid; 
    wire [3:0] ID_field;
    wire [31:0] ID_imm, ID_rs1_data, ID_rs2_data;

    ControlUnit INST3 (
        .opcode(ID_opcode), 
        .ValidReg(ID_ValidReg),
        .ALUOp(ID_ALUOp), 
        .RegSrc(ID_RegSrc), 
        .ALUSrc(ID_ALUSrc), 
        .RegWrite(ID_RegWrite), 
        .MemRead(ID_MemRead), 
        .MemWrite(ID_MemWrite), 
        .Branch(ID_Branch),
        .Jump(ID_Jump),
        .Valid(ID_Valid)
    );
    
    wire WB_RegWrite_wire;
    wire [4:0] WB_rd_wire;
    wire [31:0] WB_rd_write_data;
    
    assign WB_RegWrite_wire = WB_RegWrite;
    assign WB_rd_wire = WB_rd;

    RegFile INST4 (
        .clk(clk), 
        .rst_n(rst_n),
        .RegWrite(WB_RegWrite_wire), 
        .rs1(ID_rs1), 
        .rs2(ID_rs2), 
        .rd(WB_rd_wire), 
        .rd_write_data(WB_rd_write_data), 
        .rs1_data(ID_rs1_data), 
        .rs2_data(ID_rs2_data)
    );

    ImmGen INST5 (
        .instruction(ID_instruction), 
        .imm(ID_imm)
    );

    ALUControl INST6 (
        .funct7(ID_funct7), 
        .funct3(ID_funct3), 
        .ALUOp(ID_ALUOp), 
        .regbit(ID_opcode[5]), 
        .field(ID_field)
    );

    assign ID_pc_imm = ID_pc + ID_imm;
    assign BTBwrite = (ID_Jump || ID_Branch) ? 1 : 0;
    

    // ==================================== EXECUTE =====================================

    wire EX_zero, EX_sign, EX_overflow, EX_carry;

    wire [31:0] EX_op1, EX_op2, EX_rs1_fwd_data, EX_rs2_fwd_data, EX_rs1_data_final, EX_rs2_data_final;

    wire EX_Flush;
 
    assign EX_op1 = (EX_ALUOp == 1 && EX_ALUSrc == 1 && EX_RegSrc == 0 && EX_RegWrite == 1 && EX_ValidReg == 3'b001) ? 0 : EX_rs1_data_final;
    assign EX_op2 = EX_ALUSrc ? EX_imm : EX_rs2_data_final;

    wire [31:0] EX_ALU_result;
    wire [3:0] EX_field_wire;
    wire [2:0] EX_funct3_wire;
    
    assign EX_field_wire = EX_field;
    assign EX_funct3_wire = EX_funct3;

    ALU INST7 (
        .op1(EX_op1), 
        .op2(EX_op2), 
        .field(EX_field_wire), 
        .ALU_result(EX_ALU_result), 
        .zero(EX_zero), 
        .sign(EX_sign), 
        .overflow(EX_overflow), 
        .carry(EX_carry)
    );

    wire EX_branch_taken, EX_Branch_wire;
    wire [1:0] EX_prediction_status, EX_branch_prediction_wire;
    
    assign EX_Branch_wire = EX_Branch;
    assign EX_branch_prediction_wire = EX_branch_prediction;

    BRU INST8 (
        .EX_branch_prediction(EX_branch_prediction_wire),
        .EX_Branch(EX_Branch_wire), 
        .zero(EX_zero), 
        .sign(EX_sign), 
        .overflow(EX_overflow), 
        .carry(EX_carry),
        .funct3(EX_funct3_wire),
        .branch_taken(EX_branch_taken),
        .prediction_status(EX_prediction_status)
    );


    // ================================== MEMORY WRITE ==================================

    wire [31:0] MEM_rs2_fwd_data, MEM_rs2_data_final, MEM_ALU_result_wire;
    wire [2:0] MEM_funct3_wire;
    wire MEM_MemWrite_wire;
    
    assign MEM_ALU_result_wire = MEM_ALU_result;
    assign MEM_funct3_wire = MEM_funct3;
    assign MEM_MemWrite_wire = MEM_MemWrite;
    assign addrb = MEM_ALU_result;

    Store INST9 (
        .MemWrite(MEM_MemWrite_wire),
        .addrb(MEM_ALU_result_wire),
        .rs2_data(MEM_rs2_data_final),
        .funct3(MEM_funct3_wire),
        .web(web),
        .dib(dib)
    );


    // =============================== REGFILE WRITE BACK ===============================
    
    wire [31:0] WB_ALU_result_wire, WB_pc_imm_wire, WB_pc_4_wire;
    wire [2:0] WB_funct3_wire;
    wire [1:0] WB_RegSrc_wire;
    
    assign WB_ALU_result_wire = WB_ALU_result;
    assign WB_pc_imm_wire = WB_pc_imm;
    assign WB_pc_4_wire = WB_pc_4;
    assign WB_funct3_wire = WB_funct3;
    assign WB_RegSrc_wire = WB_RegSrc;

    WriteBack INST10 (
        .ALU_result(WB_ALU_result), 
        .pc_imm(WB_pc_imm), 
        .pc_4(WB_pc_4),
        .funct3(WB_funct3),
        .RegSrc(WB_RegSrc),
        .DMEM_word(dob),
        .rd_write_data(WB_rd_write_data)
    );
    
    wire [1:0] ID_branch_prediction_wire, EX_prediction_status_wire;
    wire ID_BTBhit_wire, ID_Branch_wire, ID_Jump_wire, EX_Jump_wire, ID_ALUSrc_wire, EX_ALUSrc_wire;
    wire [31:0] EX_pc_4_wire, ID_pc_imm_wire, EX_pc_imm_wire, EX_ALU_result_wire;
    
    assign ID_branch_prediction_wire = ID_branch_prediction;
    assign EX_prediction_status_wire = EX_prediction_status;
    assign ID_BTBhit_wire = ID_BTBhit;
    assign ID_Branch_wire = ID_Branch;
    assign ID_Jump_wire = ID_Jump;
    assign EX_Jump_wire = EX_Jump;
    assign ID_ALUSrc_wire = ID_ALUSrc;
    assign EX_ALUSrc_wire = EX_ALUSrc;
    assign EX_pc_4_wire = EX_pc_4;
    assign ID_pc_imm_wire = ID_pc_imm;
    assign EX_pc_imm_wire = EX_pc_imm;
    assign EX_ALU_result_wire = EX_ALU_result;

    Fetch INST11 (
        .IF_branch_prediction(IF_branch_prediction),
        .ID_branch_prediction(ID_branch_prediction_wire),
        .prediction_status(EX_prediction_status_wire),
        .IF_BTBhit(IF_BTBhit),
        .ID_BTBhit(ID_BTBhit_wire),
        .IF_Branch(IF_Branch),
        .IF_Jump(IF_Jump),
        .ID_Branch(ID_Branch_wire),
        .EX_Branch(EX_Branch_wire),
        .ID_Jump(ID_Jump_wire),
        .EX_Jump(EX_Jump_wire),
        .ID_ALUSrc(ID_ALUSrc_wire),
        .EX_ALUSrc(EX_ALUSrc_wire),
        .IF_pc(IF_pc),
        .IF_pc_imm(IF_pc_imm),
        .EX_pc_4(EX_pc_4_wire),
        .ID_pc_imm(ID_pc_imm_wire),
        .EX_pc_imm(EX_pc_imm_wire),
        .rs1_imm(EX_ALU_result_wire),
        .IF_pc_4(IF_pc_4),
        .next_pc(next_pc),
        .ID_Flush(ID_Flush),
        .EX_Flush(EX_Flush)
    );


    // ================================== FORWARDING ====================================

    wire EX_rs1_fwd, EX_rs2_fwd, MEM_MemRead_wire, WB_MemRead_wire;
    wire [31:0] MEM_pc_4_wire, MEM_pc_imm_wire;
    wire [1:0] MEM_RegSrc_wire;
    wire [4:0] EX_rs1_wire, EX_rs2_wire, MEM_rs2_wire, MEM_rd_wire;
    wire [2:0] EX_ValidReg_wire, MEM_ValidReg_wire, WB_ValidReg_wire;
    
    assign MEM_pc_4_wire = MEM_pc_4;
    assign MEM_pc_imm_wire = MEM_pc_imm;
    assign MEM_RegSrc_wire = MEM_RegSrc;
    assign EX_rs1_wire = EX_rs1;
    assign EX_rs2_wire = EX_rs2;
    assign MEM_rs2_wire = MEM_rs2;
    assign MEM_rd_wire = MEM_rd;
    assign EX_ValidReg_wire = EX_ValidReg;
    assign MEM_ValidReg_wire = MEM_ValidReg;
    assign WB_ValidReg_wire = WB_ValidReg;
    assign MEM_MemRead_wire = MEM_MemRead;
    assign WB_MemRead_wire = WB_MemRead;

    ForwardUnit INST12 (
        .MEM_ALU_result(MEM_ALU_result_wire),
        .MEM_pc_4(MEM_pc_4_wire),
        .MEM_pc_imm(MEM_pc_imm_wire),
        .MEM_RegSrc(MEM_RegSrc_wire),
        .WB_rd_write_data(WB_rd_write_data),
        .EX_rs1(EX_rs1_wire), 
        .EX_rs2(EX_rs2_wire), 
        .MEM_rs2(MEM_rs2_wire),
        .MEM_rd(MEM_rd_wire), 
        .WB_rd(WB_rd_wire),
        .EX_ValidReg(EX_ValidReg_wire), 
        .MEM_ValidReg(MEM_ValidReg_wire), 
        .WB_ValidReg(WB_ValidReg_wire),
        .MEM_MemRead(MEM_MemRead_wire),
        .MEM_MemWrite(MEM_MemWrite_wire),
        .WB_MemRead(WB_MemRead_wire),
        .EX_rs1_fwd(EX_rs1_fwd), 
        .EX_rs2_fwd(EX_rs2_fwd),
        .MEM_rs2_fwd(MEM_rs2_fwd),
        .EX_rs1_fwd_data(EX_rs1_fwd_data),
        .EX_rs2_fwd_data(EX_rs2_fwd_data),
        .MEM_rs2_fwd_data(MEM_rs2_fwd_data)
    );

    assign EX_rs1_data_final = (EX_rs1_fwd) ? EX_rs1_fwd_data : EX_rs1_data;
    assign EX_rs2_data_final = (EX_rs2_fwd) ? EX_rs2_fwd_data : EX_rs2_data;
    assign MEM_rs2_data_final = (MEM_rs2_fwd) ? MEM_rs2_fwd_data : MEM_rs2_data;


    // =================================== STALLING =====================================
    
    wire EX_MemRead_wire;
    wire [4:0] EX_rd_wire;
    
    assign EX_MemRead_wire = EX_MemRead;
    assign EX_rd_wire = EX_rd;

    StallUnit INST13 (
        .EX_MemRead(EX_MemRead_wire),
        .ID_MemWrite(ID_MemWrite),
        .EX_rd(EX_rd_wire),
        .ID_rs1(ID_rs1),
        .ID_rs2(ID_rs2),
        .ID_ValidReg(ID_ValidReg),
        .Stall(ID_Stall)
    );
    
    integer i;
    
    // IF

    always @ (posedge clk) begin

        if (!rst_n) begin

            IF_pc <= 32'b0; 

        end

        else begin

            if (!ID_Stall) IF_pc <= next_pc; 

        end

    end
    
    // ID
    
    always @ (posedge clk) begin
    
        if (!rst_n) begin
        
            ID_PostFlush <= 0;
            ID_pc <= 32'b0;
            ID_pc_4 <= 32'b0;
            ID_BHTaddr <= 8'b0;
            ID_branch_prediction <= 2'b0;
            ID_BTBhit <= 1'b0;
        
        end else begin
        
            ID_PostFlush <= 0;
        
            if (ID_Flush) begin
            
                ID_pc <= 32'b0;
                ID_pc_4 <= 32'b0;
                ID_BHTaddr <= 8'b0;
                ID_branch_prediction <= 2'b0;
                ID_BTBhit <= 1'b0;
                ID_PostFlush <= 1;
            
            end
             
            else if (!ID_Stall) begin
            
                ID_pc <= IF_pc;
                ID_pc_4 <= IF_pc_4;
                ID_BHTaddr <= IF_BHTaddr;
                ID_branch_prediction <= IF_branch_prediction;
                ID_BTBhit <= IF_BTBhit;
            
            end
        
        end
    
    end
    
    // EX
    
    always @ (posedge clk) begin
    
        if (!rst_n) begin
        
            gh <= 0;
            EX_pc_4 <= 32'b0;
            EX_pc_imm <= 32'b0;
            EX_BHTaddr <= 8'b0;
            EX_funct3 <= 3'b000;
            EX_field <= 4'b0000;
            EX_ValidReg <= 3'b000;
            EX_ALUOp <= 2'b00;
            EX_RegSrc <= 2'b00;
            EX_ALUSrc <= 1'b0;
            EX_RegWrite <= 1'b0;
            EX_MemRead <= 1'b0;
            EX_MemWrite <= 1'b0;
            EX_Branch <= 1'b0;
            EX_branch_prediction <= 2'b0;
            EX_Jump <= 1'b0;
            EX_rs1_data <= 32'b0;
            EX_rs2_data <= 32'b0;
            EX_imm <= 32'b0;
            EX_rd <= 5'b0;
            EX_rs1 <= 5'b0;
            EX_rs2 <= 5'b0;
            
            for (i = 0; i < 256; i = i+1) begin

                BHT[i] <= 2'b01;

            end
        
        end else begin
     
            if (EX_Flush) begin
            
                EX_pc_4 <= 32'b0;
                EX_pc_imm <= 32'b0;
                EX_BHTaddr <= 8'b0;
                EX_funct3 <= 3'b000;
                EX_field <= 4'b0000;
                EX_ValidReg <= 3'b000;
                EX_ALUOp <= 2'b00;
                EX_RegSrc <= 2'b00;
                EX_ALUSrc <= 1'b0;
                EX_RegWrite <= 1'b0;
                EX_MemRead <= 1'b0;
                EX_MemWrite <= 1'b0;
                EX_Branch <= 1'b0;
                EX_branch_prediction <= 2'b0;
                EX_Jump <= 1'b0;
                EX_rs1_data <= 32'b0;
                EX_rs2_data <= 32'b0;
                EX_imm <= 32'b0;
                EX_rd <= 5'b0;
                EX_rs1 <= 5'b0;
                EX_rs2 <= 5'b0;
            
            end
           
            else if (ID_Stall) begin
            
                EX_funct3 <= 3'b000;
                EX_field <= 4'b0000;
                EX_ValidReg <= 3'b000;
                EX_ALUOp <= 2'b00;
                EX_RegSrc <= 2'b00;
                EX_ALUSrc <= 1'b0;
                EX_RegWrite <= 1'b0;
                EX_MemRead <= 1'b0;
                EX_MemWrite <= 1'b0;
                EX_Branch <= 1'b0;
                EX_branch_prediction <= 2'b0;
                EX_Jump <= 1'b0;
   
            end
            
            else begin
            
                EX_pc_4 <= ID_pc_4;
                EX_pc_imm <= ID_pc_imm;
                EX_BHTaddr <= ID_BHTaddr;
                EX_funct3 <= ID_funct3;
                EX_field <= ID_field;
                EX_ValidReg <= ID_ValidReg;
                EX_ALUOp <= ID_ALUOp;
                EX_RegSrc <= ID_RegSrc;
                EX_ALUSrc <= ID_ALUSrc;
                EX_RegWrite <= ID_RegWrite;
                EX_MemRead <= ID_MemRead;
                EX_MemWrite <= ID_MemWrite;
                EX_Branch <= ID_Branch;
                EX_branch_prediction <= ID_branch_prediction;
                EX_Jump <= ID_Jump;
                EX_rs1_data <= ID_rs1_data;
                EX_rs2_data <= ID_rs2_data;
                EX_imm <= ID_imm;
                EX_rd <= ID_rd;
                EX_rs1 <= ID_rs1;
                EX_rs2 <= ID_rs2;
            
            end
            
            if (EX_Branch) begin
    
                gh <= {gh[6:0], EX_branch_taken};
    
                case (EX_prediction_status)
    
                    0: begin
                        
                        BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]+1;
    
                    end
                    1: begin
                        
                        BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]-1;
    
                    end
                    2: begin
                        
                        if (BHT[EX_BHTaddr] > 0)  BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]-1;
    
                    end
                    3: begin
                        
                        if (BHT[EX_BHTaddr] < 3 && EX_branch_prediction > 1)  BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]+1;
    
                    end
    
                endcase

            end
        
        end
        
    end
    
    // MEM
    
    always @ (posedge clk) begin
    
        if (!rst_n) begin
        
            MEM_pc_4 <= 0;
            MEM_pc_imm <= 0;
            MEM_funct3 <= 0;
            MEM_ValidReg <= 0;
            MEM_RegSrc <= 0;
            MEM_RegWrite <= 0;
            MEM_MemRead <= 0;
            MEM_MemWrite <= 0;
            MEM_ALU_result <= 0;
            MEM_rs2_data <= 0;
            MEM_rs2 <= 0;
            MEM_rd <= 0;
        
        end else begin
        
            MEM_pc_4 <= EX_pc_4;
            MEM_pc_imm <= EX_pc_imm;
            MEM_funct3 <= EX_funct3;
            MEM_ValidReg <= EX_ValidReg;
            MEM_RegSrc <= EX_RegSrc;
            MEM_RegWrite <= EX_RegWrite;
            MEM_MemRead <= EX_MemRead;
            MEM_MemWrite <= EX_MemWrite;
            MEM_ALU_result <= EX_ALU_result;
            MEM_rs2_data <= EX_rs2_data_final;
            MEM_rs2 <= EX_rs2;
            MEM_rd <= EX_rd;
          
        end
    
    end
    
    // WB
    
    always @ (posedge clk) begin
    
        if (!rst_n) begin
        
            WB_pc_4 <= 0;
            WB_pc_imm <= 0;
            WB_funct3 <= 0;
            WB_ValidReg <= 0;
            WB_RegSrc <= 0;
            WB_MemRead <= 0;
            WB_RegWrite <= 0;
            WB_ALU_result <= 0;
            WB_rd <= 0;
        
        end else begin
        
            WB_pc_4 <= MEM_pc_4;
            WB_pc_imm <= MEM_pc_imm;
            WB_funct3 <= MEM_funct3;
            WB_ValidReg <= MEM_ValidReg;
            WB_RegSrc <= MEM_RegSrc;
            WB_MemRead <= MEM_MemRead;
            WB_RegWrite <= MEM_RegWrite;
            WB_ALU_result <= MEM_ALU_result;
            WB_rd <= MEM_rd;
        
        end
    
    end
    
endmodule