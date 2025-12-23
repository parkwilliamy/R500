`timescale 1ns/1ps

module CPU (
    input rst_n, clk,
    input [31:0] doa, dob,
    output [15:0] addra, addrb, 
    output [3:0] web, 
    output [31:0] dib 
);

    // NAMING CONVENTIONS

    // Pipeline Stages: IF (Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM (Memory Writeback), WB (Register File Writeback)
    // Generally most registers are written as {PIPELINE STAGE}_{SIGNAL}
    // Nets are written as {PIPELINE_STAGE}_{SIGNAL}_wire, these are used to connect to the pipeline registers


    // ************************************************************************************************ PIPELINE REGISTERS ************************************************************************************************************************************

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


    // ****************************************************************************************************** PIPELINE NETS ***********************************************************************************************************************************

    // IF

    wire [31:0] IF_pc_4, IF_pc_imm;
    wire IF_Branch, IF_Jump, BTBwrite, IF_BTBhit;
    wire [7:0] IF_BHTaddr;
    wire [1:0] IF_branch_prediction;

    // ID

    wire [31:0] ID_instruction, ID_imm, ID_rs1_data, ID_rs2_data, ID_pc_imm, ID_pc_wire;
    wire [6:0] ID_opcode;
    wire [11:7] ID_rd;
    wire [14:12] ID_funct3;
    wire [19:15] ID_rs1;
    wire [24:20] ID_rs2;
    wire [31:25] ID_funct7;
    wire ID_Stall, ID_Flush, ID_ALUSrc, ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Valid, ID_BTBhit_wire, ID_Branch, ID_Jump;
    wire [2:0] ID_ValidReg;
    wire [1:0] ID_ALUOp, ID_RegSrc, ID_branch_prediction_wire;
    wire [3:0] ID_field; 
    
    // EX
    
    wire EX_zero, EX_sign, EX_overflow, EX_carry, EX_Flush, EX_branch_taken, EX_Branch_wire, EX_rs1_fwd, EX_rs2_fwd, EX_Jump_wire, EX_ALUSrc_wire, EX_MemRead_wire;
    wire [31:0] EX_op1, EX_op2, EX_rs1_fwd_data, EX_rs2_fwd_data, EX_rs1_data_final, EX_rs2_data_final, EX_ALU_result, EX_pc_4_wire, EX_pc_imm_wire, EX_ALU_result_wire;
    wire [3:0] EX_field_wire;
    wire [2:0] EX_funct3_wire, EX_ValidReg_wire;
    wire [1:0] EX_prediction_status, EX_branch_prediction_wire;
    wire [4:0] EX_rs1_wire, EX_rs2_wire, EX_rd_wire;

    // MEM

    wire [31:0] MEM_rs2_fwd_data, MEM_rs2_data_final, MEM_ALU_result_wire, MEM_pc_4_wire, MEM_pc_imm_wire;
    wire [2:0] MEM_funct3_wire, MEM_ValidReg_wire;
    wire MEM_MemWrite_wire, MEM_MemRead_wire;
    wire [1:0] MEM_RegSrc_wire;
    wire [4:0] MEM_rs2_wire, MEM_rd_wire;

    // WB

    wire WB_RegWrite_wire;
    wire [4:0] WB_rd_wire;
    wire [31:0] WB_rd_write_data;
    wire [31:0] WB_ALU_result_wire, WB_pc_imm_wire, WB_pc_4_wire;
    wire [2:0] WB_funct3_wire, WB_ValidReg_wire;
    wire [1:0] WB_RegSrc_wire;
    wire WB_MemRead_wire;


    // ********************************************************************************************************  PERFORMANCE METRICS **************************************************************************************************************************

    reg [31:0] clk_cycles, invalid_clk_cycles, retired_instructions, correct_predictions, total_predictions;

    // CPI = (clk_cycles - invalid_clk_cycles) / (retired_instructions)
    // Branch Predictor Accuracy = correct_predictions / total_predictions


    // *************************************************************************************************************** MODULES ********************************************************************************************************************************
               
    // =============================== INSTRUCTION FETCH ================================

    reg [1:0] BHT [255:0]; // Branch History Table stores predictions for up to 256 branch instructions
    // Prediction Encodings
    // 1) 00 - Strong Not Taken
    // 2) 01 - Weak Not Taken
    // 3) 10 - Weak Taken
    // 4) 11 - Strong Taken

    reg [7:0] gh; // Global History shift register stores the last 8 predictions, with 0 indicating branch not taken and 1 indicating branch taken
    
    assign ID_pc_wire = ID_pc;
    assign IF_BHTaddr = IF_pc[9:2] ^ gh; // gshare branch prediction indexing
    assign IF_branch_prediction = BHT[IF_BHTaddr];

    // Branch Target Buffer (BTB) is a 2-way set associative cache that holds up to 32 branch target addresses
    // Purpose of the BTB is to provide branch target addresses in the IF stage to avoid needing to compute it in the ID stage
    // No penalty incurred on taken branches that already computed the target address previously (i.e., loops)

    BTB INST1 (
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

    reg ID_PostFlush; // flag used to indicate if a pipeline flush occured last cycle

    assign ID_instruction = ID_PostFlush ? 0 : doa; // if pipeline flush occured last cycle, clear the instruction received
    assign ID_opcode = ID_instruction[6:0];
    assign ID_rd = ID_instruction[11:7];
    assign ID_funct3 = ID_instruction[14:12];
    assign ID_rs1 = ID_instruction[19:15];
    assign ID_rs2 = ID_instruction[24:20];
    assign ID_funct7 = ID_instruction[31:25];
    assign addra = ID_Stall ? ID_pc : IF_pc; // fetch instruction from ID_pc if pipeline is stalled
    
    ControlUnit INST2 (
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
    
    assign WB_RegWrite_wire = WB_RegWrite;
    assign WB_rd_wire = WB_rd;

    RegFile INST3 (
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

    ImmGen INST4 (
        .instruction(ID_instruction), 
        .imm(ID_imm)
    );

    ALUControl INST5 (
        .funct7(ID_funct7), 
        .funct3(ID_funct3), 
        .ALUOp(ID_ALUOp), 
        .regbit(ID_opcode[5]), 
        .field(ID_field)
    );

    assign ID_pc_imm = ID_pc + ID_imm;
    assign BTBwrite = (ID_Jump || ID_Branch) ? 1 : 0;
    

    // ==================================== EXECUTE =====================================

    assign EX_op1 = (EX_ALUOp == 1 && EX_ALUSrc == 1 && EX_RegSrc == 0 && EX_RegWrite == 1 && EX_ValidReg == 3'b001) ? 0 : EX_rs1_data_final;
    assign EX_op2 = EX_ALUSrc ? EX_imm : EX_rs2_data_final;
    assign EX_field_wire = EX_field;
    assign EX_funct3_wire = EX_funct3;

    ALU INST6 (
        .op1(EX_op1), 
        .op2(EX_op2), 
        .field(EX_field_wire), 
        .ALU_result(EX_ALU_result), 
        .zero(EX_zero), 
        .sign(EX_sign), 
        .overflow(EX_overflow), 
        .carry(EX_carry)
    );

    assign EX_Branch_wire = EX_Branch;
    assign EX_branch_prediction_wire = EX_branch_prediction;

    // Branch Resolution Unit compares prediction with actual branch result, yielding a prediction status that indicates whether the prediction was correct or not

    BRU INST7 (
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


    // ================================ MEMORY WRITEBACK ================================
    
    assign MEM_ALU_result_wire = MEM_ALU_result;
    assign MEM_funct3_wire = MEM_funct3;
    assign MEM_MemWrite_wire = MEM_MemWrite;
    assign addrb = MEM_ALU_result;

    Store INST8 (
        .MemWrite(MEM_MemWrite_wire),
        .addrb(MEM_ALU_result_wire),
        .rs2_data(MEM_rs2_data_final),
        .clk_cycles(clk_cycles),
        .invalid_clk_cycles(invalid_clk_cycles),
        .retired_instructions(retired_instructions),
        .correct_predictions(correct_predictions),
        .total_predictions(total_predictions),
        .funct3(MEM_funct3_wire),
        .web(web),
        .dib(dib)
    );


    // =============================== REGFILE WRITEBACK ===============================+
    
    assign WB_ALU_result_wire = WB_ALU_result;
    assign WB_pc_imm_wire = WB_pc_imm;
    assign WB_pc_4_wire = WB_pc_4;
    assign WB_funct3_wire = WB_funct3;
    assign WB_RegSrc_wire = WB_RegSrc;

    WriteBack INST9 (
        .ALU_result(WB_ALU_result), 
        .pc_imm(WB_pc_imm), 
        .pc_4(WB_pc_4),
        .funct3(WB_funct3),
        .RegSrc(WB_RegSrc),
        .DMEM_word(dob),
        .rd_write_data(WB_rd_write_data)
    );
    
    assign ID_branch_prediction_wire = ID_branch_prediction;
    assign ID_BTBhit_wire = ID_BTBhit;
    assign EX_Jump_wire = EX_Jump;
    assign EX_ALUSrc_wire = EX_ALUSrc;
    assign EX_pc_4_wire = EX_pc_4;
    assign EX_pc_imm_wire = EX_pc_imm;
    assign EX_ALU_result_wire = EX_ALU_result;

    // Fetch Unit fetches next PC based on prediction status and control signals
    // Flushes the pipeline for incorrect predictions

    Fetch INST10 (
        .IF_branch_prediction(IF_branch_prediction),
        .ID_branch_prediction(ID_branch_prediction_wire),
        .prediction_status(EX_prediction_status),
        .IF_BTBhit(IF_BTBhit),
        .ID_BTBhit(ID_BTBhit_wire),
        .IF_Branch(IF_Branch),
        .IF_Jump(IF_Jump),
        .ID_Branch(ID_Branch),
        .EX_Branch(EX_Branch_wire),
        .ID_Jump(ID_Jump),
        .EX_Jump(EX_Jump_wire),
        .ID_ALUSrc(ID_ALUSrc),
        .EX_ALUSrc(EX_ALUSrc_wire),
        .IF_pc(IF_pc),
        .IF_pc_imm(IF_pc_imm),
        .EX_pc_4(EX_pc_4_wire),
        .ID_pc_imm(ID_pc_imm),
        .EX_pc_imm(EX_pc_imm_wire),
        .rs1_imm(EX_ALU_result_wire),
        .IF_pc_4(IF_pc_4),
        .next_pc(next_pc),
        .ID_Flush(ID_Flush),
        .EX_Flush(EX_Flush)
    );


    // ================================== FORWARDING ====================================

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

    // Forward Unit passes data to EX and MEM stages for Read After Write (RAW) hazards
    // 3 types of forwards:
    // 1) MEM -> EX
    // 2) WB -> EX
    // 3) WB -> MEM 

    ForwardUnit INST11 (
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
    
    assign EX_MemRead_wire = EX_MemRead;
    assign EX_rd_wire = EX_rd;

    // Stall Unit freezes the pipeline for load-use hazards

    StallUnit INST12 (
        .EX_MemRead(EX_MemRead_wire),
        .ID_MemWrite(ID_MemWrite),
        .EX_rd(EX_rd_wire),
        .ID_rs1(ID_rs1),
        .ID_rs2(ID_rs2),
        .ID_ValidReg(ID_ValidReg),
        .Stall(ID_Stall)
    );


    // *********************************************************************************************************** SEQUENTIAL LOGIC ***************************************************************************************************************************
    
    integer i;
    
    // IF

    always @ (posedge clk) begin

        if (!rst_n) begin

            IF_pc <= 32'b0; 
            clk_cycles <= 0;

        end

        else begin

            if (!ID_Stall) IF_pc <= next_pc;
            clk_cycles <= clk_cycles + 1; 

        end

    end
    
    // ID
    
    always @ (posedge clk) begin
    
        if (!rst_n) begin
        
            invalid_clk_cycles <= 0;

            ID_PostFlush <= 0;
            ID_pc <= 32'b0;
            ID_pc_4 <= 32'b0;
            ID_BHTaddr <= 8'b0;
            ID_branch_prediction <= 2'b0;
            ID_BTBhit <= 1'b0;
        
        end else begin
        
            ID_PostFlush <= 0;

            if (!ID_Valid) invalid_clk_cycles <= invalid_clk_cycles + 1;
        
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

            correct_predictions <= 0;
            total_predictions <= 0;
        
            gh <= 0;
            EX_pc_4 <= 32'b0;
            EX_pc_imm <= 32'b0;
            EX_BHTaddr <= 8'b0;
            EX_funct3 <= 3'b0;
            EX_field <= 4'b0;
            EX_ValidReg <= 3'b0;
            EX_ALUOp <= 2'b0;
            EX_RegSrc <= 2'b0;
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

            if (EX_Branch) total_predictions <= total_predictions+1;
     
            if (EX_Flush) begin
            
                EX_pc_4 <= 32'b0;
                EX_pc_imm <= 32'b0;
                EX_BHTaddr <= 8'b0;
                EX_funct3 <= 3'b0;
                EX_field <= 4'b0;
                EX_ValidReg <= 3'b0;
                EX_ALUOp <= 2'b0;
                EX_RegSrc <= 2'b0;
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
            
                EX_funct3 <= 3'b0;
                EX_field <= 4'b0;
                EX_ValidReg <= 3'b0;
                EX_ALUOp <= 2'b0;
                EX_RegSrc <= 2'b0;
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
                        correct_predictions <= correct_predictions+1;
    
                    end
                    3: begin
                        
                        if (BHT[EX_BHTaddr] < 3 && EX_branch_prediction > 1)  BHT[EX_BHTaddr] <= BHT[EX_BHTaddr]+1;
                        correct_predictions <= correct_predictions+1;
    
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
            retired_instructions <= 0;
        
        end else begin

            if (WB_ValidReg != 3'b000) retired_instructions <= retired_instructions+1;
        
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