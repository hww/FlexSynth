;**********************************************
; РАБОТА С ДСП
;**********************************************

	SECTION	WORK

TUNE:	DW	0000H

	SECTION	ICODE

;**********************************************
; TST DSP
;**********************************************
DSP_SIMPL:
	DI
	LD	HL,0
	LD	DE,0
	CALL	DSP_SET
	LD	B,0
DSP_SIM_0:
	OUT0	(DSP),B
	DJNZ	DSP_SIM_0
	LD	C,0
	LD	HL,0FF00H
	CALL	DSP_RSET
	OUT0	(DSP+2),L
	OUT0	(DSP+2),L	; START
	OUT0	(DSP+2),L
	OUT0	(DSP+2),L	; LOOP
	OUT0	(DSP+2),H
	OUT0	(DSP+2),L	; END
	OUT0	(DSP+2),L	; PAGE
	OUT0	(DSP+2),H	; VOL
	OUT0	(DSP+2),L
	OUT0	(DSP+2),L	; SPARE
	OUT0	(DSP+2),H
	OUT0	(DSP+2),H	; DIV
	LD	A,1
	OUT0	(DSP+1),A
	RET

DSP_TST:
	LD	HL,0
	LD	DE,0
	CALL	DSP_SET
	LD	B,16
	LD	C,0
DSP_TST_0:
	OUT0	(DSP),L
	OUT0	(DSP),H

	LD	DE,1
	ADD	HL,DE
	JR	NC,DSP_TST_0
	INC	HL
	DJNZ	DSP_TST_0

	LD	HL,0
	LD	DE,0
	CALL	DSP_SET
	LD	B,16
	LD	C,1
DSP_TST_1:
	IN0	A,(DSP)
	CP	L
	JR	NZ,DSP_TST_2
	IN0	A,(DSP)
	CP	H
	JR	NZ,DSP_TST_2

	LD	DE,1
	ADD	HL,DE
	JR	NC,DSP_TST_1
	INC	HL
	DJNZ	DSP_TST_1
	OR	A
	EI
	RET
DSP_TST_2:
	SCF
	EI
	RET

;**********************************************
;вход	EHL	адрес
;выход	A	данные	
;**********************************************

DSP_MRD:
	DI
	LD	A,8CH
	OUT0	(DSP+3),A
	OUT0	(DSP+2),L
	OUT0	(DSP+2),H
	OUT0	(DSP+2),E
	IN0	A,(DSP)
;	EI
	RET
;**********************************************
;вход	EHL	адрес
;	A	данные	
;**********************************************
DSP_MWR:
	DI
	LD	D,8CH
	OUT0	(DSP+3),D
	OUT0	(DSP+2),L
	OUT0	(DSP+2),H
	OUT0	(DSP+2),E
	OUT0	(DSP),A
;	EI
	RET
;**********************************************
;вход	C	адрес
;	A	данные	
;**********************************************
DSP_RRD:
	OUT0	(DSP+3),C
	IN0	A,(DSP+2)
	RET
;**********************************************
;вход	C	адрес
;	A	данные	
;**********************************************
DSP_RWR:
	OUT0	(DSP+3),C
	OUT0	(DSP+2),A
	RET
;**********************************************
;выход	A	данные	
;**********************************************
DSP_STAT:
	IN0	A,(DSP+1)
	RET
;**********************************************
;вход	A	данные CNTR
;выход	A	данные STAT	
;**********************************************
DSP_CNTR:
	OUT0	(DSP+1),A
	IN0	A,(DSP+1)
	RET
;**********************************************
;вход	EHL	адрес 	[DI]
;**********************************************
DSP_SET:
	DI
	LD	D,8CH
	OUT0	(DSP+3),D
	OUT0	(DSP+2),L
	OUT0	(DSP+2),H
	OUT0	(DSP+2),E
	RET
;**********************************************
; Загрузака данныхи из памяти
; HL	Adres memory
; DE	Lenght
;**********************************************
DSP_LDIR:
	PUSH	AF
DSP_LDIRL:
	LD	A,(HL)
	OUT0	(DSP),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,DSP_LDIRL
	POP	AF
	RET	
		
;**********************************************
;вход	C	адрес 	[DI]
;**********************************************
DSP_RSET:
	DI
	SET	7,C		; автоинкремент
	OUT0	(DSP+3),C
	RET

;**********************************************
; вход  C	номер регистра
; выход HL	коф деления
;**********************************************
DSP_RRDW:
	OUT0	(DSP+3),C
	IN0	L,(DSP+2)
	IN0	H,(DSP+2)
	RET
DSP_RWRW:
	OUT0	(DSP+3),C
	OUT0	(DSP+2),L
	OUT0	(DSP+2),H
	RET
;**********************************************
;вход	C	канал 	[DI]
;	A	громкость
;**********************************************
DSP_VOL:
	PUSH	AF
	PUSH	BC
	PUSH	AF
	LD	B,16
	MLT	BC	; канал * 16
	LD	A,C
	ADD	7	; + 7 "регистр громкости"
	OUT0	(DSP+3),A
	IN0	A,(DSP+2)
	AND	80H	; бит зацикливания
	LD	B,A
	POP	AF	; 000V VVVV
	AND	1FH	; 000V VVVV только громкость
	OR	B
	OUT0	(DSP+2),A	
	POP	BC
	POP	AF
	RET

DSP_GETVOL:
	PUSH	BC
	LD	B,16
	MLT	BC	; канал * 16
	LD	A,C
	ADD	7	; + 7 "регистр громкости"
	OUT0	(DSP+3),A
	IN0	A,(DSP+2)
	AND	1FH
	POP	BC
	RET

;**********************************************
; Проигрывание звука
;
;IN	A	CHANEL	
;	L	INSTRUMENT
;	C	NOTE
;	B	VOLUME
;**********************************************
IPLAY:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	H,16
	MLT	HL	; INSTR * 16
	LD	DE,ITABLE
	ADD	HL,DE	; + BASE TABLE 
	PUSH	HL
	POP	IX	; IX = BASE INSTUMENT
	CALL	PLAY
	LD	A,H	; текущая громкость
	POP	BC
	POP	DE
	POP	HL
	LD	H,A	; текущая громкость
	POP	AF
	RET
;**********************************************
; Проигрывание звука
;
;IN	A	CHANEL	
;	IX	MEMLOCATION SAMPLE HEADER
;	C	NOTE
;	B	VOLUME
;**********************************************
PLAY:
	DI
	AND	7
	CALL	DSP_STOP

	PUSH	AF
	PUSH	BC

	CALL	R_SET

	LD	A,(IX)		; начало мл байт
	OUT0	(DSP+2),A
	LD	A,(IX+1)	; ст б.
	OUT0	(DSP+2),A
	
	LD	A,(IX+2)
	OUT0	(DSP+2),A
	LD	A,(IX+3)	; лооп
	OUT0	(DSP+2),A

	LD	A,(IX+4)	; конец мл. байт
	OUT0	(DSP+2),A
	LD	A,(IX+5)	; ст б.
	OUT0	(DSP+2),A

	LD	A,(IX+6)	; страница
	OUT0	(DSP+2),A 	; страница

	LD	A,(IX+7)	; флаг лооп/громкость
	POP	BC		; нота и громкость
	LD	L,A		; громкость в инструменте 7 бит
	PUSH	AF
	RES	7,L		; сброс. лооп бита
	INC	L		; гр. в инстр 80H .. 01H
	LD	H,B		; входная громкость = 7 бит
	RES	7,H
	MLT	HL		;HL= 00VV VVVV VVVV VVVV = громкость * громкость
	RL	L
	RL	H		;HL= 0VVV VVVV VVVV VVVV = громкость * громкость
	LD	A,(MAIN_VOL)
	LD	L,A
	MLT	HL		;HL= 00VV VVVV VVVV VVVV = громкость * громкость
	SRL	H		;H = 000V VVVV

	POP	AF
	AND	80H
	OR	H		; лооп бит
	OUT0	(DSP+2),A	; громкость и признак зацикливания	

	XOR	A
	OUT0	(DSP+2),A	; кодек старт	
	OUT0	(DSP+2),A		

	PUSH	HL		; текущая громкость

	CALL	S_DIV

	POP	HL
	POP	AF
	CALL	DSP_PUSK
;	EI
	RET

R_SET:
	PUSH	BC
	PUSH	AF
	LD	B,A
	LD	C,16	; регистров на канал
	MLT	BC	; BC=B*C номер канала * регистров на канал
	CALL	DSP_RSET
	POP	AF
	POP	BC
	RET
;**********************************************
; Запуск иостанов канала
;**********************************************

DSP_PUSK:
	PUSH	AF
	PUSH	BC
	LD	B,A
	INC	B
	LD	A,80H
	CALL	ST_LOP
	IN0	B,(DSP+1)
	OR	B
	OUT0	(DSP+1),A
	POP	BC
	POP	AF
	RET

DSP_STOP:
	PUSH	AF
	PUSH	BC
	LD	B,A
	INC	B
	LD	A,7FH
	CALL	ST_LOP
	IN0	B,(DSP+1)
	AND	B
	OUT0	(DSP+1),A
	POP	BC
	POP	AF
	RET

ST_LOP:
	RLCA
	DJNZ	ST_LOP
	RET
;**********************************************
; Установим коэфициэнт деления
; IN	C	нота
;
;**********************************************

S_DIV:
	LD	L,C	; note
	CALL	N_2_ON
	LD	C,A	; octave_note

	LD	L,(IX+0AH) ; Snote нота оцифровики
	CALL	N_2_ON
	LD	B,A	; S.octave_note оцифровки

	LD	A,B
	AND	0FH	; S.note
	LD	L,A
	LD	H,12
	MLT	HL	; S.note * 12

	LD	A,C
	AND	0FH	; .note
	LD	E,A
	LD	D,0
	ADD	HL,DE	; (S.note * 12) + note
	ADD	HL,HL	; ((S.note*12)+note)*2

	LD	DE,DIV_TABLE
	ADD	HL,DE	; (((S.note * 12) + note)*2)+DIV_TABLE

	LD	E,(HL)
	INC	HL
	LD	D,(HL)	; DE=divisor
	EX	DE,HL
	LD	DE,0	; EHL.D=kdiv

	LD	A,C
	AND	0F0H	; octave
	LD	C,A
	LD	A,B
	AND	0F0H	; S.octave-octave
	SUB	C	; разность октав

	JR	Z,N_OK
	JR	C,N_T2
SHR_OC:
	RR	H
	RR	L	; KDIV/2
	RR	D
	SUB	10H
	JR	NZ,SHR_OC
	JR	N_OK
N_T2:
	OR	A
	RL	L
	RL	H	; KDIV*2
	RL	E
N_OK:
	LD	A,(IX+8); SAMP RATE LOW
	CP	44H
	JR	Z,SR44

	OR	A	; 22 kHz
	RR	E
	RR	H
	RR	L	; KDIV/2
	RR	D

SR44:
	LD	A,D
	CP	81H
	JR	C,ROUND_F
	INC	HL
ROUND_F:
	LD	DE,(TUNE)
	ADD	HL,DE
	OUT0	(DSP+2),L
	OUT0	(DSP+2),H
	RET
;**********************************************
; IN	L	NOTE
; OUT	A	OCTAVE/NOTE
;**********************************************
N_2_ON:
	LD	H,0
	LD	DE,ON_TABLE
	ADD	HL,DE
	LD	A,(HL)
	RET

ON_TABLE:
	DB	00H,01H,02H,03H,04H,05H,06H,07H,08H,09H,0AH,0BH
	DB	10H,11H,12H,13H,14H,15H,16H,17H,18H,19H,1AH,1BH
	DB	20H,21H,22H,23H,24H,25H,26H,27H,28H,29H,2AH,2BH
	DB	30H,31H,32H,33H,34H,35H,36H,37H,38H,39H,3AH,3BH
	DB	40H,41H,42H,43H,44H,45H,46H,47H,48H,49H,4AH,4BH
	DB	50H,51H,52H,53H,54H,55H,56H,57H,58H,59H,5AH,5BH
	DB	60H,61H,62H,63H,64H,65H,66H,67H,68H,69H,6AH,6BH
	DB	70H,71H,72H,73H,74H,75H,76H,77H,78H,79H,7AH,7BH
	DB	80H,81H,82H,83H,84H,85H,86H,87H,88H,89H,8AH,8BH
	DB	90H,91H,92H,93H,94H,95H,96H,97H,98H,99H,9AH,9BH
