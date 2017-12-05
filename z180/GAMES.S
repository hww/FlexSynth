
	SECTION	WORK

GM_PHASE: 	DB	0
GM_MODE: 	DB	0	; 0=STEP 5=DICTANT 6=CLASTER 
				; 2=INTERVAL 3=TRIZVUK 4=SEPTACCORD
GM_NOTE: 	DB	0	; предыдущая нота
GM_METR: 	DB	0	; 0=2X дольный 1=3X дольный
GM_LAD:	DB	0	; 0-мажор 1-минор 2-уменьшенный 3-увелич.
GM_ZVUK: 	DB	0	; 0=натуральный 1=альтерированый
GM_PNTR: 	DB	0	; указатель колонки для выбора
GM_INPUT:	DS	9
GM_NTMP: 	DS	9	; буфер ноток
GM_NBUF: 	DS	9	; буфер ноток
GM_TBUF: 	DS	9	; буфер длительностей
GM_NBUFSRT: DS	9	; буфер ноток
GM_BOUNUS:	DB	0	; балы
GM_STAGE:	DB	0	; сложность кластеров 2 - 7
GM_TMR:	DB	0	; формирование задержек

	SECTION	ICODE

;**********************************************
; ВХОД ПРЕРЫВАНИЯ ИГРЫ
;**********************************************
GAME_INT:
; вызывает соответствующую функцию
	LD	A,(GM_MODE)
	OR	A
	JP	Z,GAME_STEPS
	CP	1
	JP	Z,GAME_INTER
	CP	2
	JP	Z,GAME_TREZ
	CP	3
	JP	Z,GAME_SEPT
	CP	4
	JP	Z,GAME_DICT
	CP	5
	JP	Z,GAME_CLAST
	RET

;**********************************************
; Вызывается нажатием копки РЕЖИМ
;**********************************************
GAME_INIT:
; сбрасывает поинтер
	XOR	A
	LD	(GM_PNTR),A
	LD	(GM_PHASE),A
	CALL	DSP_STAT
	AND	A,80H
	CALL	DSP_CNTR
	RET

;**********************************************
; Форт ядро 
;**********************************************

FORT:
	POP	DE	; адрес возврата
	LD	A,(GM_PHASE)
	LD	L,A
	LD	H,0
	ADD	HL,HL	; селектор * 2
	ADD	HL,DE	; (HL) адрес ячейки п ерехода
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,FORT_INC
	PUSH	HL
	PUSH	DE
FORT_NOP:
	RET

FORT_INC:
	LD	A,(GM_PHASE)
	INC	A
	LD	(GM_PHASE),A
	RET

;**********************************************
; 	С Т У П Е Н И 
;**********************************************

GAME_STEPS:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	STEPS_INIT
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	ST_REP		;MAKE
	DW	ROYAL		;ROYAL
	DW	STEPS_ON
	DW	FORT_NOP
	DW	STEPS_OFF
	DW	STEPS_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	STEPS_ON
	DW	FORT_NOP
	DW	STEPS_OFF
	DW	STEPS_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	SONGS		;VOICE
	DW	FORT_NOP
	DW	FORT_NOP
	DW	STEPS_ON
	DW	FORT_NOP
	DW	STEPS_OFF
	DW	STEPS_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	FORT_NOP
	DW	FORT_NOP
	DW	STEPS_ON
	DW	FORT_NOP
	DW	STEPS_OFF
	DW	STEPS_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB

;----------------------------------------------
; первая фаза инициализация и генерация звука
STEPS_INIT:
	CALL	GM_NMAKE	; создали нотную последовательность
	XOR	A
	LD	(GM_BOUNUS),A
	RET
;----------------------------------------------
; включение звука  
STEPS_ON:
	LD	A,(GM_NOTE)
	LD	E,A
	LD	D,7FH
	LD	A,90H
	CALL	MIDIIN		; воспроизвели ноту
	XOR	A
	LD	(GM_INPUT),A
	RET
;----------------------------------------------
; выключение звука 
STEPS_OFF:
	LD	A,(GM_NOTE)
	LD	E,A
	LD	D,7FH
	LD	A,80H
	CALL	MIDIIN		; воспроизвели ноту
	RET
;----------------------------------------------
; проверка прихода ноты
STEPS_CHECK:
	LD	A,(GM_INPUT)
	OR	A
	JR	NZ,STCH_0
	POP	HL
	RET
STCH_0:
	LD	A,(GM_INPUT+1)
	LD	B,A
	LD	A,(GM_NOTE)
	CP	B
	JP	Z,BOUNUS_INC

	XOR	A
	LD	(GM_INPUT),A
	RET

STEPS_CHECKNB:
	LD	A,(GM_INPUT)
	OR	A
	JR	NZ,STCH_0NB
	POP	HL
	RET
STCH_0NB:
	LD	A,(GM_INPUT+1)
	LD	B,A
	LD	A,(GM_NOTE)
	CP	B
	JP	Z,STCH_1NB

	XOR	A
	LD	(GM_INPUT),A
	RET
STCH_1NB:
	JP	STEPS_LOOP

;----------------------------------------------

BOUNUS_CLR:
	XOR	A
	LD	(GM_BOUNUS),A
	LD	(GM_STAGE),A
	RET

BOUNUS_INC:			; + STEPS_LOOP
	LD	A,(GM_BOUNUS)
	INC	A
	LD	(GM_BOUNUS),A

STEPS_LOOP:
	CALL	STEPS_LOOPB
	LD	A,(GM_BOUNUS)
	LD	C,A
	LD	B,0
	LD	DE,5
	CALL	MOD16
	LD	A,C
	LD	(GM_STAGE),A

	LD	A,L
	OR	A
	JP	Z,PLAY_GOOD

	CALL	FILE_1
	CALL	PLAY_F
	RET

STEPS_LOOPB:
	LD	A,2
	LD	(GM_PHASE),A
	RET

;----------------------------------------------

ROYAL:
	XOR	A
	LD	(MCH_AREA + MCH_PRG),A
	RET
SONGS:
	LD	A,1
	LD	(MCH_AREA + MCH_PRG),A
	RET

;----------------------------------------------
; берём нотку и инициализируем ноты если нужно
ST_REP:
	LD	HL,GM_NBUF
	LD	A,(GM_PNTR)
	LD	D,0
	LD	E,A
	INC	A
	LD	(GM_PNTR),A
	CP	(HL)
	JR	NC,ST_REPMK

	INC	HL
	ADD	HL,DE
	LD	A,(HL)
	LD	(GM_NOTE),A
	RET

ST_REPMK: 
	XOR	A
	LD	(GM_PNTR),A

	INC	HL
	ADD	HL,DE
	LD	A,(HL)
	LD	(GM_NOTE),A

	CALL	GM_NMAKE
	RET

;**********************************************

GAME_INTER:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	BOUNUS_CLR
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	INTER_NOTE	;MAKE
	DW	CLAST_SORT
	DW	ROYAL		;ROYAL
	DW	CLAST_ON
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	SONGS		;VOICE
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB

INTER_NOTE:
	LD	HL,GM_NBUF
	LD	(HL),2
	INC	HL

	LD	A,(GM_STAGE)
	CP	20
	JR	C,INTER_LO
	CP	40
	JR	NC,INTER_HI
;MEDIUM
	LD	(HL),48
	INC	HL
INTER_L0:
	LD	A,1
	PUSH	HL
	CALL	GM_GETN		; A= nota
	POP	HL
	CP	48
	JR	NC,INTER_L0
	LD	(HL),A
	RET

INTER_LO:
	LD	(HL),48
	INC	HL
INTER_L1:
	LD	A,1
	PUSH	HL
	CALL	GM_GETN		; A= nota
	POP	HL
	CP	49
	JR	C,INTER_L1
	LD	(HL),A
	RET

INTER_HI:
	LD	A,(HL)
	INC	HL
	LD	(HL),A
	DEC	HL
INTER_L2:
	LD	A,1
	PUSH	HL
	CALL	GM_GETN		; A= nota
	POP	HL
	CP	(HL)
	JR	Z,INTER_L2
	LD	(HL),A
	RET

INTER_SORT:
	LD	HL,GM_NBUF
	LD	DE,GM_NBUFSRT
	LD	BC,9
	LDIR
	RET
;**********************************************

GAME_TREZ:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	BOUNUS_CLR
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	TREZ_NOTE	;MAKE
	DW	CLAST_SORT
	DW	ROYAL		;ROYAL
	DW	CLAST_ON
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	SONGS		;VOICE
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB

TREZ_NOTE:
	CALL	GM_GETNTRZ
	LD	HL,GM_NBUF
	LD	(HL),3
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),A
	RET
;**********************************************

GAME_SEPT:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	BOUNUS_CLR
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	SEPT_NOTE	;MAKE
	DW	CLAST_SORT
	DW	ROYAL		;ROYAL
	DW	CLAST_ON
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	SONGS		;VOICE
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - -- 
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB

SEPT_NOTE:
	CALL	GM_GETNSPT
	LD	HL,GM_NBUF
	LD	(HL),4
	INC	HL
	LD	(HL),C
	INC	HL
	LD	(HL),B
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),D
	RET
;**********************************************

GAME_DICT:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	BOUNUS_CLR
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	GM_NMAKE	; сгенерировали последовательность
	DW	DICT_TMAKE
	DW	ROYAL		;ROYAL
	DW	DICT_ON
	DW	DICT_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	DICT_ON
	DW	DICT_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	SONGS		;VOICE
	DW	DICT_ON
	DW	DICT_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	FORT_NOP
	DW	DICT_ON
	DW	DICT_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB
;----------------------------------------------
DICT_TMAKE:
	LD	A,(GM_STAGE)
	CALL	GM_GETMTBL
	LD	DE,GM_TBUF
	LD	(DE),A
	INC	DE
	LD	BC,8
	LDIR
	XOR	A
	LD	(GM_TMR),A
	RET

;----------------------------------------------
; включение звука  
DICT_ON:
	LD	A,(GM_TMR)
	OR	A
	JR	Z,DION_0
	DEC	A
	LD	(GM_TMR),A
	JR	Z,DION_0
	POP	HL
	RET
DION_0:
	LD	A,(GM_NOTE)
	LD	E,A
	LD	D,0
	LD	A,80H
	CALL	MIDIIN

        LD	A,DO
	LD	(GM_NBUF+1),A	; ПЕРВАЯ НОТА В ДИКТАНТЕ ВСЕГДА до

	LD	HL,GM_NBUF
	LD	B,(HL)
	INC	HL

	LD	A,(GM_PNTR)
	CP	B
	JR	NC,DICT_OFF
	LD	E,A
	LD	D,0
	INC	A
	LD	(GM_PNTR),A

	ADD	HL,DE
	LD	A,(HL)
	LD	(GM_NOTE),A
	LD	DE,9
	ADD	HL,DE
	LD	E,A
	LD	A,(HL)
	LD	(GM_TMR),A
	LD	D,7FH
	LD	A,90H
	CALL	MIDIIN		; воспроизвели ноту
	POP	HL
	RET

;----------------------------------------------
; выключение звука 
DICT_OFF:

	XOR	A
	LD	(GM_INPUT),A
	LD	(GM_PNTR),A
	LD	(GM_TMR),A
	RET

;----------------------------------------------
DICT_CHECK:
	CALL	DICH_0
	RET	NZ
	LD	A,(GM_NBUF)
	LD	B,A
	LD	A,(GM_INPUT)
	CP	B
	JP	NC,BOUNUS_INC
	POP	HL
	RET
;
DICT_CHECKNB:
	CALL	DICH_0
	RET	NZ
	LD	A,(GM_NBUF)
	LD	B,A
	LD	A,(GM_INPUT)
	CP	B
	JP	NC,STEPS_LOOP
	POP	HL
	RET
;
DICH_0:
	LD	A,(GM_INPUT)
	OR	A
	RET	Z
	LD	B,A
	LD	HL,GM_NBUF+1
	LD	DE,GM_INPUT+1
DICH_1:
	LD	A,(DE)
	CP	(HL)
	RET	NZ
	INC	HL
	INC	DE
	DJNZ	DICH_1
	RET


;**********************************************

GAME_CLAST:
	CALL	FORT
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	BOUNUS_CLR
	DW	PLAY_PROB
	DW	FORT_NOP
	DW	FORT_NOP
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	GM_NMAKE	; сгенерировали последовательность
	DW	CLAST_SORT
	DW	ROYAL		;ROYAL
	DW	CLAST_ON
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	PLAY_PROBR	;SPEAK
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECK	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	SONGS		;VOICE
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
;- - - - - - - - - - - - - - - - - - - - - - --
	DW	FORT_NOP
	DW	FORT_NOP
	DW	CLAST_ONPL
	DW	FORT_NOP
	DW	CLAST_OFF
	DW	CLAST_CHECKNB	;?
	DW	PLAY_BAD	;SPEAK
	DW	STEPS_LOOPB

;----------------------------------------------
; включение звука  
CLAST_ON:
	XOR	A
	LD	(GM_INPUT),A

	LD	HL,GM_NBUFSRT
	LD	B,(HL)
	INC	HL
CLAST_ON_L:
	LD	E,(HL)
	LD	D,7FH
	LD	A,90H
	CALL	MIDIIN		; воспроизвели ноту
	INC	HL
	DJNZ	CLAST_ON_L
	RET
;----------------------------------------------
; включение звука  
CLAST_ONPL:
	XOR	A
	LD	(GM_INPUT),A

	LD	HL,GM_NBUFSRT
	LD	B,(HL)
	INC	HL

	LD	A,(GM_PNTR)
	CP	B
	RET	NC
	LD	E,A
	LD	D,0
	INC	A
	LD	(GM_PNTR),A

	ADD	HL,DE
	LD	E,(HL)
	LD	D,7FH
	LD	A,90H
	CALL	MIDIIN		; воспроизвели ноту
	POP	HL
	RET
;----------------------------------------------
; выключение звука 
CLAST_OFF:
	XOR	A
	LD	(GM_PNTR),A

	LD	HL,GM_NBUFSRT
	LD	B,(HL)
	INC	HL

CLAST_OFF_L:
	LD	E,(HL)
	LD	D,7FH
	LD	A,80H
	CALL	MIDIIN		; воспроизвели ноту
	INC	HL
	DJNZ	CLAST_OFF_L
	RET
;----------------------------------------------
CLAST_CHECK:
	CALL	CLCH_0
	RET	C	; ошибка
	LD	HL,GM_NBUFSRT
	LD	C,(HL)
	CALL	WAIT_KEY	; INPUTNUM - NEEDNUM
	JP	NC,BOUNUS_INC ; нормальный выход
	POP	HL	; ожидание
	RET
;
; возвращ CF если обнаружена ошибка
CLCH_0:
	LD	HL,GM_INPUT
	LD	A,(HL)	; A= количество вввед,нных кодов
	OR	A
	RET	Z

	INC	HL
	EX	HL,DE	; DE буфер введ,нных кодов
	LD	HL,GM_NBUFSRT
	LD	B,A	; B= количество вввед,нных кодов
CLCH_1:
	LD	A,(DE)
	CALL	STR_SRCH
	RET	C
	INC	DE
	DJNZ	CLCH_1
	RET

CLAST_CHECKNB:
	CALL	CLCH_0
	RET	C
	LD	HL,GM_NBUFSRT
	LD	C,(HL)
	CALL	WAIT_KEY
	JP	NC,STEPS_LOOP
	POP	HL
	RET
;----------------------------------------------
CLAST_STAGE:
	LD	A,(GM_BOUNUS)	; 0 - 50
	LD	C,A
	LD	B,0
	LD	DE,10
	CALL	MOD16	; BC/DE
	LD	A,C	; 0 - 5
	ADD	2	; 2 - 7	количество нот
	LD	(GM_STAGE),A
	RET

;**********************************************
; ожидание ввода N клавиш
;IN	C	количество
;OUT	CF	1 недождались
WAIT_KEY:
	LD	A,(GM_INPUT)
	CP	C
	RET

;**********************************************
; IN	HL	строка в которой искать
; 	A	искомый байт
STR_SRCH:
	PUSH	HL
	PUSH	BC
	LD	B,(HL)
	INC	HL
STR_SRCH_L:
	CP	(HL)
	JR	Z,STR_SRCH_E
	INC	HL
	DJNZ	STR_SRCH_L
	SCF
	POP	BC
	POP	HL
	RET

STR_SRCH_E:
	POP	BC
	POP	HL
	RET

;**********************************************
; 	СОРТИРОВКА НОТОК
; 
CLAST_SORT:
	LD	HL,GM_NBUF
	LD	DE,GM_NBUFSRT

;**********************************************
; Сортировка строки
;IN	HL	строка источник
;	DE	строка приемник
STR_SORT:
	PUSH	DE
	INC	DE	
	LD	C,0	; счетчик
	LD	A,0FFH	; начальное максимальное число
STRSRT_L:
	CALL	STR_MAX
	OR	A
	JR	Z,STRSRT_EX
	LD	(DE),A
	INC	DE
	INC	C	; подсчет количества
	JR	STRSRT_L

STRSRT_EX:
	LD	A,C
	POP	DE
	LD	(DE),A
	RET

;**********************************************
; ПОИСК МАКСИМАЛЬНОГО БАЙТА В СТРОКЕ
; IN	A = MAX
;	HL  Строка
; OUT 	A = 0 ... D - 1 
STR_MAX:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	D,A
	LD	B,(HL)
	INC	HL
	LD	E,0
STRMAX_L:
	LD	A,(HL)
	CP	E
	JR	C,STRMAX_0
	CP	D
	JR	NC,STRMAX_0
	LD	E,A
STRMAX_0:
	INC	HL
	DJNZ	STRMAX_L
	LD	A,E
	POP	BC
	POP	DE
	POP	HL
	RET

;**********************************************
; Генерирут нотную последовательность
; в буффере GM_BUF
;**********************************************

GM_NMAKE:
	LD	IX,GM_NBUF	; нотный  буфер

	LD	A,(GM_METR)
	OR	A
	JR	NZ,METR_3X	; МЕТР 3 дольный
;----------------------------------------------
; 2 дольный
	LD	(IX),5

	LD	A,(GM_ZVUK)
	OR	A
	JR	Z,NAT_2X	; натуральный звукоряд

	LD	A,0
	CALL	GM_GETN	; A= nota
	LD	(IX+1),A

	LD	A,1
	CALL	GM_GETN	; A= nota
	LD	(IX+2),A

	LD	A,2
	CALL	GM_GETN2 ; BC= nota
	LD	(IX+3),C
	LD	(IX+4),B

	LD	A,3
	CALL	GM_GETN	; A= nota
	LD	(IX+5),A
	RET
;----------------------------------------------
NAT_2X:
	LD	A,0
	CALL	GM_GETN	; A= nota
	LD	(IX+1),A

	LD	A,1
	CALL	GM_GETN	; A= nota
	LD	(IX+2),A

	LD	A,2
	CALL	GM_GETN ; A= nota
	LD	(IX+3),A

	LD	A,3
	CALL	GM_GETN ; A= nota
	LD	(IX+4),A

	LD	A,4
	CALL	GM_GETN ; A= nota
	LD	(IX+5),A
	RET
;----------------------------------------------

METR_3X:
	LD	(IX),7

	LD	A,(GM_ZVUK)
	OR	A
	JR	Z,NAT_3X	; натуральный звукоряд

	LD	A,0
	CALL	GM_GETN ; A= nota
	LD	(IX+1),A

	LD	A,1
	CALL	GM_GETN	; A= nota
	LD	(IX+2),A

	LD	A,2
	CALL	GM_GETN2 ; BC= nota
	LD	(IX+3),C
	LD	(IX+4),B

	LD	A,3
	CALL	GM_GETN2 ; BC= nota
	LD	(IX+5),C
	LD	(IX+6),B

	LD	A,4
	CALL	GM_GETN	; A= nota
	LD	(IX+7),A
	RET
;----------------------------------------------
NAT_3X:
	LD	A,0
	CALL	GM_GETN ; A= nota
	LD	(IX+1),A

	LD	A,1
	CALL	GM_GETN	; A= nota
	LD	(IX+2),A

	LD	A,2
	CALL	GM_GETN	; A= nota
	LD	(IX+3),A

	LD	A,3
	CALL	GM_GETN	; A= nota
	LD	(IX+4),A

	LD	A,4
	CALL	GM_GETN	; A= nota
	LD	(IX+5),A

	LD	A,5
	CALL	GM_GETN	; A= nota
	LD	(IX+6),A

	LD	A,6
	CALL	GM_GETN	; A= nota
	LD	(IX+7),A
	RET

;**********************************************
; Возвращаем 1 ноту из строки случаино
;IN	A	номер строки
;OUT	ADE	3 ноты
;**********************************************

GM_GETNTRZ:
	PUSH	HL
	PUSH	BC
	LD	HL,TREZ_TBL
	LD	A,(HL)		; A = число записей в таблице
	INC	HL		; ^HL = начало строки без размера
	CALL	RND_X
	LD	D,3
	LD	E,A
	MLT	DE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	POP	BC
	POP	HL
	RET

GM_GETNSPT:
	PUSH	HL
	LD	HL,SEPT_TBL
	LD	A,(HL)		; A = число записей
	INC	HL		; ^HL = начало строки без размера
	CALL	RND_X
	LD	D,4
	LD	E,A
	MLT	DE
	ADD	HL,DE
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	POP	HL
	RET

;**********************************************
; Возвращаем 1 ноту из строки случаино
;IN	A	номер строки
;OUT	A	нота
;**********************************************

GM_GETN:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	GM_2LINE
	LD	A,(HL)		; DE = число байт в таблице
	INC	HL		; ^HL = начало строки без размера
	CALL	RND_X
	LD	D,0
	LD	E,A
	ADD	HL,DE
	LD	A,(HL)
	POP	BC
	POP	DE
	POP	HL
	RET

;**********************************************
; Возвращаем 2 ноты из строки случаино
;IN	A	номер строки
;OUT	BC	ноты
;**********************************************

GM_GETN2:
	PUSH	HL
	PUSH	DE
	CALL	GM_2LINE
	LD	A,(HL)		; DE = число байт в таблице
	INC	HL		; ^HL = начало строки без размера
	CALL	RND_X
	RES	0,A
	LD	D,0
	LD	E,A
	ADD	HL,DE
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	POP	DE
	POP	HL
	RET

;**********************************************
; Позиционируется на строку сномером у текущего лада
;IN	A	номер строки
;**********************************************

GM_2LINE:
	INC	A
	LD	B,A
	CALL	GM_GETL		; ^HL = таблица лада
	JR	GM_2LINE_0

GM_2LINE_L:
	LD	D,0
	LD	E,(HL)
	INC	HL
	ADD	HL,DE
GM_2LINE_0:
	DJNZ	GM_2LINE_L
	RET
;**********************************************
; Возвращает поинтер на таблицу лада
;OUT	HL	указатель на таблицу
;**********************************************

GM_GETL:
	LD	A,(GM_ZVUK)
	OR	A
	JR	Z,GM_GETL_NAT	; натуральный звукоряд

	LD	A,(GM_METR)
	OR	A
	JR	NZ,GM_GETL_A3	; альтер 3 дольный

	LD	A,(GM_LAD)
	LD	HL,LAD_MAGA
	OR	A
	RET	Z
	LD	HL,LAD_MINA
	DEC	A
	RET	Z
	LD	HL,LAD_LOWA
	DEC	A
	RET	Z
	LD	HL,LAD_BIGA
	RET
GM_GETL_A3:
	LD	A,(GM_LAD)
	LD	HL,LAD_MAGA3
	OR	A
	RET	Z
	LD	HL,LAD_MINA3
	DEC	A
	RET	Z
	LD	HL,LAD_LOWA3
	DEC	A
	RET	Z
	LD	HL,LAD_BIGA3
	RET

GM_GETL_NAT:
	LD	A,(GM_METR)
	OR	A
	JR	NZ,GM_GETL_N3	; натур 3 дольный

	LD	A,(GM_LAD)
	LD	HL,LAD_MAG
	OR	A
	RET	Z
	LD	HL,LAD_MIN
	DEC	A
	RET	Z
	LD	HL,LAD_LOW
	DEC	A
	RET	Z
	LD	HL,LAD_BIG
	RET

GM_GETL_N3:
	LD	A,(GM_LAD)
	LD	HL,LAD_MAG3
	OR	A
	RET	Z
	LD	HL,LAD_MIN3
	DEC	A
	RET	Z
	LD	HL,LAD_LOW3
	DEC	A
	RET	Z
	LD	HL,LAD_BIG3
	RET

;**********************************************
; Возвращает указатель на таблицу метра 
;IN	A	ВЕРСИЯ
;OUT	HL	POINTER
;**********************************************
GM_GETMTBL:
	LD	E,A
	LD	A,(GM_METR)
	OR	A
	JR	NZ,MT_0
	LD	HL,TIME_2X
	LD	D,5
	MLT	DE
	ADD	HL,DE
	LD	A,5
	RET

MT_0:
	LD	HL,TIME_3X
	LD	D,7
	MLT	DE
	ADD	HL,DE
	LD	A,7
	RET

;**********************************************
; 
;**********************************************
LJ:	EQU	57
LO:	EQU	56
SO:	EQU	55
ZU:	EQU	54
FA:	EQU	53
MI:	EQU	52
MO:	EQU	51
REE:	EQU	50
TU:	EQU	49
DO:	EQU	48
SI0:	EQU	47
CU0:	EQU	46
LJ0:	EQU	45
LO0:	EQU	44
SO0:	EQU	43
ZU0:	EQU	42	
FA0:	EQU	41

LAD_MAG:
	DB	2, DO,MI
	DB	9, SO0,LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB	8, SO0,LJ0,SI0,REE,MI,FA,SO,LJ
	DB	6, SO0,LJ0,SI0,REE,MI,SO
	DB	3, DO,MI,SO
LAD_MAGA:
	DB	2, DO,MI
	DB	9, SO0,LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB     26, SO0,TU,LO0,SO0,LJ0,TU,CU0,SI0,SI0,TU,TU,SI0
	DB	   REE,TU,MO,MI,MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB	1, DO
LAD_MAG3:
	DB	2, DO,MI
	DB	9, SO0,LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB	5, SO0,LJ0,SI0,REE,SO
	DB	9, SO0,LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB	8, LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB	6, SO0,LJ0,SI0,REE,MI,SO
LAD_MAGA3:
	DB	2, DO,MI
	DB	9, SO0,LJ0,SI0,DO,REE,MI,FA,SO,LJ
	DB     24, SO0,TU,LO0,SO0,CU0,SI0,SI0,TU,TU,SI0
	DB	   REE,TU,MO,MI,MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB     22, LO0,SO0,CU0,SI0,SI0,TU,TU,SI0
	DB	   REE,TU,MO,MI,MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB	1, DO
;----------------------------------------------
LAD_MIN:
	DB	2, DO,MO
	DB	9, SO0,LO0,CU0,DO,REE,MO,FA,SO,LO
	DB	8, SO0,LO0,CU0,REE,MO,FA,SO,LO
	DB	6, SO0,CU0,SI0,REE,MO,SO
	DB	1, DO
LAD_MINA:
	DB	2, DO,MO
	DB	8, SO0,LJ0,SI0,REE,MO,FA,SO,LO
	DB     26, SO0,TU,LO0,SO0,LJ0,SI0,CU0,SI0,SI0,TU,TU,SI0,REE,TU,MO,MI
	DB	   MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB	1, DO
LAD_MIN3:
	DB	2, DO,MO
	DB	9, SO0,LO0,CU0,DO,REE,MO,FA,SO,LO
	DB	8, SO0,LO0,CU0,REE,MO,FA,SO,LO
	DB	6, LO0,CU0,DO,REE,FA,LO
	DB	8, SO0,LO0,CU0,REE,MO,FA,SO,LO
	DB	6, SO0,CU0,SI0,REE,MO,SO
	DB	1, DO
LAD_MINA3:
	DB	2, DO,MO
	DB	8, SO0,LJ0,SI0,REE,MO,FA,SO,LO
	DB     24, SO0,TU,LO0,SO0,LJ0,SI0,CU0,SI0,SI0,TU,REE,TU,MO,MI
	DB	   MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB     22, LO0,SO0,LJ0,SI0,CU0,SI0,SI0,TU,TU,SI0,REE,TU
	DB	   MI,TU,FA,TU,ZU,SO,SO,TU,LO,SO
	DB	1, DO
;----------------------------------------------
LAD_LOW:
	DB	1, DO
	DB	8, LO0,LJ0,SI0,DO,REE,MO,FA,LO
	DB	9, ZU0,LO0,LJ0,SI0,REE,MO,FA,ZU,LO
	DB	6, ZU0,LJ0,SI0,REE,MO,ZU
	DB	1, DO
LAD_LOWA:
	DB	1, DO
	DB	9, ZU0,LO0,LJ0,SI0,REE,MO,FA,ZU,LO
	DB	24,SO0,LO0,LO0,REE,LJ0,SI0,CU0,SI0,SI0,TU
	DB	   TU,SI0,REE,TU,MO,SI0,MI,MO,FA,TU,ZU,SI0,SO,TU
	DB	1, DO
LAD_LOW3:
	DB	1, DO
	DB	8, LO0,LJ0,SI0,DO,REE,MO,FA,LO
	DB	9, ZU0,LO0,LJ0,SI0,REE,MO,FA,ZU,LO
	DB	10,ZU0,LO0,LJ0,SI0,DO,REE,MO,FA,ZU,LO
	DB	9, ZU0,LO0,LJ0,SI0,REE,MO,FA,ZU,LO
	DB	6, ZU0,LJ0,SI0,REE,MO,ZU
	DB	1, DO

LAD_LOWA3:
	DB	1, DO
	DB	9, ZU0,LO0,LJ0,SI0,REE,MO,FA,ZU,LO
	DB	20,SO0,LO0,LO0,REE,LJ0,SI0,CU0,SI0,SI0,TU
	DB	   TU,SI0,REE,TU,MI,MO,FA,TU,SO,ZU
	DB	16,SO0,ZU0,CU0,SI0,SI0,TU
	DB	   TU,SI0,REE,TU,MI,MO,FA,TU,SO,TU
	DB	1, DO
;----------------------------------------------
LAD_BIG:
	DB	1, DO
	DB	7, LO0,CU0,DO,REE,MI,ZU,LO
	DB	6, LO0,CU0,REE,MI,ZU,LO
	DB	5, LO0,CU0,REE,MI,LO
	DB	1, DO
LAD_BIGA:
	DB	1, DO
	DB	7, LO0,CU0,DO,REE,MI,ZU,LO
	DB	20,LO0,TU,LJ0,LO0,CU0,SI0,REE,TU,MO,MI,MI,TU,FA,ZU
	DB	   ZU,TU,SO,LO,LO,SI0,LJ,TU
	DB	1, DO
LAD_BIG3:
	DB	1, DO
	DB	7, LO0,CU0,DO,REE,MI,ZU,LO
	DB	6, LO0,CU0,REE,MI,ZU,LO
	DB	6, CU0,DO,REE,MI,ZU
	DB	7, LO0,CU0,DO,REE,MI,ZU,LO
	DB	5, LO0,CU0,REE,MI,LO
	DB	1, DO
LAD_BIGA3:
	DB	1, DO
	DB	7, LO0,CU0,DO,REE,MI,ZU,LO
	DB	20,LO0,TU,LJ0,LO0,CU0,SI0,REE,TU,MO,MI,MI,SI0
	DB	   FA,ZU,SO,LO,LO,SI0,LJ,TU
	DB	22,LO0,TU,LJ0,LO0,CU0,SI0,REE,TU,MO,MI,MI,TU
	DB	   FA,ZU,ZU,TU,SO,SI0,LO,SI0,LJ,TU
	DB	1, DO

;----------------------------------------------
TIME_2X:
	DB	2,2,1,1,2
	DB	2,1,1,2,2
	DB	1,1,2,2,2
	DB	1,2,2,2,1
	DB	1,2,1,2,2
	DB	3,1,2,1,1
	DB	3,1,1,1,2

TIME_3X:
	DB	2,1,3,1,1,1,3
	DB	2,1,1,1,1,3,3
	DB	1,1,1,3,2,1,3
	DB	1,2,1,2,1,3,2
	DB	1,3,1,1,1,3,2
	DB	1,1,3,2,1,3,1
	DB	1,1,2,1,2,1,4

X0:	EQU	48
X1:	EQU	X0+1
X2:	EQU	X0+2
X3:	EQU	X0+3
X4:	EQU	X0+4
X5:	EQU	X0+5
X6:	EQU	X0+6
X7:	EQU	X0+7
X8:	EQU	X0+8
X9:	EQU	X0+9
XA:	EQU	X0+10
XB:	EQU	X0+10

Y1:	EQU	X0-1
Y2:	EQU	X0-2
Y3:	EQU	X0-3
Y4:	EQU	X0-4
Y5:	EQU	X0-5
Y6:	EQU	X0-6
Y7:	EQU	X0-7
Y8:	EQU	X0-8
Y9:	EQU	X0-9
YA:	EQU	X0-10
YB:	EQU	X0-11

TREZ_TBL:
	DB	20	; количество записей 1 запись = 3 байта
	DB	48,51,54,48,51,55,48,52,55,48,52,56	; +
	DB	48,45,42,48,45,41,48,44,41,48,44,40	; -
	DB	48,51,56,48,51,57,48,52,57		; +
	DB	48,45,40,48,45,39,48,44,39		; -
	DB	48,53,56,48,53,57,48,54,57		; +
	DB	48,43,40,48,43,39,48,42,39		; -
;
SEPT_TBL:
	DB	4 + 3 + 3 + 4 + 4 + 4 + 4 + 4 + 4 + 3 + 3 + 4
	DB	X0,X3,X6,X9,X0,X3,X6,XA,X0,X3,X7,XA,X0,X3,X7,XB	; +
	DB	X0,X4,X7,XA,X0,X4,X7,XB,X0,X4,X8,XB		; +
	DB	X0,Y4,Y7,YA,X0,Y4,Y7,YB,X0,Y4,Y8,YB		; -
	DB	X0,Y3,Y6,Y9,X0,Y3,Y6,YA,X0,Y3,Y7,YA,X0,Y3,Y7,YB ; -

	DB	X0,X1,X4,X7,X0,X1,X4,X8,X0,X1,X5,X8,X0,X1,X5,X9	; +
	DB	X0,X2,X5,X8,X0,X2,X5,X9,X0,X2,X6,X9,X0,X2,X6,XA	; +
	DB	X0,Y2,Y5,Y8,X0,Y2,Y5,Y9,X0,Y2,Y6,Y9,X0,Y2,Y6,YA	; -
	DB	X0,Y1,Y4,Y7,X0,Y1,Y4,Y8,X0,Y1,Y5,Y8,X0,Y1,Y5,Y9	; -

	DB	X0,X3,X4,X8,X0,X3,X5,X8,X0,X3,X5,X9,X0,X4,X5,X8	; +
	DB	X0,X4,X5,X9,X0,X4,X6,X9,X0,X4,X6,XA		; +
	DB	X0,Y4,Y5,Y9,X0,Y4,Y6,Y9,X0,Y4,Y6,YA		; -
	DB	X0,Y3,Y4,Y8,X0,Y3,Y5,Y8,X0,Y3,Y5,Y9,X0,Y4,Y5,Y8	; -



