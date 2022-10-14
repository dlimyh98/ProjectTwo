# DP Instructions #

## Lab 4 (w.r.t Lab 4's .asm code) ##
1. ADC - Add with Carry `ADCS R7, R4, R5`
      - confirmed that ADCS correctly updates Flags
3. BIC - Logical Bit Clear
4. EOR - Logical EOR
5. MOV
6. MVN
7. RSB
8. RSC
9. SBC
10. TEQ
11. TST

### POTENTIAL IMPROVEMENTS ###
1. Pipelining
2. support #imm8 with rotation
3. Shifter will affect C flag

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