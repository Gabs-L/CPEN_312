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
OFF equ 0FFH ;
org 0
mov ledra, #0H
mov ledrb, #0H

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
    mov 0BH, #90 ; was 130
L3: mov 0AH, #250
L2: mov 09H, #250
L1: djnz 09H, L1  ; 3 machine cycles-> 3*30ns*250=22.5us
    djnz 0AH, L2  ; 22.5us*250=5.625ms
    djnz 0BH, L3  ; 5.625ms*90=0.506s (approximately)
	ret
	
setState:
	jb KEY.3, start
	mov r0, swa
	mov a, r0
	mov r0, a
	
start:
	mov a, r0
	cjne a, #0, s1
	lcall state_000
s1:
	cjne a, #1, s2
	lcall state_001
s2:
	cjne a, #2, s3
	lcall state_010
s3:
	cjne a, #3, s4
	lcall state_011
s4:
	cjne a, #4, s5
	lcall state_100
s5:
	cjne a, #5, s6
	lcall state_101
s6:
	cjne a, #6, s7
	lcall state_110
s7:
	cjne a, #7, other
	lcall state_111
other: lcall setState

state_000:
	mov HEX5, #N_9
	mov HEX4, #N_7
	mov HEX3, #N_2
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_1
	ret
	
state_001:
	mov HEX6, #OFF
	mov HEX5, #OFF
	mov HEX4, #OFF
	mov HEX3, #OFF
	mov HEX2, #OFF
	mov HEX1, #N_1
	mov HEX0, #N_5
	ret
	
state_010:
	mov HEX5, #N_9
	mov HEX4, #N_7
	mov HEX3, #N_2
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_1
	lcall waitChoice_010
	mov HEX5, #N_7
	mov HEX4, #N_2
	mov HEX3, #N_1
	mov HEX2, #N_5
	mov HEX1, #N_1
	mov HEX0, #N_1
	lcall waitChoice_010
	mov HEX5, #N_2
	mov HEX4, #N_1
	mov HEX3, #N_5
	mov HEX2, #N_1
	mov HEX1, #N_1
	mov HEX0, #N_5
	lcall waitChoice_010
	mov HEX5, #N_1
	mov HEX4, #N_5
	mov HEX3, #N_1
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_9
	lcall waitChoice_010
	mov HEX5, #N_5
	mov HEX4, #N_1
	mov HEX3, #N_1
	mov HEX2, #N_5
	mov HEX1, #N_9
	mov HEX0, #N_7
	lcall waitChoice_010
	mov HEX5, #N_1
	mov HEX4, #N_1
	mov HEX3, #N_5
	mov HEX2, #N_9
	mov HEX1, #N_7
	mov HEX0, #N_2
	lcall waitChoice_010
	mov HEX5, #N_1
	mov HEX4, #N_5
	mov HEX3, #N_9
	mov HEX2, #N_7
	mov HEX1, #N_2
	mov HEX0, #N_1
	lcall waitChoice_010
	mov HEX5, #N_5
	mov HEX4, #N_9
	mov HEX3, #N_7
	mov HEX2, #N_2
	mov HEX1, #N_1
	mov HEX0, #N_5
	lcall waitChoice_010
		
	setState_010:
		lcall setState
	waitHalf_010:
		lcall waitHalf
	ret
	waitChoice_010:
		jnb KEY.3, setState_010
		jb SWA.3, waitHalf_010
		lcall waitHalf
		lcall waitHalf
	ret
	
state_011:
	mov HEX5, #N_9
	mov HEX4, #N_7
	mov HEX3, #N_2
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_1
	lcall waitChoice_011
	mov HEX5, #N_5
	mov HEX4, #N_9
	mov HEX3, #N_7
	mov HEX2, #N_2
	mov HEX1, #N_1
	mov HEX0, #N_5
	lcall waitChoice_011
	mov HEX5, #N_1
	mov HEX4, #N_5
	mov HEX3, #N_9
	mov HEX2, #N_7
	mov HEX1, #N_2
	mov HEX0, #N_1
	lcall waitChoice_011
	mov HEX5, #N_1
	mov HEX4, #N_1
	mov HEX3, #N_5
	mov HEX2, #N_9
	mov HEX1, #N_7
	mov HEX0, #N_2
	lcall waitChoice_011
	mov HEX5, #N_5
	mov HEX4, #N_1
	mov HEX3, #N_1
	mov HEX2, #N_5
	mov HEX1, #N_9
	mov HEX0, #N_7
	lcall waitChoice_011
	mov HEX5, #N_1
	mov HEX4, #N_5
	mov HEX3, #N_1
	mov HEX2, #N_1
	mov HEX1, #N_5
	mov HEX0, #N_9
	lcall waitChoice_011
	mov HEX5, #N_2
	mov HEX4, #N_1
	mov HEX3, #N_5
	mov HEX2, #N_1
	mov HEX1, #N_1
	mov HEX0, #N_5
	lcall waitChoice_011
	mov HEX5, #N_7
	mov HEX4, #N_2
	mov HEX3, #N_1
	mov HEX2, #N_5
	mov HEX1, #N_1
	mov HEX0, #N_1
	lcall waitChoice_011
	
	setState_011:
		lcall setState
	waitHalf_011:
		lcall waitHalf
	ret
	waitChoice_011:
		jnb KEY.3, setState_011
		jb SWA.3, waitHalf_011
		lcall waitHalf
		lcall waitHalf
	ret
	
state_100:
	state_100_loop:
		jnb KEY.3, setState_100
		
		mov HEX5, #N_2
		mov HEX4, #N_1
		mov HEX3, #N_5
		mov HEX2, #N_1
		mov HEX1, #N_1
		mov HEX0, #N_5

		jb SWA.3, active_100
		lcall waitHalf
		lcall waitHalf
		lcall clearDisplay
		lcall waitHalf
		lcall waitHalf
		sjmp state_100_loop
		
	active_100:
		lcall waitHalf
		lcall clearDisplay
		lcall waitHalf
		sjmp state_100_loop

	setState_100:
		lcall setState
	ret
	
state_101:
	state_101_loop:
		jnb KEY.3, setState_101
		
		mov r5, #N_9
		mov r4, #N_7
		mov r3, #N_2
		mov r2, #N_1
		mov r1, #N_5
		mov r0, #N_1
		
		mov HEX5, #OFF
		mov HEX4, #OFF
		mov HEX3, #OFF
		mov HEX2, #OFF
		mov HEX1, #OFF
		mov HEX0, #OFF
		lcall waitChoice_101
		
		mov HEX5, r5
		lcall waitChoice_101
		mov HEX4, r4
		lcall waitChoice_101
		mov HEX3, r3
		lcall waitChoice_101
		mov HEX2, r2
		lcall waitChoice_101
		mov HEX1, r1
		lcall waitChoice_101
		mov HEX0, r0
		lcall waitChoice_101
		sjmp state_101_loop
	
	setState_101:
		lcall setState
	waitHalf_101:
		lcall waitHalf
		
	ret
	waitChoice_101:
		jnb KEY.3, setState_101
		jb SWA.3, waitHalf_101
		lcall waitHalf
		lcall waitHalf
	ret
	
state_110:
	state_110_loop:
		mov HEX5, #L_H
		mov HEX4, #L_E
		mov HEX3, #L_L
		mov HEX2, #L_L
		mov HEX1, #L_O
		mov HEX0, #OFF
		lcall waitChoice_110
		mov HEX5, #N_9
		mov HEX4, #N_7
		mov HEX3, #N_2
		mov HEX2, #N_1
		mov HEX1, #N_5
		mov HEX0, #N_1
		lcall waitChoice_110
		mov HEX5, #L_C
		mov HEX4, #L_P
		mov HEX3, #L_N
		mov HEX2, #N_3
		mov HEX1, #N_1
		mov HEX0, #N_2
		lcall waitChoice_110
	sjmp state_110_loop
	
	waitChoice_110:
		jnb KEY.3, SetState_110
		jb SWA.3, activeWait_110
		lcall waitHalf
		lcall waitHalf
	ret
	
	activeWait_110:
		lcall waithalf
		
	ret
	setState_110:
		lcall setState
	
state_111:
	state_111_loop:
	jnb KEY.3, setState_111
		mov HEX5, #OFF
		mov HEX4, #OFF
		mov HEX3, #OFF
		mov HEX2, #OFF
		mov HEX1, #OFF
		mov HEX0, #OFF
		
		jb SWA.5, on5
			sjmp check4
			on5:
			mov HEX5, #N_9
			
	check4:
		jb SWA.4, on4
			sjmp check3
			on4:
			mov HEX4, #N_7
	check3:
		jb SWA.3, on3
			sjmp check2
			on3:
			mov HEX3, #N_2
	check2:	
		jb SWA.2, on2
			sjmp check1
			on2:
			mov HEX2, #N_1
	check1:	
		jb SWA.1, on1
			sjmp check0
			on1:
			mov HEX1, #N_5
	check0:	
		jb SWA.0, on0
		sjmp state_111_loop
		on0:
			mov HEX0, #N_1
			sjmp state_111_loop
	setState_111:
		lcall setState
	ret
END