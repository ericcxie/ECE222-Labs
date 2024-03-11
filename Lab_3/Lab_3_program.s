; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2
				
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				
loop 			;BL 			DISPLAY_NUM	;added for testing
				BL 			RandomNum 	;get random number into R11
				
				MOV			R0, R11
				BL			DELAY	;delay for random number of time
				
				; turns one LED on
				MOV32 		R12, #0x20000000	;moving value to turn on the 1.29 LED
				LDR			R5, =FIO1SET		;get the FIO1SET address (already done in Display number but don't think it will be called before
				STR			R12, [R5]
				
				MOV			R3, #0		; initialize counter (increment once every 0.1ms)
				

;start of polling INTO button				
poll			
				MOV 		R0, #1
				BL 			DELAY
				ADD			R3, #1
				LDR 		R1, =FIO2PIN	    ;get the push button address
				LDR			R1, [R1]
				LSR			R1, #10
				BFI			R2, R1, #0, #1		;might need to use other register than R1
				
				CMP			R2, #0
				BNE			poll
;end of polling INTO button


loop_display	MOV			R4, R3
				MOV			R1, #4
				
				
display
				;Test
				MOV 		R6, #0
				
				BFI			R6, R4, #0, #8
				LSR			R4, #8
				BL			DISPLAY_NUM
				MOV			R0, #20000		
				BL			DELAY
				
				SUBS		R1, #1
				;TEST
				TEQ			R1, #0
				BNE			display
				
				MOV			R0, #0
				MOV 		R0, #50000
				BL 			DELAY
				
				B			loop_display
				B			display
				
				
				
				
				
				
				

				B loop

;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD		R13!,{R1, R2, R4, R14}

; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

				;MOV			R6, #0x0		;counter
				LDR			R5, =FIO1SET
				LDR			R7, =FIO2SET

Counter			
				;End counter part 1
				
				LSR			R1, R6, #5			; get the last 3 bits of 8 bit input
				
				AND			R1, R1, #0x7		;last 3 bits of R6
				AND			R2, R6, #0x1F		;first 5 bits of R6
				
				MOV			R8, R1
				AND			R1, R1, #1      
				LSL 		R8, R8, #1
				BIC			R8, R8, #2
				ORR			R1, R1, R8
				
				RBIT		R1, R1
				RBIT		R2, R2
				;LSR			R2, #27
				
				;LSR			R1, R1, #4
				LSR			R2, R2, #25
				
				AND			R4, R2, #0x0000007C
				AND			R9, R1, #0xB0000000
				
				STR 		R4, [R7]
				STR			R9, [R5]
				
				EOR			R4, R2, #0x0000007C
				EOR			R9, R1, #0xB0000000
				
				STR			R4, [R7, #4]
				STR			R9, [R5, #4]
				
				
				
				;MOV			R0, #1000	;1000
				;BL			DELAY
				
				
				; Counter part 2
				;ADD 		R6, #1
				;CMP 		R6, #256
				;BNE			Counter
				B			exitCounter
				; Counter part 2
				
				
exitCounter
				LDMFD		R13!,{R1, R2, R4, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				;testing
				;MOV			R11, #1
				
				LDMFD		R13!,{R1, R2, R3, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.


;DELAY START
DELAY			STMFD		R13!,{R2, R14}
		;
		; code to generate a delay of 0.1mS * R0 times
		;
MultipleDelay	TEQ			R0, #0 ;test R0 to see if it's 0 - set zero flag so you can use BEQ, BNE
				MOV 		R10, #0x85    ;0x85 ;133
				
loop1
				SUBS		R10, #1
				BNE			loop1
				SUBS		R0, #1
				BEQ			exitDelay
				BNE			MultipleDelay

exitDelay		LDMFD		R13!,{R2, R15}
;DELAY END
				

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]

FIO1SET			EQU		0x2009C038		
FIO2SET			EQU		0x2009C058
	
FIO2PIN			EQU		0x2009C054		;address for push button
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 


; 1- If a 32-bit register is counting user reaction time in 0.1 milliseconds increments, what is the
; maximum amount of time which can be stored in 8 bits, 16-bits, 24-bits and 32-bits?

; 8 bits = (2^8 - 1) * 0.1 ms = 25.5 ms
; 16 bits -> 6553.5 ms
; 24 bits -> 1677721.5 ms
; 32 bits -> 429496729.5 ms

; 2- Considering typical human reaction time, which size would be the best for this task (8, 16,
; 24, or 32 bits)?

; According to Google, the typical human reaction time is around 250 milliseconds. 
; Therefore, 16 bits would be the best for this task since it can store up to 6553.5 ms whereas 8 bits can only store up to 25.5 ms.

; 3- Prove time delay meets 2 to 10 sec +/- 5% spec.

