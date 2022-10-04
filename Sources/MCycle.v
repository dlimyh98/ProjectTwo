`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS
// Engineer: Shahzor Ahmad, Rajesh C Panicker
// 
// Create Date: 27.09.2016 10:59:44
// Design Name: 
// Module Name: MCycle
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

module MCycle

    #(parameter width = 4) // Keep this at 4 to verify your algorithms with 4 bit numbers (easier). When using MCycle as a component in ARM, generic map it to 32.
    (
        input CLK,
        input RESET, // Connect this to the reset of the ARM processor.
        input Start, // Multi-cycle Enable. The control unit should assert this when an instruction with a multi-cycle operation is detected.
        input [1:0] MCycleOp, // Multi-cycle Operation. "00" for signed multiplication, "01" for unsigned multiplication, "10" for signed division, "11" for unsigned division. Generated by Control unit
        input [width-1:0] Operand1, // Multiplicand / Dividend
        input [width-1:0] Operand2, // Multiplier / Divisor
        output reg [width-1:0] Result1, // LSW of Product / Quotient
        output reg [width-1:0] Result2, // MSW of Product / Remainder
        output reg Busy // Set immediately when Start is set. Cleared when the Results become ready. This bit can be used to stall the processor while multi-cycle operations are on.
    );
    
// use the Busy signal to reset WE_PC to 0 in ARM.v (aka "freeze" PC). The two signals are complements of each other
// since the IDLE_PROCESS is combinational, instantaneously asserts Busy once Start is asserted
  
    parameter IDLE = 1'b0 ;  // will cause a warning which is ok to ignore - [Synth 8-2507] parameter declaration becomes local in MCycle with formal parameter declaration list...

    parameter COMPUTING = 1'b1 ; // this line will also cause the above warning
    reg state = IDLE ;
    reg n_state = IDLE ;
   
    reg done ;
    reg diff ;
    reg [7:0] count = 0 ; // assuming no computation takes more than 256 cycles.
    reg [2*width-1:0] temp_sum = 0 ;
    reg [2*width-1:0] shifted_op1 = 0 ;
    reg [2*width-1:0] shifted_op2 = 0 ;    
    
    reg [width-1:0] quotient = 0 ;
    
     
   
    always@( state, done, Start, RESET ) begin : IDLE_PROCESS  
		// Note : This block uses non-blocking assignments to get around an unpredictable Verilog simulation behaviour.
        // default outputs
        Busy <= 1'b0 ;
        n_state <= IDLE ;
        
        // reset
        if(~RESET)
            case(state)
                IDLE: begin
                    if(Start) begin // note: a mealy machine, since output depends on current state (IDLE) & input (Start)
                        n_state <= COMPUTING ;
                        Busy <= 1'b1 ;
                    end
                end
                COMPUTING: begin
                    if(~done) begin
                        n_state <= COMPUTING ;
                        Busy <= 1'b1 ;
                    end
                end        
            endcase    
    end


    always@( posedge CLK ) begin : STATE_UPDATE_PROCESS // state updating
        state <= n_state ;    
    end

    
    always@( posedge CLK ) begin : COMPUTING_PROCESS // process which does the actual computation
        // n_state == COMPUTING and state == IDLE implies we are just transitioning into COMPUTING
        if( RESET | (n_state == COMPUTING & state == IDLE) ) begin // 2nd condition is true during the very 1st clock cycle of the multiplication
            count = 0 ;
            temp_sum = 0 ;
            quotient = 0;
            
            shifted_op1 = { {width{~MCycleOp[0] & Operand1[width-1]}}, Operand1 } ; // sign extend the operands  
            shifted_op2 = { {width{~MCycleOp[0] & Operand2[width-1]}}, Operand2 } ; 
            
            if (~MCycleOp[0]) begin     // for signed mul/div
                // invert + 1 if negative
                if (Operand1[width-1] == 1) begin     
                    shifted_op1 = ~shifted_op1 + 1'b1;
                end
                if (Operand2[width-1] == 1) begin     
                    shifted_op2 = ~shifted_op2 + 1'b1;
                end
                if (Operand1[width-1] == ~Operand2[width-1]) begin
                    diff = 1;
                end
            end
            
            if (MCycleOp[1]) begin
                shifted_op2 = { shifted_op2[width - 1:0], {width{1'b0}} };
            end
           
            
        end ;
        done <= 1'b0 ;   
        
        if( ~MCycleOp[1] ) begin // Multiply
            // if( ~MCycleOp[0] ), takes 2*'width' cycles to execute, returns signed(Operand1)*signed(Operand2)
            // if( MCycleOp[0] ), takes 'width' cycles to execute, returns unsigned(Operand1)*unsigned(Operand2)        
            if( shifted_op2[0] ) // add only if b0 = 1
                temp_sum = temp_sum + shifted_op1 ; // partial product for multiplication
                
            shifted_op2 = {1'b0, shifted_op2[2*width-1 : 1]} ;
            shifted_op1 = {shifted_op1[2*width-2 : 0], 1'b0} ;    
                
            if( (MCycleOp[0] & count == width-1) | (~MCycleOp[0] & count == 2*width-1) ) // last cycle?
                done <= 1'b1 ;   
               
            count = count + 1;    
        end    
        
        else if (MCycleOp[1]) begin     // division.
            // shifted_op1 -- Dividend / Remainder
            // shifted_op2 -- Divisor
            
            shifted_op1 = shifted_op1 - shifted_op2;
            
            if (shifted_op1[2*width-1] == 0) begin     // shift Quotient left with LSB = 1
                quotient = {quotient[2:0], 1'b1};
            end
            else begin      // remainder < 0
                shifted_op1 = shifted_op1 + shifted_op2;     // add back the divisor
                quotient = {quotient[2:0], 1'b0};           // shift Quotient by left with LSB = 0
            end
              
            shifted_op2 = {1'b0, shifted_op2[2*width-1:1]};  // divisor shift right
            
            count = count + 1;
            
          
            if(count == width + 1) begin       // check for last cycle
                if (diff) begin
                    shifted_op1[3:0] = ~shifted_op1[3:0] + 1'b1;
                    quotient = ~quotient + 1'b1;
                    diff = 0;
                end
                
                temp_sum = {shifted_op1[3:0], quotient};   // remainder as MSW and quotient as LSW  
                
                done <= 1'b1;
            end
        
        end
        
        
        Result2 <= temp_sum[2*width-1 : width] ;
        Result1 <= temp_sum[width-1 : 0] ;
             
    end
   
endmodule

















