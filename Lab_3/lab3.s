; ECE-222 Lab ... Winter 2013 term
; Lab 3 sample code
                        THUMB             ; Thumb instruction set
                AREA          My_code, CODE, READONLY
                EXPORT        __MAIN
                        ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs
                        LDR               R10, =LED_BASE_ADR            ; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

                        MOV         R3, #0xB0000000         ; Turn off three LEDs on port 1  
                        STR         R3, [r10, #0x20]
                        MOV         R3, #0x0000007C
                        STR         R3, [R10, #0x40]  ; Turn off five LEDs on port 2
                        

                  
                        
                        ;BL               DISPLAY_NUM
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
                        ;MOV              R11, #0xABCD            ; Init the random number generator with a non-zero number
                        
                        
loop              BL                RandomNum
                        ;BL               COUNTER
                        
REFLEX                  PUSH        {R0-R12,LR}
                        BL                SCALED_VALUE
                        
                        MOV32       R2,#0
                        LDR               R4,=FIO2PIN
                        
                        BL                DELAY
                        
                        MOV               R3,#0x40
                        BL                DISPLAY_NUM
                        
                        MOV               R5,#0x28
POLL              SUBS        R5,#1
                        ADDEQ       R2,#1
                        MOVEQ       R5,#0x28
                        
                        LDR               R6,[R4]
                        LSR               R6,#10
                        MOV               R8, #0
                        BFI               R8, R6,#0,#1
                        
                        
                        
                        TEQ               R8,#0
                        BNE               POLL
                        MOV               R3,#0
                        BL                DISPLAY_NUM
                        
DISPLAY_COUNTER   MOV               R7,R2
DISPLAY_LOOP      AND               R3,R7,#0xFF
                        BL                DISPLAY_NUM
                        MOV               R0,#20000
                        BL                DELAY
                        LSR               R7,#8
                        CMP               R7,#0
                        BNE               DISPLAY_LOOP
                        MOV               R3,#0
                        MOV               R0,#50000
                        
                        BL                DISPLAY_NUM
                        BL                DELAY
                        B                 DISPLAY_COUNTER
                        
                        POP               {R0-R12,LR}
                        
                        B loop
                        
                        
                        

COUNTER                 PUSH        {R0-R12,LR}
                        MOV32             R3,#0 ; counter that counts from 0 to 255
                        
COUNTER_LOOP      
                        
                        BL                DISPLAY_NUM
                        MOV32       R1,#0x00020805

COUNTER_DELAY     
                        SUBS        R1,#1
                        BNE               COUNTER_DELAY
                        
                        ADD               R3,#1
                        CMP               R3,#256
                        BLT               COUNTER_LOOP
                        
                        
                        MOV               R3,#0
                        BL                DISPLAY_NUM
                        
                        
                        
                        POP               {R0-R12,LR}
                        BX                LR
                        

                        
                        
;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM       STMFD       R13!,{R1-R8, R14}

                        LDR               R1,= FIO1CLR
                        LDR               R2,= FIO2CLR
                        MOV               R8,#0xFFFFFFFF
                        STR               R8,[R1]
                        STR               R8,[R2]


                        LDR               R1,= FIO1SET
                        LDR               R2,= FIO2SET
                        
                        
                        MOV               R4,#0
                        MOV               R5,#0
                        MOV               R6,#0
                        MOV               R7,#0
                        
                        MOV               R6,R3
                        RBIT        R7,R6
                        LSR               R7,#24
                        BFI               R4,R7,#28,#2
                        LSR               R7,#2
                        BFI               R4,R7,#31,#1
                        LSR               R7,#1
                        BFI               R5,R7,#2,#5
                  
                        
                        
                        STR               R4,[R1]
                        STR               R5,[R2]
                        
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

                        LDMFD       R13!,{R1-R8, R15}
                        

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum         STMFD       R13!,{R1, R2, R3, R14}

                        AND               R1, R11, #0x8000
                        AND               R2, R11, #0x2000
                        LSL               R2, #2
                        EOR               R3, R1, R2
                        AND               R1, R11, #0x1000
                        LSL               R1, #3
                        EOR               R3, R3, R1
                        AND               R1, R11, #0x0400
                        LSL               R1, #5
                        EOR               R3, R3, R1        ; the new bit to go into the LSB is present
                        LSR               R3, #15
                        LSL               R11, #1
                        ORR               R11, R11, R3
                        
                        LDMFD       R13!,{R1, R2, R3, R15}

;
;           Delay 0.1ms (100us) * R0 times
;           aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.


DELAY             STMFD       R13!,{R1-R5, R14} ;Push R2, LR to stack
                        MOV               R1, #10000
                        MOV32       R3,#4000000 
                        MOV               R4,#3
                        
                        MOV               R2,R0
                        UDIV        R2,R1
                        
                        MUL               R2,R3
                        UDIV        R2,R4
                        
                        
DELAY_LOOP        SUBS        R2, #1
                  BNE               DELAY_LOOP
                        
            ; code to generate a delay of 0.1mS * R0 times
            ;
exitDelay         LDMFD       R13!,{R1-R5, R15} ;Pop R2, PC from stack

SCALED_VALUE      PUSH {R1,R2,LR}
                        MOV               R0,R11
                        MOV               R2,#9 ; Multiplicand, divisor
                        UDIV        R1,R0, R2
                        MUL               R1,R2
                        SUB               R0,R1
                        ADD               R0,#2
                        MOV               R2,#10000
                        MUL               R0,R2
                        
                        POP {R1,R2,LR}
                        BX                LR
                        

LED_BASE_ADR      EQU   0x2009c000        ; Base address of the memory that controls the LEDs
PINSEL3                 EQU   0x4002c00c        ; Address of Pin Select Register 3 for P1[31:16]
PINSEL4                 EQU   0x4002c010        ; Address of Pin Select Register 4 for P2[15:0]
FIO1SET                 EQU         0x2009C038
FIO2SET                 EQU         0x2009C058  
FIO1CLR                 EQU   0x2009C03C
FIO2CLR                 EQU   0x2009C05C
FIO2PIN                 EQU         0x2009C054
;     Usefull GPIO Registers
;     FIODIR  - register to set individual pins as input or output      
;     FIOPIN  - register to read and write pins
;     FIOSET  - register to set I/O pins to 1 by writing a 1
;     FIOCLR  - register to clr I/O pins to 0 by writing a 1

                        ALIGN

                        END
