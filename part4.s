/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */
SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

//CODE FROM PART 3
          .text                   // executable code follows
          .global _start  
_start:                             
          MOV     R3, #TEST_NUM   //load the data word into R3
		  MOV     R5, #0         //Initialize longest string of ones to zero 
		  MOV     R6, #0        //Initialize longest string of zeroes to zero
		  MOV     R7, #0       //Initialize longest string of alternating ones and zeros to zero 

LOOP:     LDR     R1, [R3]  
		  CMP     R1, #0      //If R1 is pointing to zeros, we have reached the end of the list, so end program
		  BEQ     DISPLAY        //Change this from END to DISPLAY? 
		  
		  MOV     R0, #0        //Reset R0
		  BL      ONES         //After ONES runs, R0 should hold the #of ones in that word
		  CMP     R0, R5      //R0-R5 
		  MOVGE   R5, R0     //If R0>R5, move that into R5
		 
		  MOV    R0, #0         //Reset R0 
		  LDR    R1, [R3]      //Re-Load original word pointed to by R3 into R1 
		  BL     ZEROS        //Call Zeros Subroutine 
		  CMP    R0, R6      //R0-R5
		  MOVGE  R6, R0     //If R6-R0<0, R6<-R0
		  
		  MOV    R0, #0 
		  LDR    R1, [R3]
		  BL     ALTERNATE 
		  CMP    R0, R7 
		  MOVGE  R7, R0 
		  
		  ADD     R3, #4 //Point to the next word on the list
		  B       LOOP
	 	   
ONES:     CMP     R1, #0           // loop until the data contains no more 1's
          BEQ     DONE             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1         // count the string length so far
          B       ONES 

ZEROS:     LDR     R8, =0xFFFFFFFF   //1111111
		   EOR     R1, R1, R8       //Flip the number so that the zeros become ones then call the ones algorithm 
	       PUSH    {LR}
		   BL      ONES            //R0 will hold the Number of zeros in that number 
		   POP     {LR}
		   MOV     pc, lr            

ALTERNATE: LDR     R9, =0x7FFFFFFF//011111
		   ROR     R2, R1,#1     //R2 <- R1 Rotated once
		   EOR     R1, R1, R2   //R1<- R1 EORED with R2
		   AND     R1, R1, R9  //This will make the first number of the thing we are passing in 0 (cutting off) 
		   PUSH    {lr}        
		   BL      ONES      //The above process will turn the segment of alternating ones and zeros into a segment of ones 
		   ADD     R0, #1   //Add one to the end to compensate for the one we cut off 
		   POP     {LR}
		   MOV     PC, LR 
		    
DONE: 	  MOV     PC, LR  

                      
END:      B       END  
//CODE FROM PART 3

//CODE FOR PART4
/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0

            MOV     R0, R5          // display R5 on HEX1-0  R0 <- R5
            BL      DIVIDE          // ones digit will be in R0 and tens digit in R1
			MOV     R9, R1          // Move the 10s digit into R9
			
            BL      SEG7_CODE       //Convert the ones digit stored in R0 into ones digit bit code
            MOV     R4, R0          //R4<- bit code(24 zeros, 8 bits ones digit) 
			
			MOV     R0, R9          //R0 now holds 10s digit 
            BL      SEG7_CODE       //Convert the 10s digit to bit code R0 <-(24 zeros, 8 bits 10s digit) 
            LSL     R0, #8          //R0 <- (16 zeros, 8 bits 10 digits, 8 zeros) 
			
            ORR     R4, R0		 	//R4 <- R4 + R0 (16 zeros, 8bits 10s digit, 8 bits ones digit) 
			
			
			//R4<- (8bitsR610sDigit, 8BitsR61sDigit, 8BitsR510sDigit, 8BitsR5OnesDigit)
            ...
			MOV      R0, R6      //Mov R6 into R0 
			BL       DIVIDE
			MOV      R9, R1      //Move the 10s digit into R9 
			
			BL       SEG7_CODE   //Convert the ones digit stored in R0 into ones digit bit code
			MOV      R10, R0     //R10<- Ones digit bit code (24 zeros, 8bits R6 ones digit)
			LSL      R10, #16    //R10<- (8 zeros, 8 bits R6 ones digit, 16 zeros) 
			
			MOV      R0, R9      //R0 Now holds the 10s digit 
			BL       SEG7_CODE   //R0<- 10s digit bit code (24 zeros, 8bitsR610'sDigit) 
			LSL      R0, #24     //R0<- (8bitsR610'sDigit, 24 zeros) 
			ORR      R10, R0     //R10<- (8bitsR610'sDigit, 8bitsR61'sDigit, 16 zeros) 
			
			ORR      R4, R10    //R4<-(8BitsR610'sDigit, 8BitsR61'sDigit, 8 bitsR510'sDigit, 8BitsR51'sDigit)
            
			STR      R4, [R8]   // display the numbers from R6 and R5
			
			//R7 Begins Here 
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4 (Where R7 will be displayed)
			MOV     R0, R7 
			BL      DIVIDE
			MOV     R9, R1 
			
			BL      SEG7_CODE
			MOV     R4, R0 
			
			MOV     R0, R9 
			BL      SEG7_CODE
			
			LSL     R0, #8
			ORR     R4, R0 
            STR     R4, [R8]        // display the number from R7
				
DIVIDE: 	MOV R2, #0

CONT: 		CMP R0, #10
	  		BLT DIV_END
	  		SUB R0, #10
	  		ADD R2, #1
	  		B CONT

DIV_END: 	MOV R1, R2 // quotient in R1 (remainder in R0)
		 	MOV PC, LR
TEST_NUM:
		  .word   0x103fe00f   //(has 9 ones, 9 zeros, 3 alternating)  
		  .word   0x800007D0   //(has 5 ones, 20 zeros, 4 alternating) 
		  .word   0x80018493   //(has 2 ones, 14 zeros, 3 alternating)
		  .word   0x71B36893   //(has 3 ones, 3 zeros, 4 alternating)
		  .word   0xB2D036E7   //(has 3 ones, 6 zeros, 4 alternating) 
		  .word   0x7FFFFFFF   //(has 31 ones, 1 zero, 2 alternating) 
		  .word   0x7A0A1F00   //(has 5 ones, 8 zeros, 5 alternating) 
		  .word   0x8BF3644C   //(has 6 ones, 4 zeros, 4 alternating) 
		  .word   0x8BF3647F   //(has 7 ones, 3 zeros, 4 alternating) 
		  .word   0x80000000   //(has 1 ones, 31 zeros, 2 alternating) 
		  .word   0x00000000   //(has zero ones, 32 zeros, 0 alternating) 
          .end                            
