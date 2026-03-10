$MODDE0CV

N_9 equ 10011000B ; 9
N_7 equ 11111000B ; 7
N_5 equ 10010010B ; 5
N_3 equ 10110000B ; 3
N_2 equ 10100100B ; 2
N_1 equ 11111001B ; 1
L_H equ 10001001B ; H
L_E equ 10000110B ; E
L_L equ 11000111B ; L
L_O equ 11000000B ; O
L_C equ 11000110B ; C
L_P equ 10001100B ; P
L_N equ 11001000B ; N
OFF equ 0FFH ; OFF

org 0
USING 0
mov LEDRA, #0H
mov LEDRB, #0H
ljmp setState

clearDisplay:
	mov HEX5, #OFF
	mov HEX4, #OFF
	mov HEX3, #OFF
	mov HEX2, #OFF
	mov HEX1, #OFF
	mov HEX0, #OFF
	ret
	
waitHalf:
	mov r2, #45 ;set to 90 for real time
L3: mov r1, #250
L2: mov r0, #250
L1: djnz r0, L1  ; 3 machine cycles-> 3*30ns*250=22.5us
    djnz r1, L2  ; 22.5us*250=5.625ms
    djnz r2, L3  ; 5.625ms*90=0.506s (approximately)
    ret
    
waitChoice:
	jnb KEY.3, setState
	jb SWA.3, waitHalf
	lcall waitHalf
	lcall waitHalf
	ret

setState:
	jb KEY.3, setState
	mov a, SWA
	anl a, #00000111B
	cjne a, #000B, s001
	lcall state_000
	ljmp setState
s001:
	cjne a, #001B, s010
	lcall state_001
	ljmp setState
s010:
	cjne a, #010B, s011
	lcall state_010
	ljmp setState
s011:
	cjne a, #011B, s100
	lcall state_011
	ljmp setState
s100:
	cjne a, #100B, s101
	lcall state_100
	ljmp setState
s101:
	cjne a, #101B, s110
	lcall state_101
	ljmp setState
s110:
	cjne a, #110B, s111
	lcall state_110
	ljmp setState
s111:
	cjne a, #111B, setState
	lcall state_111
	ljmp setState
	
runSeq:
	clr a
	movc a, @a+dptr
	mov r7, a
	inc dptr
	mov r5, dpl
	mov r4, dph
	mov r6, #0
seqLoop:
	mov a, r6
	mov b, #6
	mul ab
	add a, r5
	mov dpl, a
	mov a, b
	addc a, r4
	mov dph, a
	clr a
	movc a, @a+dptr
	mov HEX5,a 
	inc dptr
	clr a
	movc a,@a+dptr 
	mov HEX4, a
	inc dptr
	clr a
	movc a, @a+dptr
	mov HEX3, a
	inc dptr
	clr a
	movc a, @a+dptr
	mov HEX2, a
	inc dptr
	clr a
	movc a, @a+dptr
	mov HEX1, a
	inc dptr
	clr a
	movc a, @a+dptr
	mov HEX0, a
	
	lcall waitChoice
	jc seqEnd
	inc r6
	mov a, r6
	cjne a, 07H, seqLoop
	mov r6, #0
	sjmp seqLoop
	
seqEnd:
	ret
	
state_000:
	mov HEX5, #N_9
	mov HEX4, #N_7
	mov HEX3, #N_2
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_1
	ret
	
state_001:
	mov HEX5, #OFF
	mov HEX4, #OFF
	mov HEX3, #OFF
	mov HEX2, #OFF
	mov HEX1, #N_1
	mov HEX0, #N_5
	ret

state_010:
	mov dptr, #seq_010
	ljmp runSeq

state_011:
	mov dptr, #seq_011
	ljmp runSeq

state_100:
	mov HEX5, #N_2
	mov HEX4, #N_1
	mov HEX3, #N_5
	mov HEX2, #N_1
	mov HEX1, #N_1
	mov HEX0, #N_5
	lcall waitChoice
	lcall clearDisplay
	lcall waitChoice
	sjmp state_100
	
state_101:
	mov dptr, #seq_101
	ljmp runSeq
	
state_110:
	mov dptr, #seq_110
	ljmp runSeq

state_111:
	jnb KEY.3, exit_111
	mov r5, #OFF
	jnb SWA.5, sw4
	mov r5, #N_9
sw4:
	mov r4, #OFF
	jnb SWA.4, sw3
	mov r4, #N_7
sw3:
	mov r3, #OFF
	jnb SWA.3, sw2
	mov r3, #N_2
sw2:
	mov r2, #OFF
	jnb SWA.2, sw1
	mov r2, #N_1
sw1:
	mov r1, #OFF
	jnb SWA.1, sw0
	mov r1, #N_5
sw0:
	mov r0, #OFF
	jnb SWA.0, writeSW
	mov r0, #N_1
writeSW:
	mov HEX5, r5
	mov HEX4, r4
	mov HEX3, r3
	mov HEX2, r2
	mov HEX1, r1
	mov HEX0, r0
	sjmp state_111
exit_111:
	ret
;----------------------------------------------------------------
seq_010:
	db 8
	db N_9, N_7, N_2, N_1, N_5, N_1
	db N_7, N_2, N_1, N_5, N_1, N_1
	db N_2, N_1, N_5, N_1, N_1, N_5
	db N_1, N_5, N_1, N_1, N_5, N_9
	db N_5, N_1, N_1, N_5, N_9, N_7
	db N_1, N_1, N_5, N_9, N_7, N_2
	db N_1, N_5, N_9, N_7, N_2, N_1
	db N_5, N_9, N_7, N_2, N_1, N_5
	
seq_011:
	db 8
	db N_9, N_7, N_2, N_1, N_5, N_1
	db N_5, N_9, N_7, N_2, N_1, N_5
	db N_1, N_5, N_9, N_7, N_2, N_1
	db N_1, N_1, N_5, N_9, N_7, N_2
	db N_5, N_1, N_1, N_5, N_9, N_7
	db N_1, N_5, N_1, N_1, N_5, N_9
	db N_2, N_1, N_5, N_1, N_1, N_5
	db N_7, N_2, N_1, N_5, N_1, N_1
	
seq_101:
	db 7
	db OFF, OFF, OFF, OFF, OFF, OFF
	db N_9, OFF, OFF, OFF, OFF, OFF
	db N_9, N_7, OFF, OFF, OFF, OFF
	db N_9, N_7, N_2, OFF, OFF, OFF
	db N_9, N_7, N_2, N_1, OFF, OFF
	db N_9, N_7, N_2, N_1, N_5, OFF
	db N_9, N_7, N_2, N_1, N_5, N_1
	
seq_110:
	db 3
	db L_H, L_E, L_L, L_L, L_O, OFF
	db N_9, N_7, N_2, N_1, N_5, N_1
	db L_C, L_P, L_N, N_3, N_1, N_2
END

	