`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

module Decoder(
    input [3:0] Rd,
    input [1:0] Op,
    input [5:0] Funct,
    output reg PCS = 1'b0,
    output reg RegW = 1'b0,
    output reg MemW = 1'b0,
    output reg MemtoReg = 1'b0,
    output reg ALUSrc = 1'b0,
    output reg [1:0] ImmSrc = 2'b00,
    output reg [1:0] RegSrc = 2'b00,
    output reg NoWrite,
    output reg [1:0] ALUControl = 2'b00,
    output reg [1:0] FlagW = 2'b00
    );
    
    wire ALUOp, Branch;
    reg ALUOp_toSend, Branch_toSend = 1'b0;
    assign ALUOp = ALUOp_toSend;
    assign Branch = Branch_toSend;
   
    
    // Main Decoder Logic
    // Input = Op, Funct[5], Funct[0]
    // Output = RegW, MemW, MemtoReg, ALUSrc, ImmSrc, RegSrc
    always @ (Op) begin
        case (Op)
            2'b00 : begin
                        // assert must be DP Reg or DP Imm
                        {Branch_toSend, MemtoReg, MemW} = 1'b0;
                        {RegW, ALUOp_toSend} = 1'b1;
                        
                        if (Funct[5] == 0) begin
                            // assert DP Reg
                            ALUSrc = 1'b0;
                            {ImmSrc, RegSrc} = 2'b00;   // ImmSrc == XX for DP Reg
                        end else begin
                            // assert DP Imm
                            ALUSrc = 1'b1;
                            {ImmSrc, RegSrc} = 2'b00;   // RegSrc == X0 for DP Imm
                        end
                    end
                    
            2'b01 : begin
                        // assert must be STR or LDR
                        {Branch_toSend, ALUOp_toSend} = 1'b0;
                        {MemtoReg, ALUSrc} = 1'b1;    // MemToReg == X for STR
                        ImmSrc = 2'b01;
                        RegSrc = 2'b10;    // RegSrc == X0 for LDR
                        
                        if (Funct[0] == 0) begin
                            // assert STR
                            MemW = 1'b1;
                            RegW = 1'b0;
                        end else begin
                            // assert LDR
                            MemW = 1'b0;
                            RegW = 1'b1;
                        end
                    end
                    
            2'b10 : begin
                        // assert must be Branch
                        {MemtoReg, MemW, RegW, ALUOp_toSend} = 1'b0;
                        {Branch_toSend, ALUSrc} = 1'b1;
                        ImmSrc = 2'b10;
                        RegSrc = 2'b01;
                    end
                    
            2'b11 : begin
                        // assert must be invalid command (all output signals X)
                        {Branch_toSend, MemtoReg, MemW, ALUSrc, RegW, ALUOp_toSend} = 1'b0;
                        {ImmSrc, RegSrc} = 2'b0;
                    end                                      
        endcase
    end
    
    
    // PC Logic
    // Input = Branch. RegW, Rd[3:0]
    // Output = PCS
    always @ (Branch, RegW) begin
        if (Branch == 1'b0) begin
            if (Rd == 4'd15 && RegW == 1'b1) PCS = 1'b1; // PC is Rd for some instruction
            else PCS = 1'b0;                             // PC is not Rd for some instruction
        end else begin
            PCS = 1'b1;
        end
    end
    
    // ALU Decoder Logic
    // Input = ALUOp, Funct[4:0] (Funt[5] is I bit)
    // Output = ALUControl[1:0] and FlagW[1:0]
    always @ (ALUOp) begin        
        if (ALUOp == 1'b0) begin
            // assert must be STR/LDR (assumed positive offset only)
            // assert must be B
            ALUControl = 2'b00;
            FlagW = 2'b00;
        end else begin
            // assert must be DP instructions (positive/negative offset)
            // TODO : STR/LDR w negative offset (extend ALUOp to 2bits)
            // TODO : CMP and CMN
            // TODO : Src for DP instructions with immediate shift (FlagW change)
            FlagW = Funct[0] ? 2'b11 : 2'b00;
            case (Funct[4:1])   // Funct[4:1] == cmd (DP) or PUBW (Memory)
                4'b0100 : ALUControl = 2'b00;   // ADD or ADDS
                4'b0010 : ALUControl = 2'b01;   // SUB or SUBS   
                4'b0000 : ALUControl = 2'b10;   // AND or ANDS                  
                4'b1100 : ALUControl = 2'b11;   // ORR or ORRS                                 
            endcase
        end
    end
endmodule