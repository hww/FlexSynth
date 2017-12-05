;**********************************************
; Рабочая область миди каналов
; на каждый канал 8 байта
;**********************************************
MCHS:		EQU	4	; количество каналов (было 6)

MCH_PRG:	EQU	0
MCH_TRANS:	EQU	1
MCH_VOL:	EQU	2
MCH_PITCH:	EQU	3	; 2 байта
MCH_OFF:	EQU	5
MCH_MIX:	EQU	6

;**********************************************
; Рабочая область ДСП каналов
;**********************************************
DSP_AFLAGS:	EQU	0
DSP_AMCH:	EQU	1
DSP_AMPRG:	EQU	2
DSP_ANOTE:	EQU	3
DSP_AVOL:	EQU	4
DSP_ASMP:	EQU	5
DSP_ASVOL:	EQU	6
DSP_ATR:	EQU	7
DSP_AREL:	EQU	8

	SECTION	WORK

CH_CASE:	DB	0	; случайный выбор канала

	SECTION	ICODE

;**********************************************
; Инициализация
;**********************************************

MIDIIN_INIT:
	DI
	LD	IX,MCH_AREA
	LD	DE,8
	LD	B,MCHS
MIDIINI_0:
	LD	(IX+MCH_PRG),0
	LD	(IX+MCH_TRANS),0
	LD	(IX+MCH_VOL),80H
	LD	(IX+MCH_PITCH),0
	LD	(IX+MCH_PITCH+1),0
	LD	(IX+MCH_OFF),0
	LD	(IX+MCH_MIX),0
	ADD	IX,DE
	DJNZ	MIDIINI_0

	LD	A,2
	LD	(MCH_AREA+8*METR_CH+MCH_PRG),A

	LD	A,1
	LD	(MCH_AREA + 8 + MCH_MIX),A


	LD	HL,DSP_AREA
	LD	DE,DSP_AREA+1
	LD	BC,8*16
	LD	(HL),0
	LDIR
	XOR	A
	LD	(CH_CASE),A
	RET

;**********************************************
; Все сообщения
;IN	A	Midi Command
;IN	DE	E=byte1 D=byte2
;**********************************************

MIDIIN:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	PUSH	IY
	LD	C,A
	AND	0FH
	LD	B,A

	CP	KBD_MCH
	CALL	Z,REC_MIDI	; клавиатура пишем в миди канал

	LD	A,(M_RECCH)
	CP	B
	JR	NZ,MI_1		; все каналы воспроизводим
				; канал на запись
	LD	A,(MIDION)
	BIT	MREC_F,A
	JR	NZ,MI_2		; если запись канал на запись не воспроизв
MI_1:
	LD	A,C
	CALL	MIDIIN1
MI_2:
	POP	IY
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	RET

MIDIIN1:
	PUSH	AF
	AND	070H
	RRCA
	RRCA
	RRCA			;0000XXX0
	LD	L,A
	LD	H,0
	LD	BC,MFN_TABLE
	ADD	HL,BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	POP	AF
	PUSH	BC
MIDI_EXIT:
	RET

MFN_TABLE:
	DW	NOTE_OFF
	DW	NOTE_ON
	DW	KEY_AFT
	DW	CNTR_CHG
	DW	PRG_CHG
	DW	CH_AFT
	DW	PITCH_CHG
	DW	MIDI_EXIT

;**********************************************
; Формирование затухающей 
;**********************************************

RELEASE:
	LD	IY,DSP_AREA
	LD	C,0		; канал
	LD	B,8		; каналов
REL_LOP:
	LD	A,(IY+DSP_AFLAGS)
	CP	4
	JR	NZ,REL_NEXT

	LD	A,(IY+DSP_ASVOL)
	SUB	1
	JR	NC,REL_N0

	LD	A,0
	LD	(IY+DSP_AFLAGS),A ; chanel off
	LD	(IY+DSP_ASVOL),A	; volum = 0
	LD	A,C		; DSP_Achanel
	CALL	DSP_STOP
REL_N0:
	LD	(IY+DSP_ASVOL),A	; sec volume
	CALL	DSP_VOL
REL_NEXT:
	LD	DE,16
	ADD	IY,DE
	INC	C
	DJNZ	REL_LOP
	RET

;**********************************************
; Поиск DSPA канала 
;IN	L	NOTE
;IN	H	CHANEL
;OUT	IY	BASE
;OUT	C	CHANEL
;**********************************************

DSP_SRCH:
	PUSH	DE
	LD	IY,DSP_AREA
	LD	C,0		; канал
	LD	B,8		; каналов
DSRCH_LOP:
	LD	A,(IY+DSP_AMCH)
	CP	H
	JR	NZ,DSRCH_NEXT

	LD	A,(IY+DSP_ANOTE)
	CP	L
	JR	NZ,DSRCH_NEXT

	POP	DE
	OR	A
	RET

DSRCH_NEXT:
	LD	DE,16
	ADD	IY,DE
	INC	C
	DJNZ	DSRCH_LOP
	POP	DE
	SCF
	RET

;**********************************************
; Клавиша отпущена
;**********************************************

NOTE_OFF:
	AND	0FH		; chanel
	LD	H,A
NOTE_OFF1:
	LD	L,E		; note
	CALL	DSP_SRCH	; ret: IY=BASE
	JR	C,OFF_EXIT

	LD	A,(IY+DSP_AFLAGS) ; 4=stop chanel
	OR	A
	RET	Z
	LD	A,4
	LD	(IY+DSP_AFLAGS),A ; 4=stop chanel
OFF_EXIT:
	RET
;**********************************************
; Клавиша нажата
;**********************************************

NOTE_ON:
	AND	A,0FH		; mchanel
	LD	H,A
	LD	A,D		; velocity
	OR	A
	JP	Z,NOTE_OFF1

	LD	A,H
	CALL	MIDI_CALC	; IX = база миди канала
	BIT	0,(IX+MCH_OFF)
	RET	NZ		; канал выключен
	LD	L,E		; note
	CALL	DSP_SRCH	; ret: IY=BASE
	LD	B,H		; B=Mchanel
	JR	NC,FOUND_CHO
	CALL	LET_CHANEL

; IY DSP_ABASE, D=velocyty E=note B=Mchanel C=chanal
FOUND_CHO:
	LD	A,1
	LD	(IY+DSP_AFLAGS),A ; 1=start chanel
	LD	(IY+DSP_ANOTE),E ; note
	LD	E,(IX+MCH_VOL)
	MLT	DE
	RL	E
	RL	D		; D=vol
	LD	A,(IX+MCH_MIX)
	OR	A
	JR	NZ,V_B	

	LD	A,(VOL_A)
	JR	V_A
V_B:
	LD	A,(VOL_B)
V_A:
	LD	E,A		; E=VOL B
	MLT	DE
	RL	E
	RL	D		; D=vol
	LD	(IY+DSP_AVOL),D	; volume
	LD	(IY+DSP_AMCH),B	; midi chanel

	LD	A,B		; midi chanel
	CALL	INST_CALC	; PRG & note -> sample
				; A= samle number
	CP	0FFH
	JP	Z,INS_BAD
	LD	L,A		; samle number
	LD	A,C		; DSP chanel
	LD	B,(IY+DSP_AVOL)
	LD	C,(IY+DSP_AREL)
	CALL	IPLAY
	LD	(IY+DSP_ASVOL),H ; текущая громкость
	RET
INS_BAD:
	XOR	A
	LD	(IY+DSP_AFLAGS),A ; 1=start chanel
	LD	(IY+DSP_AVOL),A	; volume
	LD	(IY+DSP_AMCH),A	; midi chanel
	LD	(IY+DSP_ANOTE),A
	LD	(IY+DSP_AREL),A
	RET
;**********************************************
; Подбор канала
;OUT	C	Chanel
;OUT	IY	DSP_ABASE
;**********************************************
LET_CHANEL:
	PUSH	DE
; подберём канал
	CALL	DSP_STAT
	LD	C,A
	BIT	1,H		; H = Midi chanel
	JR	NZ,EVEN_CH
	OR	0AAH
	JR	ODD_CH
EVEN_CH:
	OR	055H
ODD_CH:
	CP	0FFH
	JR	NZ,CHS_FREE
	LD	A,C
	CP	0FFH
	JR	NZ,CHS_FREE
; Свободных каналов нет
	LD	A,(CH_CASE)
	INC	A
	AND	3
	LD	(CH_CASE),A	; DSPA chanel
	ADD	A
	LD	C,A
	LD	A,H
	AND	1
	OR	C
	LD	C,A
	LD	IY,DSP_AREA
	LD	DE,16
	INC	A
CHS_RNDL:
	DEC	A
	JR	Z,FOUND_CH
	ADD	IY,DE
	JR	CHS_RNDL
FOUND_CH:
	POP	DE
	RET
; есть свободные каналы в ДСП
CHS_FREE:
	LD	IY,DSP_AREA
	LD	DE,16
	LD	C,0
CHS_FREEL:
	RRA
	JR	NC,FOUND_CH
	ADD	IY,DE
	INC	C
	JR	CHS_FREEL

;**********************************************
; Изменение громкости
;**********************************************

KEY_AFT:
	RET
;**********************************************
; Изменение контроллера
;**********************************************

CNTR_CHG:
	RET
;**********************************************
; Изменение инструмента
;**********************************************
PRG_CHG:
	LD	C,E
	CALL	MIDI_CALC
	LD	(HL),C
	RET
;**********************************************
; Изменение громкости
;**********************************************
CH_AFT:
	RET

;**********************************************
; Питч измменение
;**********************************************
PITCH_CHG:
	RET

;**********************************************
; Вычисление буфера канала
;IN	A	command
;**********************************************
MIDI_CALC:
	PUSH	AF
	PUSH	DE
	AND	0FH	; 0000CCCC канал
	LD	E,A
	LD	D,8	; 8 байт на канал
	MLT	DE
	LD	IX,MCH_AREA
	ADD	IX,DE
	POP	DE
	POP	AF
	RET
;**********************************************
; Вычисление номера инструмента канала
;IN	A	midi chanel
;**********************************************
INST_CALC:
	LD	H,(IX+MCH_PRG)	; H=PRG
	LD	L,(IX+MCH_TRANS) ; TRANS	
	LD	A,(IY+DSP_ANOTE)
	ADD	L		; Транспонирование
	AND	7FH
	LD	(IY+DSP_AREL),A

	LD	L,A
	SRL	H
	RL	L
	RRC	L
	LD	DE,INST_TABLE
	ADD	HL,DE
	LD	A,(HL)
	RET

INST_TABLE:
; рояль
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H	;10
	DB	001H,001H,001H,001H,001H,001H,001H,002H,002H,002H,002H,002H
	DB	002H,002H,002H,002H,003H,003H,003H,003H,003H,003H,003H,003H
	DB	004H,004H,004H,004H,004H,004H,004H,004H,004H,004H,005H,005H
	DB	005H,005H,005H,006H,006H,006H,006H,006H,006H,006H,006H,006H	;40
	DB	006H,006H,006H,006H,006H,006H,006H,006H,006H,006H,006H,006H
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH	;70
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
; голосовой банк
	DB	0ffH,0ffH,0ffH,0ffH,0ffH,0ffH,0ffH,0ffH,0fFH,0ffH,0ffH,0ffH ;0
	DB	008H,009H,00AH,00BH,00CH,00DH,00EH,00FH,010H,011H,012H,013H ;12
	DB	008H,009H,00AH,00BH,00CH,00DH,00EH,00FH,010H,011H,012H,013H ;24
	DB	014H,015H,016H,017H,018H,019H,01AH,01BH,01CH,01DH,01EH,01FH ;36
	DB	020H,021H,022H,023H,024H,025H,026H,027H,028H,029H,02AH,02BH ;48
	DB	02CH,02DH,02EH,02FH,030H,031H,032H,033H,034H,035H,036H,037H ;60
	DB	038H,039H,02EH,02FH,030H,031H,032H,033H,034H,035H,036H,037H ;72
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;84
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;96
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;108
	DB	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH			    	;120
; голосовой банк

	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7


