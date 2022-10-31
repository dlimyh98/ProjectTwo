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
		LDR R4, ARITHMETIC_AMOUNT  ; R4 = 0x1 = 0b0000_0001
		LDR R5, OVERFLOW_AMOUNT    ; R5 = 0xFFFFFFFF
		LDR R8, LSB_MASK           ; R8 = 0x00FF (0b1111_1111)
		
main_loop
		MOV R5, #0xFFFFFFFF    ; reset OVERFLOW_AMOUNT
		LDR R6, [R1]		   ; R6 = DIPS, use this if manually flipping switches onboard
		;LDR R6, DIPS_SIMUL     ; use this to simulate DIPS (0x2 = 0b0000_0000_0000_0010)
		LDR R7, ZERO           ; reset result seen on SEVENSEG
		
		;MOV R0, R0            ; Load and Use Hazard (LDR R6, [R1] -> ADDS R7, R5, R6)
		
		ADDS R7, R5, R6         ; purposefully cause an UNSIGNED overflow (C flag set to 1), R7 should be 0x1 now			   
		;MOV R0, R0
		;MOV R0, R0
							   
		ADCS R7, R7, R4          ; R7 = R7 + R4 + C_Flag = 0x3, (C flag should be reset to 0)
		;MOV R0, R0
		;MOV R0, R0
		
		BICS R7, R7, R8, LSR #7  ; R7 = R7 & ~(R8 >> #7) = 0x2, (C flag should be set to 1, V flag should NOT be set together with it)
		MVNCSS R5, R8            ; R5 = ~R8 = 0xFF...F00 (N flag should be set to 1)
		MVNVS R5, R3             ; should not execute, since V flag not set
		;MOV R0, R0
		;MOV R0, R0
		
		ADD R7, R7, R5          ; R7 should be 0xFF...F02                                   
		LDR R5, EOR_MASK        ; R5 = 0xFF...F9.             D @ 16 , E @ 17.1 , M @ 17.2, WB @ 18
		;MOV R0, R0             ; Load and Use Hazard
		;MOV R0, R0

		EOR R7, R7, R5          ; R7 should be 0xFB			  D @ 17.1 - 17.2 ,	E @ 18 , M @ 19, WB @ 20	
		;MOV R0, R0
		;MOV R0, R0				; Data Forwarding Hazard

		RSB R7, R7, #0x000000FF ; R7 = 0xFF - 0xFB = 0x04
		;MOV R0, R0
		;MOV R0, R0
		
		TEQ R7, #00000004		; C flag is UNCHANGED, still 1
		RSC R7, R7, #0x000000FF ; R7 = 0xFF - 0x04 - ~(0x1) = 0xFB		(Since C_flag is 1)
		ADDS R7, R7, #00000001  ; R7 = 0xFC (C_flag changes to 0, since NO carryOut)
		;MOV R0, R0
		;MOV R0, R0
		
		TST R5, R7				; R5 & R7. C flag is UNAFFECTED since NO SHIFTING		
		SBC R7, R5, R7			; R7 = 0xFFFFFFF9 - 0xFC - ~(0x0) = 0xFFFF_FEFC (Since C_flag is 0)

		
		LDR R5, SEVENSEG		
		STR R5, [R3]				
		;MOV R0, R0		       ; Mem-Mem Copy, stall TWICE
		;MOV R0, R0
		
        
		STR R7, [R3]           ; display R7 on SEVENSEG 		
		

		B main_loop
		;MOV R0, R0            ; Control Hazard
		;MOV R0, R0
		MOV R0, R0
		MOV R0, R0
		
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
OVERFLOW_AMOUNT
		DCD 0xFFFFFFFF
ARITHMETIC_AMOUNT
		DCD 0x00000001
EOR_MASK
		DCD 0xFFFFFFF9
DIPS_SIMUL
        DCD 0x00000002
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