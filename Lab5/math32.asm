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
; a) (DOWN) Two sides of a triangle are given, and the hypotenus is calculated
;	C = sqrt(A^2+B^2)
; b) (UP) One side and the hypotenus is given, and the missing side is calculated
;	A = sqrt(C^2-B^2)
; 
; Assume that all inputs are positive. if result is negative, display positive number and turn on LED0
; After calculation, any key from 0-9 should clear and display the new input value
;----------------------------------------------------
tri32:
	push acc
    push psw
    push AR0
    push AR1
    push AR2
    push AR3
    push AR4
    push AR5
    push AR6
    push AR7
    clr LEDRA.0
    mov tri_a+0, x+0
    mov tri_a+1, x+1
    mov tri_a+2, x+2
    mov tri_a+3, x+3
    mov tri_b+0, y+0
    mov tri_b+1, y+1
    mov tri_b+2, y+2
    mov tri_b+3, y+3
    lcall copy_xy ; y = x
    lcall mul32 ; y = x*y = x^2
    jb mf, tri32_overflow ; check if the square is too big
    mov tri_a+0, x+0 ; store output into "tri_a"
    mov tri_a+1, x+1
    mov tri_a+2, x+2
    mov tri_a+3, x+3
    mov x+0, tri_b+0
    mov x+1, tri_b+1
    mov x+2, tri_b+2
    mov x+3, tri_b+3
    lcall copy_xy ; copy y into x
    lcall mul32 ; square
    jb mf, tri32_overflow ; check if square overflows
    mov tri_b+0, x+0 ; store output into "tri_b"
    mov tri_b+1, x+1
    mov tri_b+2, x+2
    mov tri_b+3, x+3
    jnb SWA.1, tri32_down
    sjmp tri32_up
tri32_overflow:
    setb mf
    ljmp tri32_done
tri32_up: ; for A = sqrt(C^2-B^2), computes C^2-B^2 and hands off to tri32_sqrt
    mov x+0, tri_a+0
    mov x+1, tri_a+1
    mov x+2, tri_a+2
    mov x+3, tri_a+3
    mov y+0, tri_b+0
    mov y+1, tri_b+1
    mov y+2, tri_b+2
    mov y+3, tri_b+3
    
    lcall x_gteq_y
    jb mf, tri32_sub ; result is positive
    setb LEDRA.0
    mov x+0, tri_b+0
    mov x+1, tri_b+1
    mov x+2, tri_b+2
    mov x+3, tri_b+3
    mov y+0, tri_a+0
    mov y+1, tri_a+1
    mov y+2, tri_a+2
    mov y+3, tri_a+3
tri32_sub:
    lcall sub32
    sjmp tri32_sqrt
tri32_down: ; C = sqrt(A^2+B^2), computes A^2+B^2 and hands off to tri32_sqrt
    mov x+0, tri_a+0
    mov x+1, tri_a+1
    mov x+2, tri_a+2
    mov x+3, tri_a+3
    mov y+0, tri_b+0
    mov y+1, tri_b+1
    mov y+2, tri_b+2
    mov y+3, tri_b+3
    lcall add32
    jb mf, tri32_overflow
tri32_sqrt:
    mov tri_sq+0, x+0
    mov tri_sq+1, x+1
    mov tri_sq+2, x+2
    mov tri_sq+3, x+3
    mov tri_a+0, #0
    mov tri_a+1, #0
    mov tri_a+2, #0
    mov tri_a+3, #0
    mov r6, #16
    mov r5, #0x80
    mov r4, #0x00
tri32_sqrtLoop: ; iterates through current candidate stored in tri_a
    mov x+0, tri_a+0
    mov x+1, tri_a+1
    mov x+2, tri_a+2
    mov x+3, tri_a+3
    mov a, r4 ; x candidate
    orl a, x+0
    mov x+0, a
    mov a, r5
    orl a, x+1
    mov x+1, a
    lcall copy_xy ; move candidate into y
    lcall mul32 ; square to see if overflows
    jb mf, tri32_sqrtNext ; if too big, skip
    mov y+0, tri_sq+0
    mov y+1, tri_sq+1
    mov y+2, tri_sq+2
    mov y+3, tri_sq+3
    lcall x_lteq_y
    jnb mf, tri32_sqrtNext
    mov a, r4
    orl a, tri_a+0
    mov tri_a+0, a
    mov a, r5
    orl a, tri_a+1
    mov tri_a+1, a
tri32_sqrtNext:
    clr c
    mov a, r5
    rrc a
    mov r5, a
    mov a, r4
    rrc a
    mov r4, a
    djnz r6, tri32_sqrtLoop
    mov x+0, tri_a+0
    mov x+1, tri_a+1
    mov x+2, tri_a+2
    mov x+3, tri_a+3
    clr mf
    sjmp tri32_done
tri32_done:
    pop AR7
    pop AR6
    pop AR5
    pop AR4
    pop AR3
    pop AR2
    pop AR1
    pop AR0
    pop psw
    pop acc
	ret

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