;----------------------------------------------------------------------------------
;--	License terms :
;--	You are free to use this code as long as you
;--		(i) DO NOT post it on any public repository;
;--		(ii) use it only for educational purposes;
;--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
;--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
;--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
;--		(vi) retain this notice in this file or any files derived from this.
;----------------------------------------------------------------------------------

	AREA    MYCODE, CODE, READONLY, ALIGN=9 ; 2^9 = 512 bytes (enough space for 128 words). Each section is aligned to an address divisible by 512.
   	  ENTRY
	  
; ------- <code memory (ROM mapped to Instruction Memory) begins>
; Total number of instructions should not exceed 127 (126 excluding the last line 'halt B halt').
		LDR R1, DIPS               ; R1 = address of DIPS (0x00000C04)
		LDR R2, PBS                ; R2 = address of PBS (0x00000C08)
		LDR R3, SEVENSEG           ; R3 = address of SEVENSEG (0x00000C18)
		LDR R4, MULTIPLY_AMOUNT    ; R4 = 0xCC = 0b1100_1100
		LDR R5, DIVIDE_AMOUNT      ; R5 = 0xBB = 0b1011_1011
		
main_loop
		LDR R6, [R1]		   ; R6 = DIPS, use this if manually flipping switches onboard
		;LDR R6, DIPS_SIMUL    ; use this to simulate DIPS (0x05DB = 0b0000_0101_1101_1011)
		LDR R7, [R2]           ; R7 = PBS, use this if manually pressing BTNC to toggle between MUL and MLA
		;LDR R7, BTNC_SIMUL    ; R7 = 0x2, use this to simulate BTNC being pressed
		LDR R8, ZERO           ; reset result seen on SEVENSEG
		
		CMP R7, #0x2           ; MUL -> R7 = 0x2 (BTNC pressed), MLA -> R7 = 0 (BTNC not pressed);
		BEQ multiplication_loop
		B division_loop
		
multiplication_loop
		MUL R8, R6, R4       ; R8 = R6*R4, should be 0x4AA84 if using DIPS_SIMUL
        STR R8, [R3]         ; display R8 on SEVENSEG		
		B main_loop
		
division_loop		         ; MLA Rd, Rm, Rs, Rn
							 ; MLA R8, R6, R5, R15
		MLA R8, R6, R5, R1   ; R8 = R6/R5, set Rn to be 4'd1 to differentiate it from MUL
						     ; 0x05DB / 0xBB = 8 R 3, where 8 (quotient) stored in R8
        STR R8, [R3]         ; display R8 on SEVENSEG
		B main_loop
		
halt	
		B    halt           ; infinite loop to halt computation. // A program should not "terminate" without an operating system to return control to
							; keep halt	B halt as the last line of your code.
; ------- <\code memory (ROM mapped to Instruction Memory) ends>


	AREA    CONSTANTS, DATA, READONLY, ALIGN=9 
; ------- <constant memory (ROM mapped to Data Memory) begins>
; All constants should be declared in this section. This section is read only (Only LDR, no STR).
; Total number of constants should not exceed 128 (124 excluding the 4 used for peripheral pointers).
; If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.

;Peripheral pointers
LEDS
		DCD 0x00000C00		; Address of LEDs. //volatile unsigned int * const LEDS = (unsigned int*)0x00000C00;  
DIPS
		DCD 0x00000C04		; Address of DIP switches. //volatile unsigned int * const DIPS = (unsigned int*)0x00000C04;
PBS
		DCD 0x00000C08		; Address of Push Buttons. Optionally used in Lab 2 and later
CONSOLE
		DCD 0x00000C0C		; Address of UART. Optionally used in Lab 2 and later
CONSOLE_IN_valid
		DCD 0x00000C10		; Address of UART. Optionally used in Lab 2 and later
CONSOLE_OUT_ready
		DCD 0x00000C14		; Address of UART. Optionally used in Lab 2 and later
SEVENSEG
		DCD 0x00000C18		; Address of 7-Segment LEDs. Optionally used in Lab 2 and later

; Rest of the constants should be declared below.
ZERO
		DCD 0x00000000		; constant 0
MULTIPLY_AMOUNT
        DCD 0xCC
DIVIDE_AMOUNT
		DCD 0xBB
DIPS_SIMUL
        DCD 0x000005DB
BTNC_SIMUL
		DCD 0x00000002
ONES
		DCD 0xF
LSB_MASK
		DCD 0x000000FF		; constant 0xFF
variable1_addr
		DCD variable1		; address of variable1. Required since we are avoiding pseudo-instructions // unsigned int * const variable1_addr = &variable1;
constant1
		DCD 0xABCD1234		; // const unsigned int constant1 = 0xABCD1234;
string1   
		DCB  "\r\nWelcome to CG3207..\r\n",0	; // unsigned char string1[] = "Hello World!"; // assembler will issue a warning if the string size is not a multiple of 4, but the warning is safe to ignore
stringptr
		DCD string1			;
		
; ------- <constant memory (ROM mapped to Data Memory) ends>	


	AREA   VARIABLES, DATA, READWRITE, ALIGN=9
; ------- <variable memory (RAM mapped to Data Memory) begins>
; All variables should be declared in this section. This section is read-write.
; Total number of variables should not exceed 128. 
; No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using STR before reading using LDR).

variable1
		DCD 0x00000000		;  // unsigned int variable1;
; ------- <variable memory (RAM mapped to Data Memory) ends>	

		END	
		
;const int*x ;         // x is a non-constant pointer to constant data
;int const*x ;         // x is a non-constant pointer to constant data 
;int*constx ;          // x is a constant pointer to non-constant data