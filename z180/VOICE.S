GOOD_MAX:	EQU	3

	SECTION	WORK

VOICE_MODE:	DB	0
VOICE_G:	DB	0

	SECTION	ICODE

;**********************************************
; Вычисление номера инструмента канала
;IN	A	номер фразы
;**********************************************
PLAY_V:
	CALL	PLV_TEXT
	CALL	PLV_VOICE
	RET
;**********************************************
; текстовое сообщение
PLV_TEXT:
	PUSH	AF
	SUB	V_GMODE
	LD	E,A
	LD	D,3
	MLT	DE
	LD	HL,T_GMODE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	EX	DE,HL
	CALL	PRINT_GRPT
	POP	AF
	RET
;**********************************************
; речевое соообщение
PLV_VOICE:
	PUSH	AF
	LD	E,A
	LD	A,(VOICE_MODE)
	OR	A
	RET	NZ
	LD	D,0
	LD	HL,V_TABLE
	ADD	HL,DE
	LD	L,(HL)	; номер сэмпла
	BIT	7,A
	RET	NZ	; такой фразы нет
	LD	A,7	; номер канала
	LD	BC,7F30H
	CALL	IPLAY
	POP	AF
	RET	

;**********************************************
; метроном клик
;**********************************************

CLICK_H:
	LD	A,80H + METR_CH ; номер канала
	LD	DE,7F00H + METR_L
	CALL	MIDIIN

	LD	A,90H + METR_CH	; номер канала
	LD	DE,7F00H + METR_H
	CALL	MIDIIN
	RET
CLICK_L:
	LD	A,80H + METR_CH	; номер канала
	LD	DE,7F00H + METR_H
	CALL	MIDIIN

	LD	A,90H + METR_CH	; номер канала
	LD	DE,7F00H + METR_L
	CALL	MIDIIN
	RET

PLAY_GOOD:
	LD	A,(VOICE_G)
	INC	A
	LD	(VOICE_G),A
	CP	GOOD_MAX
	JR	C,PLAY_G0
	XOR	A
	LD	(VOICE_G),A
PLAY_G0:
	ADD	V_GOOD
	JP	PLAY_V

PLAY_PROB:
	LD	A,V_PROB
	JP	PLAY_V

PLAY_PROBR:
	LD	A,V_PROBR
	JP	PLAY_V

PLAY_BAD:
	LD	A,(HZ10)
	BIT	1,A
	JR	Z,PLAY_BAD1
	LD	A,V_BAD
	JP	PLAY_V
PLAY_BAD1:
	CALL	FILE_2
	CALL	PLAY_F
	RET
; Речевой банк
V_TABLE:
V_GMODE:EQU	$ -  V_TABLE
	DB	046H,045H ;
V_VER:	EQU	$ -  V_TABLE
	DB	039H,03AH,03BH,03CH,03DH,03EH ;
V_ZVUK:	EQU	$ -  V_TABLE
	DB	03FH,040H
V_LAD:	EQU	$ -  V_TABLE
	DB	041H,042H,043H,044H
V_PROB:	EQU	$ -  V_TABLE
	DB	04CH
V_PROBR: EQU	$ -  V_TABLE
	DB	048H
V_BAD:	EQU	$ -  V_TABLE
	DB	047H ;
V_GOOD:	EQU	$ -  V_TABLE
	DB	049H,04AH,04BH ;

; Текстовый банк

T_GMODE: DB	CHR_T,CHR_S,CHR_NOP,CHR_A,CHR_G,CHR_NOP	;ST , GA
T_VER:	DB	CHR_U,CHR_T,CHR_S,CHR_T,CHR_N,CHR_I	;STU,INT
	DB	CHR_E,CHR_R,CHR_T,CHR_P,CHR_E,CHR_S	;TRE,SEP
	DB	CHR_C,CHR_I,CHR_D,CHR_A,CHR_L,CHR_C	;DIC,CLA
T_ZVUK:	DB	CHR_T,CHR_A,CHR_N,CHR_T,CHR_L,CHR_A	;NAT,ALT
T_LAD:	DB	CHR_G,CHR_A,CHR_NOP,CHR_N,CHR_I,CHR_NOP	;_AG,_IN
	DB	CHR_O,CHR_L,CHR_NOP,CHR_I,CHR_H,CHR_NOP	;_LO,_HI
T_PROB:	DB	CHR_MIN,CHR_MIN,CHR_MIN			;---
T_BAD:	DB	CHR_O,CHR_N,CHR_NOP,CHR_O,CHR_N,CHR_NOP	;_NO,_NO
T_GOOD:	DB	CHR_S,CHR_E,CHR_Y			;YES
	DB	CHR_S,CHR_E,CHR_Y			;YES
	DB	CHR_S,CHR_E,CHR_Y			;YES
	DB	CHR_S,CHR_E,CHR_Y			;YES
	DB	CHR_S,CHR_E,CHR_Y			;YES



