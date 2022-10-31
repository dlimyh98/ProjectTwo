# DP Instructions #

## Lab 4 (w.r.t Lab 4's .asm code) ##
1. ADC - Add with Carry `ADCS R7, R4, R5`
2. BIC - Logical Bit Clear `BICS R7, R7, R8, LSR #7`
      - Src_B_comp is updated at end of always@(...) block, NOT end of clock cycle
3. EOR - Logical EOR `EOR R7, R7, R5`
4. MOV - Move `MOV R5, #0xFFFFFFFF`
5. MVN - Move Not `MVNCSS R5, R8`
6. RSB - Reverse Subtract `RSB R7, R7, #0x000000FF`
7. RSC - Reverse Subtract w/ Carry `RSC R7, R7, #0x000000FF`
8. SBC - Subtract w/ Carry `SBC R7, R5, R7`
9. TEQ - Test Equivalence `TEQ R7, #00000004`
10. TST - Test (same as ANDS) `TST R5, R7`

### IMPROVEMENTS IMPLEMENTED ###
1. Pipelining (Data Forwarding, Mem-Mem Copy, Load and Use, Control Hazard)
2. Shifter affects C flag
3. C flag and V flag set separately

## From Lab 2 (w.r.t Lab 2's .asm code) ##
### Memory
1. Memory with negative immediate offset               `LDR R1, [R4, #-8]`
2. Memory with positive immediate offset                 `STR R7, [R4, #8]`
3. Instructions where PC is Source                              `STR R15, PC_ADDRESS`
4. Instructions where PC is Destination                       `LDR R15, PC_ADDRESS`

### Data-Processing
1. DP where Src2 is immediate (without shift)  `ADD R4, R4, #8`
    - DP where Src2 is immediate (without shift) `ANDEQS R7, R7, #0x00F0`, _**checks AND sets flags**_ , _**shows that logical operations (AND/OR) do not affect C flag (excluding shift operations)**_,  **_NO SUPPORT FOR IMMEDIATE WITH ROTATED SHIFT IN LAB 2_**
    - DP where Src2 is immediate (without shift) `SUBS R5, R5, #1`,  _**sets flags**_
2. DP where Src2 is register (without shift) `ADDEQ R7, R7, R6`, _**checks flags**_
3. DP where Src2 is register (with immediate shift) `ADD R7, R7, R4, LSR #2`, _**shows that logical operations (AND/OR) do affect C flag (if shift operations and carried out bit is 0 or 1)**_

### CMP & CMN
1. CMP `CMP R5, #0`, **_verified that NoWrite flag working & results discarded_**
2. CMN `CMN R5, R8`, **_verified that NoWrite flag working & results discarded_**

### B
1. `BNE delay_loop`

### ALUOp_toSend
00 -> non-DP, positive offset (also Branch)  
01 -> non-DP, negative offset  
10 -> not defined  
11 -> DP, positive/negative offset
