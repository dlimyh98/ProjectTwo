`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS
// Engineer: Shahzor Ahmad, Rajesh C Panicker
// 
// Create Date: 27.09.2016 16:55:23
// Design Name: 
// Module Name: test_MCycle
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/* 
----------------------------------------------------------------------------------
--	(c) Shahzor Ahmad, Rajesh C Panicker
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

module test_MCycle(

    );
    
    // DECLARE INPUT SIGNALs
    reg CLK = 0 ;
    reg RESET = 0 ;
    reg Start = 0 ;
    reg [1:0] MCycleOp = 0 ;
    reg [3:0] Operand1 = 0 ;
    reg [3:0] Operand2 = 0 ;

    // DECLARE OUTPUT SIGNALs
    wire [3:0] Result1 ;
    wire [3:0] Result2 ;
    wire Busy ;
    
    // INSTANTIATE DEVICE/UNIT UNDER TEST (DUT/UUT)
    MCycle dut( 
        CLK, 
        RESET, 
        Start, 
        MCycleOp, 
        Operand1, 
        Operand2, 
        Result1, 
        Result2, 
        Busy
        ) ;
    
    // STIMULI
    initial begin
        // hold reset state for 100 ns.
        #10 ;    
        MCycleOp = 2'b00 ;  // signed mul
        // -1 x -1 = 1 or 0001
        Operand1 = 4'b1111 ;    
        Operand2 = 4'b1111 ;
        Start = 1'b1 ; // Start is asserted continously(Operations are performed back to back). To try a non-continous Start, you can uncomment the commented lines.    

        wait(Busy) ; // suspend initial block till condition becomes true  ;
        wait(~Busy) ;
        #10 ;
        Start = 1'b0 ;
        #10 ;
        
        
        MCycleOp = 2'b00 ;  // signed mul
        // -3 x 2 = -6 or 1010
        Operand1 = 4'b1101 ;    
        Operand2 = 4'b0010 ;
        Start = 1'b1 ; // Start is asserted continously(Operations are performed back to back). To try a non-continous Start, you can uncomment the commented lines.    

        wait(Busy) ; // suspend initial block till condition becomes true  ;
        wait(~Busy) ;
        #10 ;
        Start = 1'b0 ;
        #10 ;
        
        
        MCycleOp = 2'b01 ;      // unsigned mul
        // 2 x 6 = 12 or 1100
        Operand1 = 4'b0010 ;
        Operand2 = 4'b0110 ;
        Start = 1'b1 ;
        
        wait(Busy) ; 
        wait(~Busy) ;
        #10 ;
        Start = 1'b0 ;
        #10 ;
        
        // Test cases for Divide
        // 10: signed, 11: unsigned
        //
        // -ve / +ve
        MCycleOp = 2'b10 ;      
        // -4 / 3 = -1 R -1 or 1111 R 1111
        Operand1 = 4'b1100 ;        // 0xC
        Operand2 = 4'b0011 ;        // 0x3
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        #10 ;
        Start = 1'b0 ;
        #10 ;
        
        // -ve / -ve
        MCycleOp = 2'b10 ;      
        // -6 / -4 = 1 R -2 or 0001 R 1111
        Operand1 = 4'b1010 ;        // 0xA
        Operand2 = 4'b1100 ;        // 0xC
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        #10 ;
        Start = 1'b0 ;
        #10 ;
        
        // +ve / +ve
        MCycleOp = 2'b11 ;      
        // 8 / 4 = 2 R 0 or 0010 R 0000
        Operand1 = 4'b1000 ;        // 0x8
        Operand2 = 4'b0100 ;        // 0x4
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
        // +ve / -ve
        MCycleOp = 2'b10 ;      
        // 3 / -2 = 1 R -1 or 0001 R 1111
        Operand1 = 4'b0011 ;        // 0x3
        Operand2 = 4'b1110 ;        // 0xE
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
        // Divide 0 (unsigned)
        MCycleOp = 2'b11 ;      
        // 0 / 5 = 0 R 5 or 0000 R 0101
        Operand1 = 4'b0000 ;        // 0x0
        Operand2 = 4'b0101 ;        // 0x5
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
        // Divide 0 (signed)
        MCycleOp = 2'b10 ;      
        // 0 / -2 = 0 R -2 or 0000 R 1110 
        Operand1 = 4'b0000 ;        // 0x0
        Operand2 = 4'b1110 ;        // 0xE
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
        // Divisor > Dividend
        MCycleOp = 2'b11 ;      
        // 4 / 8 = 0 R 8 or 0000 R 1000
        Operand1 = 4'b0100 ;        // 0x4
        Operand2 = 4'b1000 ;        // 0x8
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
        // Divide by whole (signed)
        MCycleOp = 2'b10 ;      
        // -4 / -4 = 1 R 0 or 0001 R 0000
        Operand1 = 4'b1100 ;    // 0xC
        Operand2 = 4'b1100 ;    // 0xc
        Start = 1'b1 ;
        wait(Busy) ; 
        wait(~Busy) ; 
        Start = 1'b0 ;
        
    end
     
    // GENERATE CLOCK       
    always begin 
        #5 CLK = ~CLK ; 
        // invert CLK every 5 time units 
    end
    
endmodule
















