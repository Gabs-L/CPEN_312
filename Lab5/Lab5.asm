$MODDE0CV
CSEG at 0H
ljmp mainCode
DSEG at 30H

x: ds 4
y: ds 4
bcd: ds 5
tri_a: ds 4
tri_b: ds 4
tri_sq: ds 4
opCode: ds 1

BSEG
newInput: dbit 1
negFlag: dbit 1
mf: dbit 1
$include(math32.asm)
$include(readKeypad.asm)

CSEG
isADD EQU 0
isSUB EQU 1
isMUL EQU 2
isDIV EQU 3
isTRI EQU 4

E EQU 00000110B ; E
r EQU 00101111B ; r
o EQU 00100011B ; o
blank EQU 0FFH ; blank

mainCode:
	mov SP, #07FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a
	clr newInput
	clr negFlag
	mov opCode, #isADD
	lcall Configure_Keypad_pins
	Load_X(0)
	Load_Y(0)

forever:
	lcall Keypad
	lcall Display
	jnc forever
	mov a, #9
	clr c
	subb a, r7
	jc isOperation

	jb newInput, newDigit
	lcall Shift_Digits_Left
	lcall bcd2hex
	ljmp forever

newDigit:
	clr newInput
	clr negFlag
	clr LEDRA.0
	Load_X(0)
	mov bcd+0, r7
	mov bcd+1, #0
	mov bcd+2, #0
	mov bcd+3, #0
	mov bcd+4, #0
	lcall bcd2hex
	jb mf, tooBig
	lcall hex2bcd
	lcall Display
	ljmp forever

tooBig:
	ljmp error

isOperation:
	check_ADD:
		cjne r7, #0AH, check_SUB
		mov opCode, #isADD
		ljmp storeOp
	
	check_SUB:
		cjne r7, #0BH, check_MUL
		mov opCode, #isSUB
		ljmp storeOp

	check_MUL:
		cjne r7, #0EH, check_DIV
		mov opCode, #isMUL
		ljmp storeOp
	
	check_DIV:
		cjne r7, #0DH, check_TRI
		mov opCode, #isDIV
		ljmp storeOp
	
	check_TRI:
		cjne r7, #0CH, check_EQU
		mov opCode, #isTRI
		ljmp storeOp
	
	check_EQU:
		cjne r7, #0FH, noMoreKeys
		ljmp doEQU

storeOp:
	lcall bcd2hex
	jnb mf, noError
	ljmp error
noError:
	lcall copy_xy
	Load_X(0)
	lcall hex2BCD
	lcall Display
	ljmp forever

noMoreKeys:
	ljmp forever
	
doEQU:
	lcall bcd2hex
	jb mf, error
	setb newInput
	clr negFlag
	mov a, opCode

doADD:
	cjne a, #isADD, doSUB
	lcall add32
	jb mf, error
	lcall hex2bcd
	lcall Display
	clr LEDRA.0
	ljmp forever

doSUB:
	cjne a, #isSUB, doMUL
	lcall sub32
	jnb mf, positiveSub
	setb LEDRA.0
	lcall neg32
	sjmp doneSub
positiveSub:
	clr LEDRA.0
doneSub:
	lcall hex2bcd
	lcall Display
	ljmp forever

doMUL:
	cjne a, #isMUL, doDIV
	lcall mul32
	jb mf, error
	lcall hex2bcd
	lcall Display
	clr LEDRA.0
	ljmp forever

doDIV:
	cjne a, #isDIV, doTRI
	lcall div32
	jb mf, error
	lcall hex2bcd
	lcall Display
	clr LEDRA.0
	ljmp forever

doTRI:
	cjne a, #isTRI, noMoreKeys
	lcall tri32
	jb mf, error
	lcall hex2bcd
	lcall Display
	clr LEDRA.0
	ljmp forever

error:
	mov HEX5, #E
	mov HEX4, #r
	mov HEX3, #r
	mov HEX2, #o
	mov HEX1, #r
	mov HEX0, #blank
	ljmp error

	;somethng here