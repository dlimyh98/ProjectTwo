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
    //input Interrupt,       // for optional future use
    input [31:0] Instr,
    input [31:0] ReadData,
    output MemWrite,
    output [31:0] PC,
    output [31:0] ALUResult,
    output [31:0] WriteData  // for checking what is at RD2
    );
    
    /************ RegFile signals ************/
    //wire CLK ;
    wire WE3 ;
    wire [3:0] A1 ;
    wire [3:0] A2 ;
    wire [3:0] A3 ;
    wire [31:0] WD3 ;
    wire [31:0] R15 ;
    wire [31:0] RD1 ;
    wire [31:0] RD2 ;
    
    /************ Extend Module signals ************/
    wire [1:0] ImmSrc ;
    wire [23:0] InstrImm ;
    wire [31:0] ExtImm ;
    
    /************ Decoder signals ************/
    wire [3:0] Rd ;
    wire [1:0] Op ;
    wire [5:0] Funct ;
    wire [3:0] isMULDIV;
    wire [3:0] isDIV;
    //wire PCS ;
    //wire RegW ;
    //wire MemW ;
    wire MemtoReg ;
    wire ALUSrc ;
    //wire [1:0] ImmSrc ;
    wire [1:0] RegSrc ;
    //wire NoWrite ;
    //wire [3:0] ALUControl ;
    //wire [3:0] FlagW ;
    wire Start;
    wire [1:0] MCycleOp;
    wire ALUorMCycle;
    wire isArithmeticOp;
    wire isADC;
    
    /************ CondLogic signals ************/
    //wire CLK ;
    wire PCS ;
    wire RegW ;
    wire NoWrite ;
    wire MemW ;
    wire [3:0] FlagW ;
    wire [3:0] Cond ;
    //wire [3:0] ALUFlags,
    wire PCSrc ;
    wire RegWrite ; 
    //wire MemWrite
    wire C_Flag;
    
    /************ Shifter signals (no Register-shifted Register support yet) ************/   
    wire [1:0] Sh ;
    wire [4:0] Shamt5 ;
    wire [31:0] ShIn ;
    wire [31:0] ShOut ;
    wire Shifter_carryOut;
    
    /************ ALU signals ************/
    wire [31:0] Src_A ;
    wire [31:0] Src_B ;
    wire [3:0] ALUControl ;
   // wire [31:0] ALUResult ;
    wire [3:0] ALUFlags ;
    
    /************ ProgramCounter signals ************/
    //wire CLK ;
    //wire RESET ;
    wire WE_PC ;    
    wire [31:0] PC_IN ;
    //wire [31:0] PC ;
     
    /************ MCycle (Multiplication/Division) signals ************/
    wire [31:0] Operand1;
    wire [31:0] Operand2;
    wire Busy;
    wire [31:0] Result1;
    wire [31:0] Result2;
    
    /************ Other internal signals ************/    
    wire [31:0] PCPlus4 ;
    wire [31:0] PCPlus8 ;
    wire [31:0] Result ;
    assign PCPlus4 = PC + 4;
    assign PCPlus8 = PC + 8;
    assign Result = (MemtoReg == 1'b1) ? ReadData :     // LDR instruction
                    (ALUorMCycle == 1'b1) ? Result1 :   // MCycle instructions
                    ALUResult;                          // DP and Branch instructions
    
    /************ Implement datapath connections ************/
    assign WE_PC = ~Busy ; // Will need to control it for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.
    assign WriteData = RD2;
    
    /////////////////////////// ExtendModule connections ///////////////////////////
    assign InstrImm = Instr[23:0];
     // ImmSrc already connected from Decoder to ExtendModule
     // ExtImm already connected from ExtendModule to ALU
     
    /////////////////////////// Decoder connections ///////////////////////////
    assign Rd = (Start == 1'b1) ? Instr[19:16] : Instr[15:12];
    assign Op = Instr[27:26];
    assign Funct = Instr[25:20];
    assign isMULDIV = Instr[7:4];
    assign isDIV = Instr[15:12];
     // PCS, RegW, MemW, NoWrite, FlagW already connected from Decoder to CondLogic
     // ALUControl already connected from Decoder to ALU
     // MemtoReg, ALUSrc, ImmSrc, RegSrc used as multiplexer    
     
    /////////////////////////// RegFile connections ///////////////////////////
    assign WE3 = RegWrite;
                 
    assign A1 = (RegSrc[0] == 1'b1) ? 4'd15 :    // Branch instructions
                (Start == 1'b1) ? Instr[11:8] :  // UMUL, UDIV instructions
                Instr[19:16];                    // DP, Memory instructions
                
    assign A2 = (RegSrc[1] == 1'b0) ? Instr[3:0] : Instr[15:12];
    assign A3 = (Start == 1'b1) ? Instr[19:16] : Instr[15:12];
    assign WD3 = Result;
    assign R15 = PCPlus8;
     // RD1 and RD2 computed inside RegFile, then used in ALU and Shifter
     
    /////////////////////////// CondLogic connections ///////////////////////////
    assign Cond = Instr[31:28];
     // PCS, RegW, NoWrite, MemW, FlagW already connected from Decoder to CondLogic
     // ALUFlags already connected from ALU to CondLogic
     // PCSrc used as multiplexer
     // RegWrite already connected to Decoder (WE3)
     // MemWrite already connected to ARM.v's output
     
    /////////////////////////// Shifter connections ///////////////////////////
    assign Sh = Instr[6:5];
    assign Shamt5 = Instr[11:7];
    assign ShIn = RD2;
     // ShOut already connected from Shifter to ALU
    
    /////////////////////////// ALU connections ///////////////////////////
    assign Src_A = RD1;
    assign Src_B = (ALUSrc == 1'b0) ? ShOut : ExtImm;
     // ALUControl already connected from Decoder to ALU
     // ALUResult already connected from ALU to ARM.v's output
     // ALUFlags already connected from ALU to CondLogic
     
   /////////////////////////// ProgramCounter connections ///////////////////////////
   assign PC_IN = (PCSrc == 1'b0) ? PCPlus4 : Result;
   
   /////////////////////////// MCycle connections ///////////////////////////
   // RD1 = Rs (operand2)
   // RD2 = Rm (operand1)
   // Rd = Rm * Rs, Rd = Rm / Rs
   assign Operand1 = RD2;   // not making use of Shifter for MCycle
   assign Operand2 = RD1;
   
   /************ Instantations ************/
    
    // Instantiate RegFile
    RegFile RegFile1( 
                    CLK,
                    WE3,
                    A1,
                    A2,
                    A3,
                    WD3,
                    R15,
                    RD1,
                    RD2     
                );
                
     // Instantiate Extend Module
    Extend Extend1(
                    ImmSrc,
                    InstrImm,
                    ExtImm
                );
                
    // Instantiate Decoder
    Decoder Decoder1(
                    Rd,
                    Op,
                    Funct,
                    isMULDIV,
                    isDIV,
                    PCS,
                    RegW,
                    MemW,
                    MemtoReg,
                    ALUSrc,
                    ImmSrc,
                    RegSrc,
                    NoWrite,
                    ALUControl,
                    FlagW,
                    Start,
                    MCycleOp,
                    ALUorMCycle,
                    isArithmeticOp,
                    isADC
                );
                                
    // Instantiate CondLogic
    CondLogic CondLogic1(
                    CLK,
                    PCS,
                    RegW,
                    NoWrite,
                    MemW,
                    FlagW,
                    Cond,
                    ALUFlags,
                    PCSrc,
                    RegWrite,
                    MemWrite,
                    C_Flag
                );
                
    // Instantiate Shifter        
    Shifter Shifter1(
                    Sh,
                    Shamt5,
                    ShIn,
                    C_Flag,
                    ShOut,
                    Shifter_carryOut
                );
                
    // Instantiate ALU        
    ALU ALU1(
               Src_A,
               Src_B,
               ALUControl,
               C_Flag,
               isArithmeticOp,
               isADC,
               Shifter_carryOut,
               ALUResult,
               ALUFlags
             );                
    
    // Instantiate ProgramCounter    
    ProgramCounter ProgramCounter1(
                    CLK,
                    RESET,
                    WE_PC,    
                    PC_IN,
                    PC  
                );
                
     // Instantiate MCycle
     MCycle MCycle1 (
                     CLK,
                     RESET,
                     Start,
                     MCycleOp,
                     Operand1,
                     Operand2,
                     Result1,
                     Result2,
                     Busy
                );                 
endmodule
