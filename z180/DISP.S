;**********************************************
;	УПРАВЛЕНИЕ ДИСПЛЕЕМ
;
;
;**********************************************

	SECTION	WORK

DISP_DTMP:	DB	0,0,0
DISP_DATA:	DB	0,0,0
DISP_MASK:	DB	0,0,0 	; примешивается & к тому что отображается
DISP_PHASE:	DB	0	; 0= дисплей вкл 1=выкл
DISP_TMP:	DB	0	; время отображения временных данных
DISP_PNTS:	DB	0	; управление точками

	SECTION	ICODE

;**********************************************
; Обновление дисплея
;**********************************************

DISP_RFSH:
	LD	A,(DISP_TMP)
	OR	A
	JR	Z,DRFM_1
;	RET	Z		; если ноль то ничего ни делаем
	SUB	1
	LD	(DISP_TMP),A
;	RET	NZ		; если стал 0 то выводим нормальный буфер
	JR	DRFM_0
; на дисплей идут нормальные данные
DRFM_1:
	LD	A,(DISP_MASK+2)
	LD	H,A
	LD	A,(DISP_DATA+2)
	OR	H
	LD	HL,(DISP_DATA)
	LD	DE,(DISP_MASK)
	ADD	HL,DE
	CALL	DISPLAY
	RET

DISP_RFSHM:
	LD	A,(DISP_TMP)
	OR	A
	JR	NZ,DRFM_0
; на дисплей идут нормальные данные
	LD	A,(DISP_MASK+2)
	LD	H,A
	LD	A,(DISP_DATA+2)
	OR	H
	LD	HL,(DISP_DATA)
	LD	DE,(DISP_MASK)
	ADD	HL,DE
	CALL	DISPLAY
	RET
DRFM_0:
	LD	A,(DISP_MASK+2)
	LD	H,A
	LD	A,(DISP_DTMP+2)
	OR	H
	LD	HL,(DISP_DTMP)
	LD	DE,(DISP_MASK)
	ADD	HL,DE
	CALL	DISPLAY
	RET

;**********************************************
; 	D I S P L A Y   A C C E S
;
;	IN	AHL	DATA FOR DISPALY
;**********************************************
DISPLAY:
	PUSH	DE
	PUSH	AF

	IN0	A,(SPORT)
	RES	1,A
	OUT0	(SPORT),A	; OFF
	SET	1,A
	OUT0	(SPORT),A	; ON

	POP	AF
	PUSH	AF
	CPL
	CALL	CS_TX

	LD	A,H
	CPL
	CALL	CS_TX

	LD	A,L
	CPL
	CALL	CS_TX

	CALL	CS_READY

	IN0	A,(SPORT)
	RES	1,A
	OUT0	(SPORT),A	; OFF
	POP	AF
	POP	DE
	RET

;**********************************************
; 	PRINT BCD
;
;	IN	HL	DATA FOR DISPALY
;		H[7]	SIGN
;**********************************************
PRINT_BCDT:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	LD	IX,DISP_DTMP
	CALL	PRINT_0
	LD	A,5	; 0,5 sek
	LD	(DISP_TMP),A
;	CALL	DISP_RFSHM
	JR	PBCD_0
;
PRINT_BCD:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	LD	IX,DISP_DATA
	CALL	PRINT_0
;	CALL	DISP_RFSHM
PBCD_0:
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	RET

PRINT_0:
	LD	B,A
	LD	A,H
	AND	0FH
	JR	NZ,PRN_1
	LD	(IX+2),B	; " "
	LD	A,L
	AND	0F0H
	JR	NZ,PRN_2
	LD	(IX+1),A	; " "
	JR	PRN_3

PRN_1:
	CALL	BIN2CHAR
	LD	(IX+2),A
;
PRN_2:
	LD	A,L
	RRA
	RRA
	RRA
	RRA
	AND	0FH
	CALL	BIN2CHAR
	LD	(IX+1),A
;
PRN_3:
	LD	A,L
	AND	0FH
	CALL	BIN2CHAR
	LD	(IX+0),A

	BIT	7,H		; знак ?
	RET	Z
	LD	A,(IX+2)
	XOR	40H		; "-"
	LD	(IX+2),A
	RET
;**********************************************
; PROGRESS BAR
;IN	A 	SEGMENT
;**********************************************
PROGRES:
	LD	H,A
	LD	L,A
	JP	DISPLAY

;**********************************************
; ВЫВОД В ГРАФИКЕ
;**********************************************

PRINT_ERRT:
	LD	A,CHR_E
	LD	HL,CHR_R * 256 + CHR_R
	
PRINT_GRPT:
	LD	(DISP_DTMP),HL
	LD	(DISP_DTMP+2),A

	LD	A,5	; 0,5 sek
	LD	(DISP_TMP),A
;	CALL	DISP_RFSHM
	RET

PRINT_GRP:
	LD	(DISP_DATA),HL
	LD	(DISP_DATA+2),A
;	CALL	DISP_RFSHM
	RET

;**********************************************
; Преобразование кода символа в "ВИД"
;
;	IN	A	код символа
;	OUT	A	вид символа
;
;**********************************************

BIN2CHAR:
	PUSH	HL
	LD	L,A
	LD	H,0
	LD	DE,CHAR_TBL
	ADD	HL,DE
	LD	A,(HL)
	POP	HL
	RET

;**********************************************
;
;	ТАБЛИЦА ВИДОВ СИМВОЛОВ
;
;**********************************************

CHAR_TBL:
	DB	00111111B	;0
	DB	00000110B	;1
	DB	01011011B	;2
	DB	01001111B	;3
	DB	01100110B	;4
	DB	01101101B	;5
	DB	01111101B	;6
	DB	00000111B	;7
	DB	01111111B	;8
	DB	01101111B	;9
	DB	01110111B	;A
	DB	01111100B	;B
	DB	01011000B	;C
	DB	01011110B	;D
	DB	01111001B	;E
	DB	01110001B	;F	
	DB	00000000B	;F	

CHR_0:	EQU	00111111B	;0
CHR_1:	EQU	00000110B	;1
CHR_2:	EQU	01011011B	;2
CHR_3:	EQU	01001111B	;3
CHR_4:	EQU	01100110B	;4
CHR_5:	EQU	01101101B	;5
CHR_6:	EQU	01111101B	;6
CHR_7:	EQU	00000111B	;7
CHR_8:	EQU	01111111B	;8
CHR_9:	EQU	01101111B	;9

CHR_NOP: EQU	00000000B	;" "	
CHR_A:	EQU	01110111B	;A
CHR_B:	EQU	01111100B	;B
CHR_C:	EQU	01011000B	;C
CHR_D:	EQU	01011110B	;D
CHR_E:	EQU	01111001B	;E
CHR_F:	EQU	01110001B	;F	
CHR_G:	EQU	00111101B
CHR_I:	EQU	00000100B
CHR_H:	EQU	01110110B
CHR_J:	EQU	00001110B
CHR_L:	EQU	00111000B
CHR_N:	EQU	01010100B
CHR_O:	EQU	01011100B
CHR_P:	EQU	01110011B
CHR_R:	EQU	01010000B
CHR_S:	EQU	01101101B
CHR_T:	EQU	01111000B
CHR_U:	EQU	00111110B
CHR_V:	EQU	00111110B
CHR_Y:	EQU	01101110B
CHR_MIN: EQU	01000000B
CHR_HI: EQU	00000001B
CHR_LO: EQU	00001000B


