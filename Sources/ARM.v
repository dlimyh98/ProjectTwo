`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: ARM
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: ARM Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface SHOULD NOT be modified. The implementation can be modified
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

//-- R15 is not stored
//-- Save waveform file and add it to the project
//-- Reset and launch simulation if you add internal signals to the waveform window

module ARM(
    input CLK,
    input RESET,
    //input Interrupt,             // for optional future use
    input [31:0] Instr_ARM,
    input [31:0] ReadData_ARM,     // equivalent to ReadData_M
    output MemWrite_ARM,           // connected to MemWrite_M (from CondLogic)
    output [31:0] PC_F,
    output [31:0] ALUResult_ARM,   // connected to ALUResult_M from ALU
    output [31:0] WriteData_ARM    // connected to RD2_M, propagated from Register File
    );
    
    /******************************** RegFile signals ********************************/
    //wire CLK ;
    //wire WE3_D;         , directly connected RegWrite_W to WE3_D
    wire [3:0] RA1_D;
    wire [3:0] RA2_D;
    wire [3:0] WA3_D;
    //wire [31:0] WD3_D;  , directly connected Result_W to WD3_D
    //wire [31:0] R15_D;  , directly connected PCPlus8_D to R15_D
    wire [31:0] RD1_D;
    wire [31:0] RD2_D;
    
    wire [3:0] Cond_D;    // need for CondLogic
    wire [1:0] Sh_D;      // need for Shifter
    wire [4:0] Shamt5_D;  // need for Shifter
    wire [31:0] ShIn_D;   // need for Shifter
    
    // Propagate to later stages
    reg [3:0] RA1_E = 4'b0;      // Hazard Hardware
    reg [3:0] RA2_E = 4'b0;      // Hazard Hardware
    reg [3:0] RA2_M = 4'b0;      // Hazard Hardware
    
    reg [3:0] WA3_E = 4'b0;      // delay Destination register along with Instruction
    reg [3:0] WA3_M = 4'b0;
    reg [3:0] WA3_W = 4'b0;
    
    reg [31:0] RD1_E = 32'b0;     // input for ALU / MCycle
    reg [31:0] RD2_E = 32'b0;     // input for ALU / MCycle
    reg [31:0] RD2_M = 32'b0;     // WriteData for Data Memory
    
    reg [3:0] Cond_E = 4'b0;     // input for CondLogic
    
    reg [1:0] Sh_E = 2'b0;       // shift-type for Shifter
    reg [4:0] Shamt5_E = 5'b0;   // shift-amount for Shifter
    reg [31:0] ShIn_E = 32'b0;   // input for Shifter
         
    
    /******************************** Decoder signals ********************************/
    wire [3:0] Rd_D;
    wire [1:0] Op_D;
    wire [5:0] Funct_D;
    wire [3:0] isMULorDIV_D;
    wire [3:0] isDIV_D;
    wire PCS_D;
    wire RegW_D;
    wire MemW_D;
    wire MemtoReg_D;
    wire ALUSrc_D;
    wire [1:0] ImmSrc_D;
    wire [1:0] RegSrc_D;
    wire NoWrite_D;
    wire [3:0] ALUControl_D;
    wire [3:0] FlagW_D;
    wire Start_D;
    wire [1:0] MCycleOp_D;
    wire ALUorMCycle_D;
    wire isArithmeticOp_D;
    wire isADC_D;
    
    // Propagate to later stages
    reg PCS_E = 1'b0;                // input for CondLogic
    reg RegW_E = 1'b0;               // input for CondLogic
    reg MemW_E = 1'b0;               // input for CondLogic
    reg NoWrite_E = 1'b0;            // input for CondLogic
    reg [3:0] FlagW_E = 4'b0;        // input for CondLogic

    reg MemtoReg_E = 1'b0;
    reg MemtoReg_M = 1'b0;
    reg MemtoReg_W = 1'b0;           // MUX to determine Result_W, choose between ALU output or Data Memory output
    
    reg ALUSrc_E = 1'b0;             // MUX to determine SrcB for ALU
    reg [3:0] ALUControl_E = 4'b0;   // determine operation for ALU
    reg isArithmeticOp_E = 1'b0;     // check if ALU does Arithmetic operation
    reg isADC_E = 1'b0;              // check if ALU is doing ADC operation
    
    reg Start_E = 1'b0;              // start signal for MCycle
    reg [1:0] MCycleOp_E = 2'b0;     // determine operation for MCycle
    reg ALUorMCycle_E = 1'b0;
    reg ALUorMCycle_M = 1'b0;
    reg ALUorMCycle_W = 1'b0;        // MUX to determine Result_W, choose between ALU output or MCycle output

   
    /******************************** CondLogic signals ********************************/
    //wire CLK ;
    //wire PCS_E;            , directly connected from E register (propagated from Decoder) to CondLogic
    //wire RegW_E;           , directly connected from E register (propagated from Decoder) to CondLogic
    //wire NoWrite_E;        , directly connected from E register (propagated from Decoder) to CondLogic
    //wire MemW_E;           , directly connected from E register (propagated from Decoder) to CondLogic
    //wire [3:0] FlagW_E;    , directly connected from E register (propagated from Decoder) to CondLogic
    //wire [3:0] Cond_E;     , directly connected from E register to CondLogic
    //wire [3:0] ALUFlags_E  , directly connected from ALU to CondLogic
    wire PCSrc_E;
    wire RegWrite_E; 
    wire MemWrite_E;
    wire C_Flag_E;
    
    // Propagate to later stages
    reg PCSrc_M = 1'b0;
    reg PCSrc_W = 1'b0;        // MUX to choose between ResultW or PCPlus8_D
    reg RegWrite_M = 1'b0;
    reg RegWrite_W = 1'b0;     // signal to control writing to Register File
    reg MemWrite_M = 1'b0;     // signal to control writing to Data Memory
    
    
    /******************************** Extend Module signals ********************************/
    //wire [1:0] ImmSrc_D;        , directly connected from Decoder to ExtendModule
    wire [23:0] InstrImm_D;
    wire [31:0] ExtImm_D;
    
    // Propagate to later stages
    reg [31:0] ExtImm_E = 32'b0;      // input for ALU    
    
    
    /************ Shifter signals (no Register-shifted Register support yet) ************/   
    //wire [1:0] Sh_E;         , directly connected from E register to Shifter
    //wire [4:0] Shamt5_E;     , directly connected from E register to Shifter
    //wire [31:0] ShIn_E;      , directly connected from E register to Shifter
    //wire C_Flag              , directly connected from CondLogic to Shifter
    wire [31:0] ShOut_E;
    wire Shifter_carryOut_E;
    
    
    /******************************** ALU signals ********************************/
     // ALUResult already connected from ALU to ARM.v's output
     // ALUFlags already connected from ALU to CondLogic
    wire [31:0] SrcA_E;          // E->E forwarding (propagated from Register File), M->E forwarding, W->E forwarding
    wire [31:0] SrcB_E;          // E->E forwarding (propagated from ExtendModule), M->E forwarding, W->E forwarding OR Shifter
    //wire [3:0] ALUControl_E;   , direcly connected from E register (propagated from Decoder) to ALU
    //wire C_Flag;               , directly connected from CondLogic to ALU
    //wire isArithmeticOp;       , directly connected from E register (propagated from Decoder) to ALU
    //wire isADC;                , directly connected from E register (propagated from Decoder) to ALU
    //wire shifter_carryOut;     , directly connected from Shifter to ALU
    wire [31:0] ALUResult_E;
    wire [3:0] ALUFlags_E;       // connect from ALU to CondLogic
    
    // Propagate to later stages
    reg [31:0] ALUResult_M = 32'b0;    // used for Data Forwarding (M->E) 
    reg [31:0] ALUResult_W = 32'b0;    // used for potential ResultW, which can then be used for Data Forwarding (W->E)
    
    /************ ProgramCounter signals ************/
    //wire CLK;
    //wire RESET;
    wire WE_PC_F;    
    wire [31:0] PC_IN;
    //wire [31:0] PC_F;
     
     
    /************ MCycle (Multiplication/Division) signals ************/
    wire [31:0] Operand1_E;
    wire [31:0] Operand2_E;
    wire Busy_E;
    wire [31:0] Result1_E;
    wire [31:0] Result2_E;
    
    // Propagate to later stages
    reg [31:0] Result1_M = 32'b0;
    reg [31:0] Result1_W = 32'b0;   // potential ResultW
    
    /************************************************ Hazard Hardware ************************************************/
    ////////////////////////// Data Forwarding //////////////////////////
    wire Match_1E_M;
    wire Match_2E_M;
    wire Match_1E_W;
    wire Match_2E_W;
    wire Match_12D_E;
    reg ForwardM = 1'b0; 
    reg [1:0] ForwardA_E = 2'b0;
    reg [1:0] ForwardB_E = 2'b0;
    reg ldrstall = 1'b0;
    reg Stall_F = 1'b0;
    reg Stall_D = 1'b0;
    reg Flush_E = 1'b0;
    
    assign Match_1E_M = (RA1_E == WA3_M);
    assign Match_2E_M = (RA2_E == WA3_M);
    assign Match_1E_W = (RA1_E == WA3_W);
    assign Match_2E_W = (RA2_E == WA3_W);
    assign Match_12D_E = (RA1_D == WA3_E) || (RA2_D == WA3_E);  // Source Reg in D same as Rd in Ex
    
    always @ (Match_1E_M, Match_1E_W, RegWrite_M, RegWrite_W) begin
        if (Match_1E_M & RegWrite_M) 
            ForwardA_E = 2'b10;
        else if (Match_1E_W & RegWrite_W)
            ForwardA_E = 2'b01;
        else ForwardA_E = 2'b00;
    end
    
    always @ (Match_2E_M, Match_2E_W, RegWrite_M, RegWrite_W, ALUSrc_E) begin
        if (Match_2E_M & RegWrite_M & ~ALUSrc_E)
            ForwardB_E = 2'b10;
        else if (Match_2E_W & RegWrite_W & ~ALUSrc_E)
            ForwardB_E = 2'b01;
        else ForwardB_E = 2'b00;
    end
    
    // Check Mem-mem copy     
    always @ (RA2_M, MemWrite_M, MemtoReg_W & RegWrite_W) begin
        // check M stage for STR, WB has LDR and LDR has executed
        ForwardM = (RA2_M == WA3_W) & MemWrite_M & MemtoReg_W & RegWrite_W;
    end
    
    ////////////////////////// Load and Use //////////////////////////
    always @ (WA3_E, MemtoReg_E) begin
        // LDR in E and event: Match_12D_E
        ldrstall = MemtoReg_E & RegWrite_E & Match_12D_E;
        Stall_F = ldrstall;
        Stall_D = ldrstall;
        Flush_E = ldrstall;
        
    end
    
    /************ Other internal signals ************/
    wire [31:0] PCPlus4_F;
    wire [31:0] PCPlus8_D;
    wire [31:0] Result_W;
                    
    reg [31:0] Instr_D = 32'b0;
    always @(posedge CLK) begin
        if (RESET) begin
            Instr_D <= 32'b0;
        end  
        else if (Stall_D == 1) begin
            Instr_D <= Instr_D;
        end
        else begin
            Instr_D <= Instr_ARM;
        end
    end
    
    
    reg [31:0] ReadData_W = 32'b0;
    always @(posedge CLK) begin
        if (RESET) begin
            ReadData_W <= 32'b0;
        end else begin
            ReadData_W <= ReadData_ARM;
        end
    end
    
    assign PCPlus4_F = PC_F + 4;
    assign PCPlus8_D = PCPlus4_F;
    assign Result_W = (MemtoReg_W == 1'b1) ? ReadData_W :   // LDR instruction
                    (ALUorMCycle_W == 1'b1) ? Result1_W :   // MCycle instructions
                    ALUResult_W;                            // DP and Branch instructions
                    

    
    /************************************************ Implement datapath connections ************************************************/
    assign WE_PC_F = ~Busy_E & ~Stall_F; // Control for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.
    assign MemWrite_ARM = MemWrite_M;
    assign ALUResult_ARM = ALUResult_M;
    assign WriteData_ARM = ForwardM ? Result_W : RD2_M;
    
    ///////////////////////////////////////////// RegFile connections /////////////////////////////////////////////
    assign RA1_D = (RegSrc_D[0] == 1'b1) ? 4'd15 :      // Branch instructions
                 (Start_D == 1'b1) ? Instr_D[11:8] :    // UMUL, UDIV instructions
                 Instr_D[19:16];                        // DP, Memory instructions
                
    assign RA2_D = (RegSrc_D[1] == 1'b0) ? Instr_D[3:0] : Instr_D[15:12];
    assign WA3_D = (Start_D == 1'b1) ? Instr_D[19:16] : Instr_D[15:12];
     // RD1_D and RD2_D computed inside RegFile
    
    assign Cond_D = Instr_D[31:28];
    assign Sh_D = Instr_D[6:5];
    assign Shamt5_D = Instr_D[11:7];
    assign ShIn_D = RD2_D;
    
    // RA1_E, RA2_E, RA2_M used as Hazard Hardware
    always @(posedge CLK) begin
        if (RESET) begin
            RA2_M <= 4'b0;
            RA1_E <= 4'b0;
            RA2_E <= 4'b0;
        end else begin
            RA2_M <= RA2_E;
            RA1_E <= RA1_D;
            RA2_E <= RA2_D;
        end
    end
    
    // delay Destination register along with Instruction
    always @(posedge CLK) begin
        if (RESET) begin
            WA3_E <= 4'b0;
            WA3_M <= 4'b0;
            WA3_W <= 4'b0;
        end else begin
            WA3_E <= WA3_D;
            WA3_M <= WA3_E;
            WA3_W <= WA3_M;
        end
    end
    
    // RD1 and RD2 propagates from RegFile to ALU/MCycle
    always @(posedge CLK) begin
        if (RESET) begin
            RD1_E <= 32'b0;
            RD2_E <= 32'b0;
            RD2_M <= 32'b0;
        end else begin
            RD1_E <= RD1_D;
            RD2_E <= RD2_D;
            RD2_M <= RD2_E;
        end
    end
    
    // Cond propagates from D stage to CondLogic
    always @(posedge CLK) begin
        if (RESET) begin
            Cond_E <= 4'b0;
        end else begin
            Cond_E <= Cond_D;
        end
    end
    
    // Sh, Shamt5, ShIn propagates from D stage to Shifter
    always @(posedge CLK) begin
        if (RESET) begin
            Sh_E <= 2'b0;
            Shamt5_E <= 5'b0;
            ShIn_E <= 32'b0;
        end else begin
            Sh_E <= Sh_D;
            Shamt5_E <= Shamt5_D;
            ShIn_E <= ShIn_D;
        end
    end
         
    ///////////////////////////////////////////// Decoder connections /////////////////////////////////////////////
    assign Rd_D = (Start_D == 1'b1) ? Instr_D[19:16] : Instr_D[15:12];
    assign Op_D = Instr_D[27:26];
    assign Funct_D = Instr_D[25:20];
    assign isMULorDIV_D = Instr_D[7:4];
    assign isDIV_D = Instr_D[15:12];
    
    
    // PCS, RegW, MemW, NoWrite, FlagW propagates from Decoder to CondLogic
    always @(posedge CLK) begin
        if (RESET) begin
            PCS_E <= 1'b0;
            RegW_E <= 1'b0;
            MemW_E <= 1'b0;
            NoWrite_E <= 1'b0;
            FlagW_E <= 4'b0;
        end else begin
            PCS_E <= Flush_E ? 0 : PCS_D;
            RegW_E <= Flush_E ? 0 : RegW_D;
            MemW_E <= Flush_E? 0 : MemW_D;
            NoWrite_E <= NoWrite_D;
            FlagW_E <= Flush_E ? 0 : FlagW_D;
        end
    end
    
    // MemtoReg propagates from Decoder to W stage, used as MUX to determine Result_W
    always @(posedge CLK) begin
        if (RESET) begin
            MemtoReg_E <= 1'b0;
            MemtoReg_M <= 1'b0;
            MemtoReg_W <= 1'b0;
        end else begin
            MemtoReg_E <= MemtoReg_D;
            MemtoReg_M <= MemtoReg_E;
            MemtoReg_W <= MemtoReg_M;
        end
    end
    
    // ALUSrc, ALUControl, isArithmeticOp, isADC propagates from Decoder to ALU
    always @(posedge CLK) begin
        if (RESET) begin
            ALUSrc_E <= 1'b0;
            ALUControl_E <= 4'b0;
            isArithmeticOp_E <= 1'b0;
            isADC_E <= 1'b0;
        end else begin
            ALUSrc_E <= ALUSrc_D;
            ALUControl_E <= ALUControl_D;
            isArithmeticOp_E <= isArithmeticOp_D;
            isADC_E <= isADC_D;
        end
    end
    
    // Start, MCycleOp propagates from Decoder to MCycle
    always @(posedge CLK) begin
        if (RESET) begin
            Start_E <= 1'b0;
            MCycleOp_E <= 2'b0;
        end else begin
            Start_E <= Start_D;
            MCycleOp_E <= MCycleOp_D;
        end
    end
    
    // ALUorMCycle propagates from Decoder to W stage, used as MUX to determine Result_W
    always @(posedge CLK) begin
        if (RESET) begin
            ALUorMCycle_E <= 1'b0;
            ALUorMCycle_M <= 1'b0;
            ALUorMCycle_W <= 1'b0;
        end else begin
            ALUorMCycle_E <= ALUorMCycle_D;
            ALUorMCycle_M <= ALUorMCycle_E;
            ALUorMCycle_W <= ALUorMCycle_M;
        end
    end
    
    ///////////////////////////////////////////// CondLogic connections /////////////////////////////////////////////
    // PCSrc propagates from CondLogic to W stage, used as MUX to determine PC_IN
    always @(posedge CLK) begin
        if (RESET) begin
            PCSrc_M <= 1'b0;
            PCSrc_W <= 1'b0;
        end else begin
            PCSrc_M <= PCSrc_E;
            PCSrc_W <= PCSrc_M;
        end
    end
     
    // RegWrite propagates from CondLogic to W stage, used to control writing to Register File
    always @(posedge CLK) begin
        if (RESET) begin
            RegWrite_M <= 1'b0;
            RegWrite_W <= 1'b0;
        end else begin
            RegWrite_M <= RegWrite_E;
            RegWrite_W <= RegWrite_M;
        end
    end
     
    // MemWrite propagates from CondLogic to M stage, used to control writing to Data Memory
    always @(posedge CLK) begin
        if (RESET) begin
            MemWrite_M <= 1'b0;
        end else begin
            MemWrite_M <= MemWrite_E;
        end
    end
         
         
    ///////////////////////////////////////////// ExtendModule connections /////////////////////////////////////////////
    assign InstrImm_D = Instr_D[23:0];
    
    // ExtImm propagates from ExtendModule to ALU
    always @(posedge CLK) begin
        if (RESET) begin
            ExtImm_E <= 32'b0;
        end else begin
            ExtImm_E <= ExtImm_D;
        end
    end
     
     
   ///////////////////////////////////////////// Shifter connections /////////////////////////////////////////////
   
    
   ///////////////////////////////////////////// ALU connections /////////////////////////////////////////////
   assign SrcA_E = (ForwardA_E == 2'b10) ? ALUResult_M :
                   (ForwardA_E == 2'b01) ? ALUResult_W : RD1_E;
                   
   assign SrcB_E = (ForwardB_E == 2'b10) ? ALUResult_M :
                   (ForwardB_E == 2'b01) ? ALUResult_W :
                   (ALUSrc_E == 1'b0)    ? ShOut_E : ExtImm_E;
                                          
   // ALUResult propagates from ALU to M stage (used for M->E forwarding) 
   //                              and W stage (potential Result_W, which can be used for W->E forwarding)
   always @(posedge CLK) begin
       if (RESET) begin
           ALUResult_M <= 32'b0;
           ALUResult_W <= 32'b0;
       end else begin
           ALUResult_M <= ALUResult_E;
           ALUResult_W <= ALUResult_M;
       end
   end

   ///////////////////////////////////////////// ProgramCounter connections /////////////////////////////////////////////
   assign PC_IN = (PCSrc_W == 1'b0) ? PCPlus4_F : Result_W;
   
   
   ///////////////////////////////////////////// MCycle connections /////////////////////////////////////////////
    // RD1 = Rs (operand2)
    // RD2 = Rm (operand1)
    // Rd = Rm * Rs, Rd = Rm / Rs
   assign Operand1_E = RD2_E;   // not making use of Shifter for MCycle
   assign Operand2_E = RD1_E;
   
   // Result1 propagates to W stage, where it is potential Results_W
   always @(posedge CLK) begin
       if (RESET) begin
           Result1_M <= 32'b0;
           Result1_W <= 32'b0;
       end else begin
           Result1_M <= Result1_E;
           Result1_W <= Result1_M;
       end
   end
   
   
   /******************************************* Instantations *******************************************/
    
    // Instantiate RegFile
    RegFile RegFile1( 
                    .CLK(CLK),
                    .WE3(RegWrite_W),
                    .A1(RA1_D),
                    .A2(RA2_D),
                    .A3(WA3_W),
                    .WD3(Result_W),
                    .R15(PCPlus8_D),
                    .RD1(RD1_D),
                    .RD2(RD2_D)     
                );
                
    // Instantiate Decoder
    Decoder Decoder1(
                    .Rd(Rd_D),
                    .Op(Op_D),
                    .Funct(Funct_D),
                    .isMULorDIV(isMULorDIV_D),
                    .isDIV(isDIV_D),
                    .PCS(PCS_D),
                    .RegW(RegW_D),
                    .MemW(MemW_D),
                    .MemtoReg(MemtoReg_D),
                    .ALUSrc(ALUSrc_D),
                    .ImmSrc(ImmSrc_D),
                    .RegSrc(RegSrc_D),
                    .NoWrite(NoWrite_D),
                    .ALUControl(ALUControl_D),
                    .FlagW(FlagW_D),
                    .Start(Start_D),
                    .MCycleOp(MCycleOp_D),
                    .ALUorMCycle(ALUorMCycle_D),
                    .isArithmeticOp(isArithmeticOp_D),
                    .isADC(isADC_D)
                );
                
    // Instantiate CondLogic
    CondLogic CondLogic1(
                    .CLK(CLK),
                    .PCS(PCS_E),
                    .RegW(RegW_E),
                    .NoWrite(NoWrite_E),
                    .MemW(MemW_E),
                    .FlagW(FlagW_E),
                    .Cond(Cond_E),
                    .ALUFlags(ALUFlags_E),
                    .PCSrc(PCSrc_E),
                    .RegWrite(RegWrite_E),
                    .MemWrite(MemWrite_E),
                    .C_Flag(C_Flag_E)
                );
                
     // Instantiate Extend Module
    Extend Extend1(
                    .ImmSrc(ImmSrc_D),
                    .InstrImm(InstrImm_D),
                    .ExtImm(ExtImm_D)
                );                
                
    // Instantiate Shifter        
    Shifter Shifter1(
                    .Sh(Sh_E),
                    .Shamt5(Shamt5_E),
                    .ShIn(ShIn_E),
                    .current_CFlag(C_Flag_E),
                    .ShOut(ShOut_E),
                    .Shifter_carryOut(Shifter_carryOut_E)
                );
                
    // Instantiate ALU        
    ALU ALU1(
               .Src_A(SrcA_E),
               .Src_B(SrcB_E),
               .ALUControl(ALUControl_E),
               .C_Flag(C_Flag_E),
               .isArithmeticOp(isArithmeticOp_E),
               .isADC(isADC_E),
               .Shifter_carryOut(Shifter_carryOut_E),
               .ALUResult(ALUResult_E),
               .ALUFlags(ALUFlags_E)
             );                
    
    // Instantiate ProgramCounter    
    ProgramCounter ProgramCounter1(
                    .CLK(CLK),
                    .RESET(RESET),
                    .WE_PC(WE_PC_F),    
                    .PC_IN(PC_IN),
                    .PC(PC_F)
                );
                
     // Instantiate MCycle
     MCycle MCycle1 (
                     .CLK(CLK),
                     .RESET(RESET),
                     .Start(Start_E),
                     .MCycleOp(MCycleOp_E),
                     .Operand1(Operand1_E),
                     .Operand2(Operand2_E),
                     .Result1(Result1_E),
                     .Result2(Result2_E),
                     .Busy(Busy_E)
                );                 
endmodule
