$NOLIST
;----------------------------------------------------
; math32.asm: Addition, subtraction, multiplication,
; and division of 32-bit integers. Also included are
; binary to bcd and bcd to binary conversion subroutines.
;
; 2011-2025 by Jesus Calvino-Fraga
; 2026 Edited by Gabriel L. (added tri32 and neg32)
;
;----------------------------------------------------

CSEG
;----------------------------------------------------
; depending on position of SW1, Either:
; a) (DOWN) Two sides of a triangle are given, and the hypotenuse is calculated, I assume A and B are the first and second operands respectively
;	C = sqrt(A^2+B^2)
; b) (UP) One side and the hypotenuse is given, and the missing side is calculated, I assume C and B are the first and second operands respecitvely
;	A = sqrt(C^2-B^2)
; if whoever is marking has an issue with that, simply swap tri_a and tri_b in the first loading step of tri32
; 
; Assume that all inputs are positive. if result is negative, display positive number and turn on LED0
; After calculation, any key from 0-9 should clear and display the new input value
;----------------------------------------------------
tri32: 
	push acc
    push psw
    push AR0
    push AR1
 
    mov tri_a+0, y+0	; Load tri_a from y (first operand, from copy_xy)
    mov tri_a+1, y+1
    mov tri_a+2, y+2
    mov tri_a+3, y+3
    mov tri_b+0, x+0	; Load tri_b from x (second operand, current input)
    mov tri_b+1, x+1
    mov tri_b+2, x+2
    mov tri_b+3, x+3
 
    mov x+0, tri_a+0	; move y into x and y then square such that x = tri_a^2
    mov x+1, tri_a+1
    mov x+2, tri_a+2
    mov x+3, tri_a+3
    mov y+0, tri_a+0
    mov y+1, tri_a+1
    mov y+2, tri_a+2
    mov y+3, tri_a+3
    lcall mul32
    jb mf, tri32_overflow
 
    mov tri_sq+0, x+0	; save tri_a^2 into tri_sq
    mov tri_sq+1, x+1
    mov tri_sq+2, x+2
    mov tri_sq+3, x+3
 
    mov x+0, tri_b+0	; load tri_b (second input) into x and y
    mov x+1, tri_b+1
    mov x+2, tri_b+2
    mov x+3, tri_b+3
    mov y+0, tri_b+0
    mov y+1, tri_b+1
    mov y+2, tri_b+2
    mov y+3, tri_b+3
    lcall mul32			; x = tri_b^2
    jb mf, tri32_overflow
    jb SWA.1, tri32_up	; check switch 1 state
	ljmp tri32_down ; jump over tri32_done to reach tri32_down

tri32_done:	; pop pushed registers and end operation. I put it here so I could be within -128/+127 of all calls
    pop AR1
    pop AR0
    pop psw
    pop acc
    ret
 
tri32_down: ; C = sqrt(A^2 + B^2)
    mov y+0, tri_sq+0	
    mov y+1, tri_sq+1
    mov y+2, tri_sq+2
    mov y+3, tri_sq+3
    lcall add32			; add tri_b^2 (stored in x) and tri_a^2 (stored in tri_sq then moved to y)
    jb mf, tri32_overflow
    ljmp tri32_sqrt		; send to sqrt solver
 
tri32_up:
    mov y+0, tri_sq+0
    mov y+1, tri_sq+1
    mov y+2, tri_sq+2
    mov y+3, tri_sq+3
    lcall x_gt_y  ; mf=1 if C^2 < B^2 (imaginary) to throw error
    jb mf, tri32_overflow ; throw an error if mf is up (imaginary answer)
	clr LEDRA.0
	lcall sub32 ; otherwise subtract then call the sqrt solver
	ljmp tri32_sqrt
 
tri32_overflow: ; if called, raise math flag and end operation
    setb mf
    ljmp tri32_done
 
tri32_sqrt: ; calculates square root
    mov a, x+0	; checks if x is 0
    orl a, x+1
    orl a, x+2
    orl a, x+3
    jnz tri32_sqrtStart ; calls the sqrt loop initiator
    clr mf
    ljmp tri32_done
 
tri32_sqrtStart:
    mov tri_sq+0, x+0	; Save radicand into tri_sq
    mov tri_sq+1, x+1
    mov tri_sq+2, x+2
    mov tri_sq+3, x+3
 
    mov y+0, x+0	; Initial guess y = radicand
    mov y+1, x+1
    mov y+2, x+2
    mov y+3, x+3
 
tri32_sqrtLoop: ; Babylonian/Heron's method using nextGuess = (guess + radicand/guess) / 2
    mov x+0, tri_sq+0	; x = radicand (tri_sq), y = current guess
    mov x+1, tri_sq+1	
    mov x+2, tri_sq+2
    mov x+3, tri_sq+3
    lcall div32	; divide by current guess
    lcall add32	; x = x + y
    clr c
    mov a, x+3	 ; set x = x / 2  (for next guess)
    rrc a
    mov x+3, a
    mov a, x+2
    rrc a
    mov x+2, a
    mov a, x+1
    rrc a
    mov x+1, a
    mov a, x+0
    rrc a
    mov x+0, a	; x = next guess
 
    lcall x_lt_y	; If next_guess < current_guess: update guess and iterate
    jb mf, tri32_sqrtNext	; if the next guess is somehow less than next guess, raise math flag
 
    mov x+0, y+0	; if next_guess >= current_guess then guesses have converged, return current guess (y)
    mov x+1, y+1
    mov x+2, y+2
    mov x+3, y+3
    clr mf
    ljmp tri32_done ; end looping
 
tri32_sqrtNext:	; Update current guess to next_guess
    mov y+0, x+0
    mov y+1, x+1
    mov y+2, x+2
    mov y+3, x+3
    ljmp tri32_sqrtLoop

;----------------------------------------------------
; Negate value x = -x
;----------------------------------------------------
neg32:
	mov a, x+0
	cpl a
	mov x+0, a
	mov a, x+1
	cpl a
	mov x+1, a
	mov a, x+2
	cpl a
	mov x+2, a
	mov a, x+3
	cpl a
	mov x+3, a
	clr c
	mov a, x+0
	add a, #1
	mov x+0, a
	mov a, x+1
	addc a, #0
	mov x+1, a
	mov a, x+2
	addc a, #0
	mov x+2, a
	mov a, x+3
	addc a, #0
	mov x+3, a
	ret

;----------------------------------------------------
; Converts the 32-bit hex number in 'x' to a 
; 10-digit packed BCD in 'bcd' using the
; double-dabble algorithm.
;---------------------------------------------------
hex2bcd:
	push acc
	push psw
	push AR0
	push AR1
	push AR2
	push x+3
	push x+2
	push x+1
	push x+0
	
	clr a
	mov bcd+0, a ; Initialize BCD to 00-00-00-00-00 
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a
	mov r2, #32  ; Loop counter.

hex2bcd_L0:
	; Shift binary left	
	mov a, x+3
	mov c, acc.7 ; This way x remains unchanged!
	mov r1, #4
	mov r0, #(x+0)
hex2bcd_L1:
	mov a, @r0
	rlc a
	mov @r0, a
	inc r0
	djnz r1, hex2bcd_L1
    
	; Perform bcd + bcd + carry using BCD arithmetic
	mov r1, #5
	mov r0, #(bcd+0)
hex2bcd_L2:   
	mov a, @r0
	addc a, @r0
	da a
	mov @r0, a
	inc r0
	djnz r1, hex2bcd_L2

	djnz r2, hex2bcd_L0
	
	pop x+0
	pop x+1
	pop x+2
	pop x+3
	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop acc
	ret

;------------------------------------------------
; bcd2hex:
; Converts the 10-digit packed BCD in 'bcd' to a 
; 32-bit hex number in 'x'
;------------------------------------------------
bcd2hex:
	push acc
	push psw
	push AR0
	push AR1
	push AR2
	push bcd+4
	push bcd+3
	push bcd+2
	push bcd+1
	push bcd+0

	mov r2, #32  ; We need 32 bits

bcd2hex_L0:
	mov r1, #5	           ; BCD byte count = 5
	clr c                  ; clear carry flag
	mov r0, #(bcd+4)       ; r0 points to most significant bcd digits
bcd2hex_L1:
	mov a, @r0             ; transfer bcd to accumulator
	rrc a                  ; rotate right
	push psw               ; save carry flag
	; BCD divide by two correction
	jnb acc.7, bcd2hex_L2  ; test bit 7
	add a, #(100h-30h)     ; bit 7 is set. Perform correction by subtracting 30h.
bcd2hex_L2:
	jnb acc.3, bcd2hex_L3  ; test bit 3            
	add a, #(100h-03h)     ; bit 3 is set. Perform correction by subtracting 03h.
bcd2hex_L3:
	mov @r0, a             ; store the result
	dec r0                 ; point to next pair of bcd digits
	pop psw                ; restore carry flag
	djnz r1, bcd2hex_L1    ; repeat for all bcd pairs

	; rotate binary result right
	mov r1, #4
	mov r0, #(x+3)
bcd2hex_L4:
	mov a, @r0
	rrc a
	mov @r0, a
	dec r0
	djnz r1, bcd2hex_L4
	
	djnz r2, bcd2hex_L0

	; If the bcd number is larger than 4294967295 make mf=1 to indicate an input error
	setb mf
	mov a, bcd+0
	jnz bcd2hex_L5
	clr mf
	
bcd2hex_L5:
	pop bcd+0
	pop bcd+1
	pop bcd+2
	pop bcd+3
	pop bcd+4
	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop acc

    ret

;------------------------------------------------
; x = x + y
;------------------------------------------------
add32:
	push acc
	push psw
	mov a, x+0
	add a, y+0
	mov x+0, a
	mov a, x+1
	addc a, y+1
	mov x+1, a
	mov a, x+2
	addc a, y+2
	mov x+2, a
	mov a, x+3
	addc a, y+3
	mov x+3, a
	mov mf, c
	pop psw
	pop acc
	ret

;------------------------------------------------
; x = x - y
;------------------------------------------------
sub32:
	push acc
	push psw
	clr c
	mov a, y+0
	subb a, x+0
	mov x+0, a
	mov a, y+1
	subb a, x+1
	mov x+1, a
	mov a, y+2
	subb a, x+2
	mov x+2, a
	mov a, y+3
	subb a, x+3
	mov x+3, a
	mov mf, c
	pop psw
	pop acc
	ret

;------------------------------------------------
; mf=1 if x < y
;------------------------------------------------
x_lt_y:
	push acc
	push psw
	clr c
	mov a, x+0
	subb a, y+0
	mov a, x+1
	subb a, y+1
	mov a, x+2
	subb a, y+2
	mov a, x+3
	subb a, y+3
	mov mf, c
	pop psw
	pop acc
	ret

;------------------------------------------------
; mf=1 if x > y
;------------------------------------------------
x_gt_y:
	push acc
	push psw
	clr c
	mov a, y+0
	subb a, x+0
	mov a, y+1
	subb a, x+1
	mov a, y+2
	subb a, x+2
	mov a, y+3
	subb a, x+3
	mov mf, c
	pop psw
	pop acc
	ret

;------------------------------------------------
; mf=1 if x = y
;------------------------------------------------
x_eq_y:
	push acc
	push psw
	clr mf
	clr c
	mov a, y+0
	subb a, x+0
	jnz x_eq_y_done
	mov a, y+1
	subb a, x+1
	jnz x_eq_y_done
	mov a, y+2
	subb a, x+2
	jnz x_eq_y_done
	mov a, y+3
	subb a, x+3
	jnz x_eq_y_done
	setb mf
x_eq_y_done:
	pop psw
	pop acc
	ret

;------------------------------------------------
; mf=1 if x >= y
;------------------------------------------------
x_gteq_y:
	lcall x_eq_y
	jb mf, x_gteq_y_done
	ljmp x_gt_y
x_gteq_y_done:
	ret

;------------------------------------------------
; mf=1 if x <= y
;------------------------------------------------
x_lteq_y:
	lcall x_eq_y
	jb mf, x_lteq_y_done
	ljmp x_lt_y
x_lteq_y_done:
	ret
	
;------------------------------------------------
; x = x * y
;------------------------------------------------
mul32:

	push acc
	push b
	push psw
	push AR0
	push AR1
	push AR2
	push AR3
	push AR4
	push AR5
		
	; R0 = x+0 * y+0
	; R1 = x+1 * y+0 + x+0 * y+1
	; R2 = x+2 * y+0 + x+1 * y+1 + x+0 * y+2
	; R3 = x+3 * y+0 + x+2 * y+1 + x+1 * y+2 + x+0 * y+3
	
	; Byte 0
	mov	a,x+0
	mov	b,y+0
	mul	ab		; x+0 * y+0
	mov	R0,a
	mov	R1,b
	
	; Byte 1
	mov	a,x+1
	mov	b,y+0
	mul	ab		; x+1 * y+0
	add	a,R1
	mov	R1,a
	clr	a
	addc a,b
	mov	R2,a
	
	mov	a,x+0
	mov	b,y+1
	mul	ab		; x+0 * y+1
	add	a,R1
	mov	R1,a
	mov	a,b
	addc a,R2
	mov	R2,a
	clr	a
	rlc	a
	mov	R3,a
	
	; Byte 2
	mov	a,x+2
	mov	b,y+0
	mul	ab		; x+2 * y+0
	add	a,R2
	mov	R2,a
	mov	a,b
	addc a,R3
	mov	R3,a
	
	mov	a,x+1
	mov	b,y+1
	mul	ab		; x+1 * y+1
	add	a,R2
	mov	R2,a
	mov	a,b
	addc a,R3
	mov	R3,a
	
	mov	a,x+0
	mov	b,y+2
	mul	ab		; x+0 * y+2
	add	a,R2
	mov	R2,a
	mov	a,b
	addc a,R3
	mov	R3,a
	
	; Byte 3
	mov	a,x+3
	mov	b,y+0
	mul	ab		; x+3 * y+0
	add	a,R3
	mov	R3,a
	mov R4,b
	mov R5,#0
	
	mov	a,x+2
	mov	b,y+1
	mul	ab		; x+2 * y+1
	add	a,R3
	mov	R3,a
	mov a,b
	addc a,R4
	mov R4,a
	clr a
	addc a,R5
	mov R5,a
	
	mov	a,x+1
	mov	b,y+2
	mul	ab		; x+1 * y+2
	add	a,R3
	mov	R3,a
	mov a,b
	addc a,R4
	mov R4,a
	clr a
	addc a,R5
	mov R5,a
	
	mov	a,x+0
	mov	b,y+3
	mul	ab		; x+0 * y+3
	add	a,R3
	mov	R3,a
	mov a,b
	addc a,R4
	mov R4,a
	clr a
	addc a,R5
	mov R5,a
	
	; See if there is overflow
	mov a, R4
	orl a, R5
	mov R4, a
	
	mov a, x+3
	mov b, y+1
	mul ab
	orl a, b
	orl a, R4
	mov R4, a

	mov a, x+2
	mov b, y+2
	mul ab
	orl a, b
	orl a, R4
	mov R4, a
	
	mov a, x+1
	mov b, y+3
	mul ab
	orl a, b
	orl a, R4
	mov R4, a

	mov a, x+3
	mov b, y+2
	mul ab
	orl a, b
	orl a, R4
	mov R4, a
	
	mov a, x+2
	mov b, y+3
	mul ab
	orl a, b
	orl a, R4
	mov R4, a

	mov a, x+3
	mov b, y+3
	mul ab
	orl a, b
	orl a, R4
	mov R4, a

	mov	x+3,R3
	mov	x+2,R2
	mov	x+1,R1
	mov	x+0,R0
	
	setb mf
	cjne R4, #0, mul32_done
	clr mf
	
mul32_done:
	pop AR5
	pop AR4
	pop AR3
	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop b
	pop acc
	
	ret

;------------------------------------------------
; x = x / y
; This subroutine uses the 'paper-and-pencil' 
; method described in page 139 of 'Using the
; MCS-51 microcontroller' by Han-Way Huang.
;------------------------------------------------
div32:
	push acc
	push psw
	push AR0
	push AR1
	push AR2
	push AR3
	push AR4
	
	mov a, y+0
	orl a, y+1
	orl a, y+2
	orl a, y+3
	jnz div32_L0
	setb mf
	ljmp div32_exit	
	
div32_L0:
	clr mf
	mov	R4,#32
	clr	a
	mov	R0,a
	mov	R1,a
	mov	R2,a
	mov	R3,a
	
div32_loop:
	; Shift the 64-bit of [[R3..R0], x] left:
	clr c
	; First shift x:
	mov	a,x+0
	rlc a
	mov	x+0,a
	mov	a,x+1
	rlc	a
	mov	x+1,a
	mov	a,x+2
	rlc	a
	mov	x+2,a
	mov	a,x+3
	rlc	a
	mov	x+3,a
	; Then shift [R3..R0]:
	mov	a,R0
	rlc	a 
	mov	R0,a
	mov	a,R1
	rlc	a
	mov	R1,a
	mov	a,R2
	rlc	a
	mov	R2,a
	mov	a,R3
	rlc	a
	mov	R3,a
	
	; [R3..R0] - y
	clr c	     
	mov	a,R0
	subb a,y+0
	mov	a,R1
	subb a,y+1
	mov	a,R2
	subb a,y+2
	mov	a,R3
	subb a,y+3
	
	jc	div32_minus		; temp >= y?
	
	; -> yes;  [R3..R0] -= y;
	; clr c ; carry is always zero here because of the jc above!
	mov	a,R0
	subb a,y+0 
	mov	R0,a
	mov	a,R1
	subb a,y+1
	mov	R1,a
	mov	a,R2
	subb a,y+2
	mov	R2,a
	mov	a,R3
	subb a,y+3
	mov	R3,a
	
	; Set the least significant bit of x to 1
	orl	x+0,#1
	
div32_minus:
	djnz R4, div32_loop	; -> no
	
div32_exit:

	pop AR4
	pop AR3
	pop AR2
	pop AR1
	pop AR0
	pop psw
	pop acc
	
	ret

; Copy x to y	
copy_xy:
	mov y+0, x+0
	mov y+1, x+1
	mov y+2, x+2
	mov y+3, x+3
	ret

; Exchange x and y 
xchg_xy:
	mov a, x+0
	xch a, y+0
	mov x+0, a
	mov a, x+1
	xch a, y+1
	mov x+1, a
	mov a, x+2
	xch a, y+2
	mov x+2, a
	mov a, x+3
	xch a, y+3
	mov x+3, a
	ret

Load_X MAC
	mov x+0, #low (%0 % 0x10000) 
	mov x+1, #high(%0 % 0x10000) 
	mov x+2, #low (%0 / 0x10000) 
	mov x+3, #high(%0 / 0x10000) 
ENDMAC

Load_y MAC
	mov y+0, #low (%0 % 0x10000) 
	mov y+1, #high(%0 % 0x10000) 
	mov y+2, #low (%0 / 0x10000) 
	mov y+3, #high(%0 / 0x10000) 
ENDMAC
	
$LIST