;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2013
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
                                EXPORT          EINT3_IRQHandler
				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
LOOP 			        BL 			RNG 
				;Random number scaling
				MOV			R6, R11
				MOV			R3, #21
				MOV			R4, #0
				UDIV		R4, R6, R3
				MUL			R4, R4, R3
				SUBS		R6, R6, R4
				ADD			R6, #5
				MOV			R1, #10
				MUL			R6, R6, R1
				MOV			R1, #0

				
FLASHING		
				LDR			R5, =FIO1SET
				LDR			R7, =FIO2SET
				
				MOV			R1, #0x0000007C
				MOV			R2, #0xB0000000
				
				STR			R1, [R7]		;turing on all LEDs
				STR 		R2, [R5]
				
				MOV			R0, #1			;calling for 0.1 sec of delay
				BL 			DELAY
				
				STR			R1, [R7, #4]	;adding #4 to FIO?SET will make it to FIO?CLR address
				STR			R2, [R5, #4]	;turing off all LEDs
				
				MOV			R0, #1
				BL			DELAY
				
				;Setting up for IRQ Handler
				MOV			R3, #0
				LDR			R3, =ISER0
				MOV 		R2, #0x00200000 	;enabling ISE_EINT3 by setting 21th bit to 1
				STR			R2, [R3]
				
				MOV 		R3, #0
				LDR			R3, =IO2IntEnf
				MOV			R2, #0x00000400	;enabling GPIO Interrupt by setting 10th bit to 1
				STR			R2, [R3]
				
				B			LOOP		
		;
		; Your main program can appear here 
		;
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
		;
		; Code to generate a delay of 100mS * R0 times
		;
MultipleDelay	TEQ			R0, #0 ;test R0 to see if it's 0 - set zero flag so you can use BEQ, BNE
				MOV32 		R10, #133333    ;0x85 ;133 133333
				
loop1
				SUBS		R10, #1
				BNE			loop1
				SUBS		R0, #1
				BEQ			exitDelay
				BNE			MultipleDelay
		
exitDelay		LDMFD		R13!,{R2, R15}


; Display Number

DISPLAY_NUM		STMFD		R13!, {R1, R2, R4, R14}
				
Counter			
				LSR			R1, R6, #5		;getting the last 3 bits of 8 bit input
				
				AND			R1, R1, #0x7	;last 3 bits of R6 input
				AND			R2, R6, #0x1F	;first 5 bits of R6
				
				MOV 		R8, R1			;copying the masked last 3 bits to R8
				AND			R1, R1, #1		;isolating first significant bit of R1
				LSL			R8, R8, #1		;shifting R8 left by 1 bit
				BIC			R8, R8, #2		;clearing bit 1 of R8
				ORR			R1, R1, R8		;or operation on R8 and R1. This will be needed for correctly spacing out 3 bits for fio1set input
				
				RBIT		R1, R1			;revresing the bit order of R1
				RBIT		R2, R2			; ''R2
				
				LSR			R2, R2, #25 	;shifting R2 right by 25 bits to get the significant bits to the front of R2
				
				AND 		R4, R2, #0x0000007C
				AND			R9, R1, #0xB0000000
				
				STR			R4, [R7]		;store R4 into FIO2SET address to turn on the LEDs that needed to be on
				STR 		R9, [R5]		;store R9 into FIO1SET ""
				
				EOR			R4, R2, #0x0000007C		;exclusive or on R2 to get the LEDs that needs to be off
				EOR			R9, R1, #0xB0000000		; ""
				
				STR			R4, [R7, #4]
				STR			R9, [R5, #4]
				
				B exitCounter
				
exitCounter		
				LDMFD		R13!, {R1, R2, R4, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
					STMFD 		R13!, {R1, R2, R4, R14}				; Use this command if you need it  

HANDLER		
					
					BL			DISPLAY_NUM
					SUBS		R6, #10
					
					BEQ			IF_ZERO		;Branch if Z flag is set (=0)
					BMI			IF_ZERO		;Branch if N flag is set (<0)
					
					MOV			R0, #10
					BL			DELAY
					
					B 			HANDLER
					
IF_ZERO				
					MOV 		R6, #0
					BL			DISPLAY_NUM
					LDR			R1, =IO2IntClr
					MOV			R2, #0x400
					STR			R2, [R1]
		
					LDMFD 		R13!, {R1, R2, R4, R14}				; Use this command if you used STMFD (otherwise use BX LR) 


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
IO2IntClr		EQU		0x400280AC		;
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 

				ALIGN 

				END 
