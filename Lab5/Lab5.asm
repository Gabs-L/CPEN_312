$MODDE0CV

	CSEG at 0
	ljmp main_code

	dseg at 30h
	x: ds 4 ; 32-bits for variable ‘x’
	y: ds 4 ; 32-bits for variable ‘y’
	og: ds 4 ; for sqrt
	g1: ds 4 ; for sqrt
	g2: ds 4 ; for sqrt
	bcd: ds 5 ; 10-digit packed BCD (each byte stores 2 digits)
	bseg
	mf: dbit 1 ; Math functions flag
	newInput: dbit 1 ; New input fag
	
	$include(math32.asm)

	CSEG

; Look-up table for 7-seg displays
myLUT:
    DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99        ; 0 TO 4
    DB 0x92, 0x82, 0xF8, 0x80, 0x90        ; 4 TO 9
    DB 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E  ; A to F

showBCD MAC
	; Display LSD
    mov A, %0
    anl a, #0fh
    movc A, @A+dptr
    mov %1, A
	; Display MSD
    mov A, %0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov %2, A
ENDMAC

Display:
	mov dptr, #myLUT
	
	$MESSAGE TIP: If digits 10, 9, 8, and 7 are not zero, LEDR7: on
	
	mov a, bcd+3
	orl a, bcd+4
	jz Display_L1
	setb LEDRA.7 ; Non-zero digits alert
	sjmp Display_L2
Display_L1:
	clr LEDRA.7
Display_L2:

	$MESSAGE TIP: Pressing KEY3, displays the most significant digits of the 10-digit number
	
	jnb key.3, Display_high_digits
	showBCD(bcd+0, HEX0, HEX1)
	showBCD(bcd+1, HEX2, HEX3)
	showBCD(bcd+2, HEX4, HEX5)
	sjmp Display_end

Display_high_digits:
	showBCD(bcd+3, HEX0, HEX1)
	showBCD(bcd+4, HEX2, HEX3)
	mov HEX4, #0xff	
	mov HEX5, #0xff	
	
Display_end:
    ret

MYRLC MAC
	mov a, %0
	rlc a
	mov %0, a
ENDMAC

Shift_Digits_Left:
	mov R0, #4 ; shift left four bits
Shift_Digits_Left_L0:
	clr c
	MYRLC(bcd+0)
	MYRLC(bcd+1)
	MYRLC(bcd+2)
	MYRLC(bcd+3)
	MYRLC(bcd+4)
	djnz R0, Shift_Digits_Left_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	ret
	
MYRRC MAC
	mov a, %0
	rrc a
	mov %0, a
ENDMAC

Shift_Digits_Right:
	mov R0, #4 ; shift right four bits
Shift_Digits_Right_L0:
	clr c
	MYRRC(bcd+4)
	MYRRC(bcd+3)
	MYRRC(bcd+2)
	MYRRC(bcd+1)
	MYRRC(bcd+0)
	djnz R0, Shift_Digits_Right_L0
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

CHECK_COLUMN MAC
	jb %0, CHECK_COL_%M
	mov R7, %1
	jnb %0, $ ; wait for key release
	setb c
	ret
CHECK_COL_%M:
ENDMAC

Configure_Keypad_Pins:
	; Configure the row pins as output and the column pins as inputs
	orl P1MOD, #0b_01010100 ; P1.6, P1.4, P1.2 output
	orl P2MOD, #0b_00000001 ; P2.0 output
	anl P2MOD, #0b_10101011 ; P2.6, P2.4, P2.2 input
	anl P3MOD, #0b_11111110 ; P3.0 input
	ret

; These are the pins used for the keypad in this program:
ROW1 EQU P1.2
ROW2 EQU P1.4
ROW3 EQU P1.6
ROw4 EQU P2.0
COL1 EQU P2.2
COL2 EQU P2.4
COL3 EQU P2.6
COL4 EQU P3.0

; This subroutine scans a 4x4 keypad.  If a key is pressed sets the carry
; to one and returns the key code in register R7.
; It works with both a default keypad or a modified keypad with the labels
; rotated 90 deg ccw.  The type of keypad is determined by SW0, which is bit SWA.0
Keypad:
	; First check the backspace/correction pushbutton.  We use KEY1 for this function.
	$MESSAGE TIP: KEY1 is the erase key
	jb KEY.1, keypad_L0
	lcall Wait50ms ; debounce
	jb KEY.1, keypad_L0
	jnb KEY.1, $ ; The key was pressed, wait for release
	lcall Shift_Digits_Right
	clr c
	ret
	
keypad_L0:
	; Make all the rows zero.  If any column is zero then a key is pressed.
	clr ROW1
	clr ROW2
	clr ROW3
	clr ROW4
	mov c, COL1
	anl c, COL2
	anl c, COL3
	anl c, COL4
	jnc Keypad_Debounce
	clr c
	ret
		
Keypad_Debounce:
	; A key maybe pressed.  Wait and check again to discard bounces.
	lcall Wait50ms ; debounce
	mov c, COL1
	anl c, COL2
	anl c, COL3
	anl c, COL4
	jnc Keypad_Key_Code
	clr c
	ret
	
Keypad_Key_Code:	
	; A key is pressed.  Find out which one by checking each possible column and row combination.

	setb ROW1
	setb ROW2
	setb ROW3
	setb ROW4
	
	$MESSAGE TIP: SW0 is used to control the layout of the keypad. SW0=0: unmodified keypad. SW0=1: keypad rotated 90 deg CCW

	jnb SWA.0, keypad_default
	ljmp keypad_90deg
	
	; This check section is for an un-modified keypad
keypad_default:	
	; Check row 1	
	clr ROW1
	CHECK_COLUMN(COL1, #01H)
	CHECK_COLUMN(COL2, #02H)
	CHECK_COLUMN(COL3, #03H)
	CHECK_COLUMN(COL4, #0AH)
	setb ROW1

	; Check row 2	
	clr ROW2
	CHECK_COLUMN(COL1, #04H)
	CHECK_COLUMN(COL2, #05H)
	CHECK_COLUMN(COL3, #06H)
	CHECK_COLUMN(COL4, #0BH)
	setb ROW2

	; Check row 3	
	clr ROW3
	CHECK_COLUMN(COL1, #07H)
	CHECK_COLUMN(COL2, #08H)
	CHECK_COLUMN(COL3, #09H)
	CHECK_COLUMN(COL4, #0CH)
	setb ROW3

	; Check row 4	
	clr ROW4
	CHECK_COLUMN(COL1, #0EH)
	CHECK_COLUMN(COL2, #00H)
	CHECK_COLUMN(COL3, #0FH)
	CHECK_COLUMN(COL4, #0DH)
	setb ROW4

	clr c
	ret
	
	; This check section is for a keypad with the labels rotated 90 deg ccw
keypad_90deg:
	; Check row 1	
	clr ROW1
	CHECK_COLUMN(COL1, #0AH)
	CHECK_COLUMN(COL2, #0BH)
	CHECK_COLUMN(COL3, #0CH)
	CHECK_COLUMN(COL4, #0DH)
	setb ROW1

	; Check row 2	
	clr ROW2
	CHECK_COLUMN(COL1, #03H)
	CHECK_COLUMN(COL2, #06H)
	CHECK_COLUMN(COL3, #09H)
	CHECK_COLUMN(COL4, #0FH)
	setb ROW2

	; Check row 3	
	clr ROW3
	CHECK_COLUMN(COL1, #02H)
	CHECK_COLUMN(COL2, #05H)
	CHECK_COLUMN(COL3, #08H)
	CHECK_COLUMN(COL4, #00H)
	setb ROW3

	; Check row 4	
	clr ROW4
	CHECK_COLUMN(COL1, #01H)
	CHECK_COLUMN(COL2, #04H)
	CHECK_COLUMN(COL3, #07H)
	CHECK_COLUMN(COL4, #0EH)
	setb ROW4

	clr c
	ret
	
main_code:
	mov SP, #07FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a
	E equ 00000110B
	r equ 00101111B
	o equ 00100011B
	clrDisp equ 0FFH
	clr newInput
	lcall Configure_Keypad_Pins
	Load_X(0)
	Load_Y(0)

forever:
	lcall Keypad
	lcall Display
	jnc forever
	; If the carry is set we got a hex number in R7 from 0 to F. 0 to 9 are digits. A to F are calculator operations (+, -, sqrt, /, *, =).
	mov a, #9
	clr c
	subb a, R7
	jc Is_Operation
	
	jb newInput, newDigit
	
	lcall Shift_Digits_Left
	lcall bcd2hex       ; Check for overflow
    jb mf, tooBig       ; Jump if > 32 bits
    lcall hex2bcd 
	ljmp forever
	
	newDigit:
		clr newInput
	    clr LEDRA.0
	    Load_X(0)           ; Clear X register
	    mov bcd+0, R7       ; Store the new digit directly
	    mov bcd+1, #0       ; Clear other digits
	    mov bcd+2, #0
	    mov bcd+3, #0
	    mov bcd+4, #0
	    
	    lcall bcd2hex
	    jb mf, tooBig
	    lcall bcd2hex
	    lcall Display
	    ljmp forever
	    
	tooBig:
		ljmp error
	
	Is_Operation:
		Check_add_key:
			cjne R7, #0AH, Check_sub_key
			mov b, #0 ; b=0:addition, b=1:subtraction, etc.
			lcall bcd2hex ; Convert input in BCD to hex in x
			lcall copy_xy ; Copy x to y
			Load_X(0) ; Clear x (this is a macro)
			lcall hex2bcd ; Convert result in x to BCD
			lcall Display ; Display the new BCD number: ‘0000000000’
			ljmp forever ; Go check for more input

		Check_sub_key:
			cjne R7, #0BH, Check_root_key
			mov b, #1
			lcall bcd2hex ; Convert input in BCD to hex in x
			lcall copy_xy ; Copy x to y
			Load_X(0) ; Clear x (this is a macro)
			lcall hex2bcd ; Convert result in x to BCD
			lcall Display ; Display the new BCD number: ‘0000000000’
			ljmp forever ; Go check for more input
				
	;======================================================
	
		Check_div_key_sqrt:
			lcall Check_div_key
		
		Check_root_key:
			cjne R7, #0CH, Check_div_key_sqrt  ; Only proceed if 'C' pressed
    		setb newInput
    		
    		;Main calculation loop (8 iterations max for stability)
    		mov R6, #4
   
   			mov og+0, x+0
		    mov og+1, x+1
		    mov og+2, x+2
		    mov og+3, x+3

    		; Initial guess = x/2 + 1
    		Load_Y(2)
			lcall div32
			Load_Y(1)
			lcall add32
    		
    		; lcall display_sqrt_result
    		
    		sqrt_loop:
    			mov g1+0, x+0
			    mov g1+1, x+1
			    mov g1+2, x+2
			    mov g1+3, x+3
			    
			    mov y+0, og+0
			    mov y+1, og+1
			    mov y+2, og+2
			    mov y+3, og+3
			    
			    lcall xchg_xy
			    lcall div32
			    
			    mov y+0, g1+0
			    mov y+1, g1+1
			    mov y+2, g1+2
			    mov y+3, g1+3
			    
			    lcall add32
			    Load_Y(2)
			    lcall div32
			    
			    mov g2+0, x+0
			    mov g2+1, x+1
			    mov g2+2, x+2
			    mov g2+3, x+3
			    
			    ;lcall display_sqrt_result
			    
			    mov x+0, g1+0
			    mov x+1, g1+1
			    mov x+2, g1+2
			    mov x+3, g1+3
			    mov y+0, g2+0
			    mov y+1, g2+1
			    mov y+2, g2+2
			    mov y+3, g2+3
			    
			    ;lcall sub32
			    ;Load_Y(1)
			    ;lcall x_lteq_y
			    ;jb mf, display_sqrt_result
			    
			    mov x+0, g2+0
			    mov x+1, g2+1
			    mov x+2, g2+2
			    mov x+3, g2+3
			    
			    ;lcall display_sqrt_result
			    
			    djnz r6, sqrtLoop
    			
		display_sqrt_result:
		    ; Final result is in x
			lcall hex2bcd
			lcall Display
			ljmp forever
			
		sqrtLoop:
			ljmp sqrt_loop
    
    ;======================================================
			
		Check_div_key:
			cjne R7, #0DH, Check_mul_key
			mov b, #3
			lcall bcd2hex
			lcall copy_xy
			Load_X(0)
			lcall hex2bcd
			lcall Display
			ljmp forever
			
		Check_mul_key:
			cjne R7, #0EH, Check_equ_key
			mov b, #4
			lcall bcd2hex
			lcall copy_xy
			Load_X(0)
			lcall hex2bcd
			lcall Display
			ljmp forever
			
		Check_equ_key:
			cjne R7, #0FH, No_more_keys
			mov a, b
			setb newInput
			
		Check_add_operation:
			cjne a, #0, Check_sub_operation
			lcall bcd2hex
			lcall add32
			jb mf, error ; check flag, if 1, then run error
			lcall hex2bcd
			lcall Display
			clr LEDRA.0
		
		Check_sub_operation:
			cjne a, #1, Check_root_operation
			lcall bcd2hex
			lcall x_lteq_y ; check if x is leq y
			jb mf, posVal
		
			lcall sub32
			lcall hex2bcd
			lcall Display
			setb LEDRA.0
			ljmp forever
			
			posVal:
				lcall xchg_xy
				lcall sub32
				lcall hex2bcd
				lcall Display
				clr LEDRA.0
				ljmp forever
		
		Check_root_operation:
			cjne a, #2, Check_div_operation
			lcall Display
			ljmp forever
		
		Check_div_operation:
			cjne a, #3, Check_mul_operation
			call bcd2hex
			lcall xchg_xy
			lcall div32
			jb mf, error
			lcall hex2bcd
			lcall Display
			ljmp forever
			
		Check_mul_operation:
			cjne a, #4, Check_equ_operation
			call bcd2hex
			lcall mul32
			jb mf, error
			lcall hex2bcd
			lcall Display
			ljmp forever
			
		Check_equ_operation:
			mov a, b
		
		No_more_keys:
			ljmp forever
			
		error:
			mov HEX5, #clrDisp
			mov HEX4, #E
			mov HEX3, #r
			mov HEX2, #r
			mov HEX1, #o
			mov HEX0, #r
			ljmp sysPause
		
		sysPause:
			lcall KeyPad
			jnc sysPause
			mov bcd+0, #0
		    mov bcd+1, #0
		    mov bcd+2, #0
		    mov bcd+3, #0
		    mov bcd+4, #0
		    Load_X(0)           ; Clear X register
		    Load_Y(0)           ; Clear Y register
		    clr newInput        ; Reset input flag
		    clr mf              ; Clear math flag
		    lcall Display 
			ljmp Is_Operation			
end
