`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2022 18:47:31
// Design Name: 
// Module Name: sim_Shifter
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


module sim_Shifter(
    );
    
    reg [1:0] Sh;
    reg [4:0] Shamt5;
    reg [31:0] ShIn;
    reg current_CFlag;
    wire [31:0] ShOut;
    wire Shifter_carryOut;
    
    Shifter dut(Sh, Shamt5, ShIn, current_CFlag, ShOut, Shifter_carryOut);
    
    initial begin
        /**************************** LSL ****************************/
        ShIn = 32'h0A55_0000;  // 32'b0000_1010_0101_0101_....
        Sh = 2'b00;
        Shamt5 = 5'd5;
        current_CFlag = 1'b0;
            // Shifter_carryOut should be 1
        
        #20;
        /**************************** LSR ****************************/
        ShIn = 32'h0000_0A55;  // 32'b..._0000_1010_0101_0101
        Sh = 2'b01;
        Shamt5 = 5'd4;
        current_CFlag = 1'b1;
            // Shifter_carryOut should be 0         
    end
    
endmodule