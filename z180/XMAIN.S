
	SECTION	ICODE

;**********************************************
;	MAIN FUNCTION LIST
;**********************************************
CHKRAM:
	DI
	LD	SP,0FFFFH	;0,1,2
	LD	BC,40H		;3,4,5
	LD	A,0CH		;6,7 /RAM0,RAM1 ON/
	OUT	(C),A		;8,9

	LD	A,84H 		;10,11 /0000-4000-8000/
	LD	C,CBAR		;12,13
	OUT	(C),A 		;6,7 /0000-4000-8000/

	LD	C,CBR		;8,9
	LD	A,0F0H		;10,11 /F0XXX+8000=F800
	OUT	(C),A		;12,13

	LD	HL,LO_MEM
	LD	DE,LO_MEM+1
	LD	BC,0FFFFH-LO_MEM

	LD	(HL),0
	LDIR

	LD	SP,HIMEM

	LD	A,1CH
	OUT0	(SPORT),A	; Start OFF

	LD	A,0H		; 3 IORQ WAIT
	OUT0	(DCNTL),A

	LD	A,0C0H
	OUT0	(OMCR),A

; инициализаци я FLEX
	CALL	TX_OFF          ; RTS=0
	CALL	CS_INIT		; ИНИТ СИНХРОННОГО ПОРТА

	LD	A,CHR_1		; ---> V E R S I O N
	LD	HL,CHR_V * 256 + CHR_5
	CALL	DISPLAY

	LD	A,0
	LD	HL,4000H
	LD	DE,14751
	CALL	FLEX_INIT
	JR	C,DIE_LOOP

	CALL	PRG_CRC
	LD	A,CHR_C		; --->
	CALL	DISPLAY

; загрузка звукового банка
	IF	SROM_ON
	CALL	MOVE_ROM
	ENDIF

	LD	A,CHR_U		; --->
	LD	HL,CHR_A * 256 + CHR_R
	CALL	DISPLAY

; инициализация рабочей области

	LD	HL,END_ICODE
	LD	DE,WORKA
	LD	BC,END_WORK - WORKA
	LDIR

	LD	HL,RETURN
	LD	(VBASE),HL
	LD	(VBASE+2),HL
	LD	(VBASE+4),HL
	LD	(VBASE+6),HL
	LD	(VBASE+8),HL
	LD	(VBASE+10),HL
	LD	(VBASE+12),HL
	LD	(VBASE+14),HL
	LD	(VBASE+16),HL

	LD	HL,VBASE
	LD	A,H
	LD	I,A
	LD	A,L
	OUT0	(IL),A
	IM	2

;**********************************************
;	LINK WITH EXTERNAL CPU
;**********************************************
LINK_CPU:
	LD	A,CHR_D		; --->
	LD	HL,CHR_R * 256 + CHR_U
	CALL	DISPLAY

	CALL	RFSHM
	CALL	MIDIIN_INIT	
	CALL	ASCI1_INIT

	LD	A,CHR_C		; --->
	LD	HL,CHR_L * 256 + CHR_R
	CALL	DISPLAY

	CALL	FILE_0
	CALL	INT_INIT

	LD	A,(STATION)
	AND	0FH
	CALL	BIN2CHAR
	LD	HL,CHR_NOP * 256 + CHR_I
	CALL	DISPLAY

	IF	RAM
	EI
DIE_LOOP:
	XOR	A
	OUT0	(COMAND),A	; CLEAR PREVIOUS COMAND

LINK_MLOOP:
	IN0	A,(COMAND)	; CLEAR PREVIOUS COMAND
	AND	30H
	OUT0	(COMAND),A	; CLEAR PREVIOUS COMAND
LINK_LOOP:
	IN0	A,(COMAND)
	AND	0FH
	JR	Z,LINK_LOOP
	CALL	XBIOS_EXE
	JP	LINK_MLOOP
;**********************************************
;	E X E C U T E   R O U T I N E
;**********************************************
XBIOS_EXE:
	IN0	A,(COMAND)
	LD	C,A
	LD	L,A
	LD	H,0
	LD	B,0

	ADD	HL,BC
	ADD	HL,BC		; MUL 3

	LD	BC,XBIOS
	ADD	HL,BC		; BASE OFSET
	LD	BC,EXE_RET
	PUSH	BC
	PUSH	HL
	IN0	A,(MA)
	IN0	L,(MHL)
	IN0	H,(MHL+1)
	IN0	E,(MDE)
	IN0	D,(MDE+1)
	IN0	C,(MBC)
	IN0	B,(MBC+1)
	RET
EXE_RET:
	OUT0	(MA),A
	OUT0	(MHL),L
	OUT0	(MHL+1),H
	OUT0	(MDE),E
	OUT0	(MDE+1),D
	OUT0	(MBC),C
	OUT0	(MBC+1),B
	PUSH	AF
	POP	HL
	OUT0	(MF),L
	RET

	ELSE
DIE_LOOP:
	EI
	SLP
	JP	DIE_LOOP
	ENDIF
;**********************************************
; ЗАГЛУШКА ПРЕРЫВАНИЯ
;**********************************************
RETURN:
	EI
	RETI
