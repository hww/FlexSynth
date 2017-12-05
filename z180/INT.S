;CH_MASK:	EQU	0FH
CH_MASK:	EQU	3 ; МАСКА КАНАЛОВ В МИДИОН
MPLA_F0:	EQU	0
MPLA_F1:	EQU	1
;MPLA_F2:	EQU	2
;MPLA_F3:	EQU	3
MCLK_F:		EQU	4
MREC_F:		EQU	5
MSYN_F:		EQU	6
MMET_F:		EQU	7	

	SECTION	WORK

; таймер 10 гц
HZ10:		DB	0
;
QUANT:		EQU	LO_MEM + 13	; время одной четверти
TRK_NUM:	EQU	LO_MEM + 11	; количество треков

G_TMRL:		DW	0	; счетчик 1/96
G_TMRH:		DW	0
G_DTIME0L:	DW	0	; дельта времени
G_DTIME0H:	DW	0
G_DTIME1L:	DW	0	; дельта времени
G_DTIME1H:	DW	0
;G_DTIME2L:	DW	0	; дельта времени
;G_DTIME2H:	DW	0
;G_DTIME3L:	DW	0	; дельта времени
;G_DTIME3H:	DW	0
R_DTIMEL:	DW	0
R_DTIMEH:	DW	0
G_QUANT:	DB	0	; 96/8 длительность кванта
G_Q_NUM:	DW	0	; номер текущего кванта
G_1_NUM:	DW	0	; номер целой
G_METR:		DW	0	; номер доли
G_P_Q:		DB	0	; позиция внутри четверти

G_TEMP:		DW	120
G_TEMP100:	DW	120
G_TEMPK:	DW	0
G_TEMPF:	DB	0

REP_UP:		DB	0
REP_DOWN:	DB	0

	SECTION	ICODE

;**********************************************
; Инициализация
;**********************************************
;**********************************************
; ЗАПУСК ПРЕРЫВАНИЯ 100 ГЦ
;**********************************************
INT_INIT:

	DI

	LD	HL,INT10MS
	LD	(VPRT_1),HL

	LD	HL,8000000/20/100
	OUT0	(RLDR1L),L
	OUT0	(RLDR1H),H

	LD	A,22H		; T1 down count , T1IE
	OUT0	(TCR),A

;**********************************************
; ЗАПУСК ПРЕРЫВАНИЯ МИДИ
;**********************************************

	LD	HL,INT_MIDI
	LD	(VPRT_0),HL

	LD	HL,400000/212	; 212=96*2 
	OUT0	(RLDR0L),L
	OUT0	(RLDR0H),H

	IN0	A,(TCR)
	LD	A,33H		; T0 & T1 down count , T1IE & T1IE
	OUT0	(TCR),A

	RET	

;**********************************************
; Установка частоты прерываний таймера 0
;IN	DEBC	время четверти в микросекундах
;**********************************************
SET_TIME:
	LD	L,C
	LD	H,B
	ADD	HL,BC
	LD	C,L
	LD	B,H
	EX	DE,HL
	ADC	HL,HL
	EX	DE,HL	; DEBC * 2
	LD	A,(QUANT)
	CALL	MOD32	; DEBC=DEBC/A {A=96}
	LD	A,5
	CALL	MOD32	; DEBC / 5
			; 2/5 = 4/10 = 8/20
	
	OUT0	(RLDR0L),C
	OUT0	(RLDR0H),B

	LD	DE,120
	CALL	MOD16	; KDIV/120
	PUSH	BC
	POP	DE
	LD	BC,500000*2/96/5 ; KDIV120
	CALL	MOD16
	LD	(G_TEMP),BC
	RET

;**********************************************
; Установка ТЕМПА
;**********************************************
CHNG_TEMP:
	LD	DE,(G_TEMP)
	LD	BC,500000*2/96/5 ; KDIV120 / TEMP
	CALL	MOD16
	
	LD	DE,120
	CALL	MLT16		; (KDIV120 / TEMP) * 120

	OUT0	(RLDR0L),C
	OUT0	(RLDR0H),B

	RET

;**********************************************
; ПРЕРЫВАНИЕ 100 ГЦ
;**********************************************

INT10MS:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	PUSH	IY
	IN0	A,(TCR)
	IN0	A,(TMDR1L)
	IN0	A,(TMDR1H)

	CALL	RELEASE
	CALL	INT_DISP

	POP	IY
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	EI
	RET
;**********************************************
; ПРЕРЫВАНИЕ 1/96 ЧЕТВЕРТИ
;**********************************************

INT_MIDI:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	PUSH	IY
	IN0	A,(TCR)
	IN0	A,(TMDR0L)
	IN0	A,(TMDR0H)
				; главный счетчик от начала файла
	CALL	MIDI_CLK	; задержка воспроизведения

	CALL	INT_METR

	POP	IY
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	EI
	RET

;**********************************************
; Обновление дисплея 4 раза за четверть
;**********************************************

INT_DISP:
	LD	A,(HZ10)
	DEC	A
	LD	(HZ10),A
	RET	NZ
	LD	A,10
	LD	(HZ10),A
	CALL	RFSH		; проверка изменения переменной
	CALL	DISP_RFSH	; обновление порта дисплея
	CALL	KEY_REPEAT	; автоповтор клавиш
	RET

;**********************************************
; Управление метрономом
;**********************************************

INT_METR:
	LD	A,(G_P_Q)	; позиция внутри четверти
	DEC	A
	LD	(G_P_Q),A
	JR	NZ,ASK_QUANT

	LD	A,(QUANT)
	LD	(G_P_Q),A

	CALL	QUANT_CLK
	CALL	METR_CLK

	LD	A,(GEN_MODE)
	OR	A
	RET	Z
	CALL	GAME_INT
	RET

ASK_QUANT:
	LD	C,A
	LD	A,(QUANT)
	SRA	A
	CP	C
	RET	NZ

	LD	HL,0		; погасили точки
	LD	(DISP_MASK+1),HL
	RET

METR_CLK:
	LD	A,(MIDION)
	BIT	MMET_F,A
	RET	Z

	LD	A,(G_METR)	; доля
	OR	A
	JR	Z,BIG_METR	; сильная доля
	BIT	0,A
	JR	Z,LOW_METR2

LOW_METR1:
	LD	HL,8000H
	LD	(DISP_MASK+1),HL
	CALL	CLICK_L
	RET

LOW_METR2:
	LD	HL,0080H
	LD	(DISP_MASK+1),HL
	CALL	CLICK_L
	RET

BIG_METR:
	LD	HL,8080H
	LD	(DISP_MASK+1),HL
	CALL	CLICK_H
	RET

;**********************************************
; 	главиный счётчик в (1/4)/96 
;	измерение времени при записи
;**********************************************
MIDI_CLK:
	LD	A,(MIDION)
	BIT	MCLK_F,A
	RET	Z		; выключено всё

	LD	HL,(G_TMRH)	; + DTIMER
	LD	DE,(G_TMRL)
	EX	DE,HL
	LD	BC,1
	ADD	HL,BC
	EX	DE,HL
	LD	C,0
	ADC	HL,BC
	LD	(G_TMRH),HL
	LD	(G_TMRL),DE

	CALL	MCLK_0
	CALL	MCLK_1
;	CALL	MCLK_2
;	CALL	MCLK_3
	
	LD	A,(MIDION)
	BIT	MREC_F,A
	RET	NZ		; если запись то продолжаем

	AND	CH_MASK		; если запись выкл и все каналы тоже
	JR	Z,EOF

	LD	DE,(L1_TMRH)
	LD	BC,(L1_TMRL)
	CALL	CPHLDE_DT
	RET	C
EOF:
	LD	A,(MARK_FL)
	BIT	1,A
	JP	Z,STOP_F
	JP	TOMARK

MCLK_0:
	LD	A,(MIDION)
	BIT	MPLA_F0,A
	RET	Z

	LD	DE,(G_DTIME0H)
	LD	BC,(G_DTIME0L)
	CALL	CPHLDE_DT
	RET	C
	LD	HL,(M_PNTR0)
	CALL	PLAY_BF
	LD	(M_PNTR0),HL
	CALL	SET_DTIME0
	RET	NZ
	LD	A,(MIDION)
	RES	MPLA_F0,A
	LD	(MIDION),A
	RET
MCLK_1:
	LD	A,(MIDION)
	BIT	MPLA_F1,A
	RET	Z

	LD	DE,(G_DTIME1H)
	LD	BC,(G_DTIME1L)
	CALL	CPHLDE_DT
	RET	C
	LD	HL,(M_PNTR1)
	CALL	PLAY_BF
	LD	(M_PNTR1),HL
	CALL	SET_DTIME1
	RET	NZ
	LD	A,(MIDION)
	RES	MPLA_F1,A
	LD	(MIDION),A
	RET
;MCLK_2:
;	LD	A,(MIDION)
;	BIT	MPLA_F2,A
;	RET	Z

;	LD	DE,(G_DTIME2H)
;	LD	BC,(G_DTIME2L)
;	CALL	CPHLDE_DT
;	RET	C
;	LD	HL,(M_PNTR2)
;	CALL	PLAY_BF
;	LD	(M_PNTR2),HL
;	CALL	SET_DTIME2
;	RET	NZ
;	LD	A,(MIDION)
;	RES	MPLA_F2,A
;	LD	(MIDION),A
;	RET
;MCLK_3:
;	LD	A,(MIDION)
;	BIT	MPLA_F3,A
;	RET	Z
;
;	LD	DE,(G_DTIME3H)
;	LD	BC,(G_DTIME3L)
;	CALL	CPHLDE_DT
;	RET	C
;	LD	HL,(M_PNTR3)
;	CALL	PLAY_BF
;	LD	(M_PNTR3),HL
;	CALL	SET_DTIME3
;	RET	NZ
;	LD	A,(MIDION)
;	RES	MPLA_F3,A
;	LD	(MIDION),A
;	RET

; HL = HIGHT DE = LOW
CPHLDE_DT:
	LD	HL,(G_TMRH)	; сравним текущее время с необходимым
	CALL	CPHLDE
	RET	NZ
	LD	HL,(G_TMRL)
	CALL	CPHLBC
	RET	

;**********************************************
; Подсчет четвертей и метронома
;**********************************************
QUANT_CLK:
	PUSH	BC

	LD	A,(T_SIG)	; количество долей
	LD	B,A

	LD	A,(G_METR)	; A = номер доли
	INC	A
	LD	(G_METR),A
	CP	B
	POP	BC
	RET	C

	XOR	A
	LD	(G_METR),A	; доля
	RET

;**********************************************
; Сброс DTIMERA
;**********************************************
RES_DTIMER:
	LD	HL,0
	LD	(G_DTIME0L),HL
	LD	(G_DTIME0H),HL
	LD	(G_DTIME1L),HL
	LD	(G_DTIME1H),HL
;	LD	(G_DTIME2L),HL
;	LD	(G_DTIME2H),HL
;	LD	(G_DTIME3L),HL
;	LD	(G_DTIME3H),HL
	LD	(G_TMRL),HL
	LD	(G_TMRH),HL
	LD	(R_DTIMEL),HL
	LD	(R_DTIMEH),HL
	RET

;**********************************************
; Установить время прерывания
; IN	DEBC	дельта время
;**********************************************

SET_DTIME0:
	PUSH	AF
	LD	HL,(G_DTIME0L)
	ADD	HL,BC
	LD	(G_DTIME0L),HL

	LD	HL,(G_DTIME0H)
	ADC	HL,DE
	LD	(G_DTIME0H),HL
	POP	AF
	RET

SET_DTIME1:
	PUSH	AF
	LD	HL,(G_DTIME1L)
	ADD	HL,BC
	LD	(G_DTIME1L),HL

	LD	HL,(G_DTIME1H)
	ADC	HL,DE
	LD	(G_DTIME1H),HL
	POP	AF
	RET

;SET_DTIME2:
;	PUSH	AF
;	LD	HL,(G_DTIME2L)
;	ADD	HL,BC
;	LD	(G_DTIME2L),HL
;
;	LD	HL,(G_DTIME2H)
;	ADC	HL,DE
;	LD	(G_DTIME2H),HL
;	POP	AF
;	RET
;
;SET_DTIME3:
;	PUSH	AF
;	LD	HL,(G_DTIME3L)
;	ADD	HL,BC
;	LD	(G_DTIME3L),HL
;
;	LD	HL,(G_DTIME3H)
;	ADC	HL,DE
;	LD	(G_DTIME3H),HL
;	POP	AF
;	RET

;**********************************************
; Вычисление изменения времени при записи
;**********************************************
CALC_DTIME:
	LD	HL,(G_TMRH)
	LD	DE,(G_TMRL)
	EX	DE,HL

	LD	BC,(R_DTIMEL)
	LD	(R_DTIMEL),HL
	OR	A
	SBC	HL,BC
	PUSH	HL
	POP	BC
	EX	DE,HL
	LD	DE,(R_DTIMEH)
	LD	(R_DTIMEH),HL
	SBC	HL,DE
	EX	DE,HL
	RET	

;**********************************************
; Автоповтор клавиш
;**********************************************
KEY_REPEAT:
	LD	A,(REP_UP)
	OR	A
	JR	Z,KR_0
	DEC	A
	LD	(REP_UP),A
	JR	NZ,KR_0
	LD	A,1
	LD	(REP_UP),A
	CALL	KEY_UPREP
	RET
KR_0:
	LD	A,(REP_DOWN)
	OR	A
	RET	Z
	DEC	A
	LD	(REP_DOWN),A
	RET	NZ
	LD	A,1
	LD	(REP_DOWN),A
	CALL	KEY_DOWNREP
	RET
