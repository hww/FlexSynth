	SECTION	WORK

RND_VAL:	DW	1

	SECTION	ICODE

;**********************************************
; ПРЕОБРАЗУЕТ БАЙТ В СЛОВО
;IN	L	байт
;OUT	HL	слово
;**********************************************
B2W:
	LD	H,0
	BIT	7,L
	RET	Z
	LD	H,0FFH
	RET

;**********************************************
;  ПРОГРАММА СРАВНЕНИЯ
;IN	HL
;IN	DE
;OUT	CF=1	HL<DE
;OUT	CF=0	HL>DE
;OUT	Z=1,CF=0 HL=DE
;CHNG	A	
;**********************************************

CPHLDE:
	LD	A,H
	SUB	D
	RET	NZ
	LD	A,L
	SUB	E
	RET

;**********************************************
;  ПРОГРАММА СРАВНЕНИЯ
;IN	HL
;IN	BC
;OUT	CF=1	HL<BC
;OUT	CF=0	HL>BC
;OUT	Z=1,CF=0 HL=BC
;CHNG	A	
;**********************************************

CPHLBC:
	LD	A,H
	SUB	B
	RET	NZ
	LD	A,L
	SUB	C
	RET

;**********************************************
;  ПРОГРАММА СРАВНЕНИЯ СО ЗНАКОМ
;IN	HL
;IN	DE
;OUT	CF=1	HL<DE
;OUT	CF=0	HL>DE
;OUT	Z=1,CF=0 HL=DE
;CHNG	A	
;**********************************************

CPHLDES:
	LD	A,H
	XOR	D
	AND	80H	; сравнили знаки
	JR	Z,CPHLDE ; знаки равны 
	LD	A,H
	OR	1	; сформировать NZ
	RLA		; сформировать CF
	RET

;**********************************************
;  ПРОГРАММА СРАВНЕНИЯ СО ЗНАКОМ
;IN	HL
;IN	BC
;OUT	CF=1	HL<BC
;OUT	CF=0	HL>BC
;OUT	Z=1,CF=0 HL=BC
;CHNG	A	
;**********************************************

CPHLBCS:
	LD	A,H
	XOR	B
	AND	80H	; сравнили знаки
	JR	Z,CPHLBC ; знаки равны 
	LD	A,H
	OR	1	; сформировать NZ
	RLA		; сформировать CF
	RET

;**********************************************
; HLBC = BC * DE
;**********************************************
MLT16:
	LD	HL,0
	LD	A,B
	LD	B,11H
	JR	MUL_1
;
MUL_3:	JR	NC,MUL_2
	ADD	HL,DE
MUL_2:	RR	H
	RR	L
MUL_1:	RR	A
	RR	C
	DJNZ	MUL_3
	LD	B,A
	RET

;**********************************************
; BC = INT( BC / DE )
;**********************************************
DIV16:
	LD	HL,0
	LD	A,B
	LD	B,10H
	RL	C
	RLA
DIV_0:	RL	L
	RL	H
	JR	C,DIV_3
	SBC	HL,DE
	JR	NC,DIV_1
	ADD	HL,DE
DIV_1:	CCF
DIV_2:	RL	C
	RLA
	DJNZ	DIV_0
	LD	B,A
; BC = результат HL = остаток
; Целое от ( BC,HL )
	ADD	HL,HL
	OR	A
	SBC	HL,DE	;( Остаток * 2 ) - делител
	RET	C
	INC	BC
	RET	
DIV_3:	OR	A
	SBC	HL,DE
	JR	DIV_2
;**********************************************
; BC =MOD ( BC / DE )    HL = FRACT ( BC / DE )
;**********************************************
MOD16:
	LD	HL,0
	LD	A,B
	LD	B,10H
	RL	C
	RLA
MOD_0:	RL	L
	RL	H
	JR	C,MOD_3
	SBC	HL,DE
	JR	NC,MOD_1
	ADD	HL,DE
MOD_1:	CCF
MOD_2:	RL	C
	RLA
	DJNZ	MOD_0
	LD	B,A
	RET	
MOD_3:	OR	A
	SBC	HL,DE
	JR	MOD_2
;**********************************************
; HL = ABS (HL) : H[7] = SIGN
;**********************************************
ABSHL:

	BIT	7,H
	RET	Z

	EX	DE,HL
	LD	HL,0FFFFH
	OR	A
	SBC	HL,DE
	INC	HL
	SET	7,H	; SIGN = 1
	RET
;**********************************************
; HL = -HL : H[7] = SIGN
;**********************************************
NEGHL:
	LD	A,L
	CPL	A
	LD	L,A
	LD	A,H
	CPL	A
	LD	H,A
	INC	HL
	RET
;**********************************************
; BIN2DEC	HL = DEC(HL)
;**********************************************
BIN2DEC:
	CALL	ABSHL

	LD	A,H
	PUSH	AF	; сохраним знак

	LD	C,L
	LD	B,H
	RES	7,B

	LD	DE,10
	CALL	MOD16
	PUSH	HL	; (SP) = FR(N/10)
			; N = N MOD 10
	LD	DE,10
	CALL	MOD16
	LD	H,16
	MLT	HL
	POP	DE
	ADD	HL,DE
	PUSH	HL

	LD	DE,10
	CALL	MOD16
	LD	H,L
	LD	L,0
	POP	DE
	ADD	HL,DE

	POP	AF
	RLC	H
	RLA
	RR	H	; установили знак
	RET

;**********************************************
; DEBC = MOD ( DEBC / A )    A = FRACT ( DEBC / A )
;**********************************************
MOD32:
	LD	H,B
	LD	L,C	; HL=BC
	LD	C,A	; C=A
	LD	A,0
	LD	B,20H	; бит

	RL	L
	RL	H
	RL	E
	RL	D	
MOD32_0:
	RLA		; ADEHL <-
	JR	C,MOD32_3
	SUB	C
	JR	NC,MOD32_1
	ADD	C
MOD32_1:
	CCF
MOD32_2:
	RL	L
	RL	H
	RL	E
	RL	D
	DJNZ	MOD32_0
	PUSH	HL
	POP	BC
	RET	
MOD32_3:
	SUB	C
	JR	MOD32_2
;**********************************************
; A = RND (A)
;**********************************************
RND_X:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	CALL	RND
	PUSH	HL
	POP	BC	; BC = RND
	POP	AF
	LD	E,A
	LD	D,0
	CALL	MOD16	; BC / DE
	LD	A,L	; L = BC FRACT DE 
	POP	BC
	POP	DE
	POP	HL
	RET

;**********************************************
; HL = RND
;**********************************************

RND:
	LD	HL,(RND_VAL)
	LD	B,16
RND_L:
	LD	A,H
	ADD	HL,HL
	AND	60H
	JP	PE,RND_0
	INC	HL
RND_0:
	DJNZ	RND_L
	LD	(RND_VAL),HL
	RET