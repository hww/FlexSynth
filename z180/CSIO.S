;**********************************************
; СИНХРОННЫЙ СЕРИАЛЬНЫЙ ИНТЕРФЕЙС
;
;
;**********************************************

	SECTION	ICODE

;**********************************************
; Инициализация интерфейса
;**********************************************

CS_INIT:
	XOR	A
	OUT0	(CNTR),A
	CALL	CS_TX
	RET
;----------------------------------------------
;IN 	HL	SOURCE
;IN	DE	LENGHT
;
CS_O_BLOK:
	CALL	CS_INIT
CS_LOOP:
	LD	A,(HL)
	CALL	CS_TX
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,CS_LOOP
	RET
;----------------------------------------------
;IN	A	DATA
;
CS_TX:
	PUSH	AF
	CALL	CS_READY
	POP	AF

	OUT0	(TRDR),A

	IN0	A,(CNTR)
	SET	4,A
	OUT0	(CNTR),A
	RET

CS_READY:
	IN0	A,(CNTR)
	BIT	4,A
	JR	NZ,CS_READY
	RET

;**********************************************
; 	ИНИЦИАЛИЗАЦИЯ FLEX
;
;IN	HL	адрес файла инициализации
;IN	DE	размер блока
;**********************************************
FLEX_INIT:
	DI
	LD	DE,14751 + 2
	LD	HL,4000H
	LD	A,0

	CALL	ROM_ENA
	IN0	A,(SPORT)
	SET	0,A
	OUT0	(SPORT),A

	LD	B,10
TW_0:
	NOP			; 500ns = (( 125ns * 3t ) + (125ns * 9t)) * 10
	DJNZ	TW_0

	RES	0,A
	OUT0	(SPORT),A
F_NR:
	IN0	A,(SPORT)
	BIT	6,A
	JR	Z,F_NR

	LD	B,10
TW_1:
	NOP			; 500ns = (( 125ns * 3t ) + (125ns * 9t)) * 10
	DJNZ	TW_1

FLEX_LOOP:
	LD	A,(HL)
	LD	B,A
	CALL	CS_TX
	IN0	A,(SPORT)
	BIT	6,A
	JR	Z,FLEX_ERROR

	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,FLEX_LOOP

	CALL	CS_READY	
	IN0	A,(SPORT)
	BIT	7,A
	RET	NZ

FLEX_ERROR:
	SCF
	RET

;**********************************************

;**********************************************

FLEX_CRC:
	LD	HL,4000H
	LD	A,0
	CALL	ROM_CRC
	RET