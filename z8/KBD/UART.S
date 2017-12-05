; SERIAL
; HEADER
; *******************************************************************
;OUTPUT	INDATA,INDATA1	ВХОДНЫЕ ДАННЫЕ	 
;INPUT 	BCNT		КОЛИЧЕСТВО БАЙТ
; *******************************************************************
; PORT 3:       BIT 7 = SERIAL OUT

RG_SCC	EQU	0	; РЕГИСТРЫ КОМ ПОРТА

BITCOUNT	EQU	R12	; СЧЕТЧИК БИТ
BITCOUNTM	EQU	12	; СЧЕТЧИК БИТ
TXDATA	EQU   	R13	; ПРЕРЕДАВАЕМЫЕ ДАННЫЕ
TXDATA1	EQU	R14	; ПРЕРЕДАВАЕМЫЕ ДАННЫЕ	
TXDATA2	EQU	R15	; ПРЕРЕДАВАЕМЫЕ ДАННЫЕ
;
; *******************************************************************
; ИНИЦИАЛИЗАЦИЯ ПЕРЕДАТЧИКА
; *******************************************************************
	SCOPE
SER_INIT:
;	SERIAL BAUDRATE, USE T0 FOR TIMING
; -------------------------------------------------------------------
	DI
; -------------------------------------------------------------------
;	LD	T0,#104	; BAUD RATE = 4800
;	LD	PRE0,#00010001B ; PRESCALER VALUE 4
; -------------------------------------------------------------------
	LD	T0,#160	; BAUD RATE = 3125 (KDIV = 2560)
	LD	PRE0,#00010001B ; PRESCALER VALUE 4 (FOR K DIV 2560)
; -------------------------------------------------------------------
	OR	TMR,#%03	; LOAD + ENABLE T0

	OR	IMR,#00010000B ;T0 INTERRUPT ON
	AND	IRQ,#11101111B ;T0 IRQ RESET

	OR	P3,#80H	; УСТАНОВИЛИ TXT В 1
; РЕГИСТРЫ КОМ ПОРТА
; -------------------------------------------------------------------
	CLR	BITCOUNT
	CLR	TXDATA
	CLR	TXDATA1
	CLR	TXDATA2
	RET
	
; *******************************************************************
; INPUT	R4 R5 	БАЙТЫ
; OUTPUT	CF	ERROR
; *******************************************************************
	SCOPE
SEND_2BYTE:
$LOOP:
	CP	BITCOUNTM,#0
	JR	NZ,$LOOP

	LD	R3,#0FFH
	RCF
	RLC	R2
	RLC	R3	; СТАРТ БИТ 2
	SCF
	RLC	R2
	RLC	R3	; СТОП БИТ 1
	RCF
	RLC	R1
	RLC	R2
	RLC	R3	; СТАРТ БИТ 1
	SCF
	RLC	R1
	RLC	R2
	RLC	R3	; ЗАЩИТНЫЙ БИТ

	LD	13+RG_SCC,R1
	LD	14+RG_SCC,R2
	LD	15+RG_SCC,R3
	LD	12+RG_SCC,#21 ; "1"+STR+BYTE+STP+STR+BYTE+STP	
	RCF
	RET
; *******************************************************************
;	TRANSMIT T0 INTERRUPT HANDLER
;	FOR  BIT GENERATION TO P3,7
; *******************************************************************
	SCOPE
T0_INT:
	IF	TEST		;<<<<<<<<<<<<<<<<<
		AND	P1,#7FH	;<<<<<<<<<<<<<<<<<
	ENDIF			;<<<<<<<<<<<<<<<<<

	PUSH	RP
	LD	RP,#RG_SCC
	CP	BITCOUNT,#0
	JR	Z,$NEXT2	; БИТОВ НЕТ /10-12/
	RRC	TXDATA2		; /6/
	RRC	TXDATA1		; /6/
	RRC	TXDATA		; /6/ SHIFT BIT
	JR	C,$SER_O_1	; /10-12/ BIT = 1
	AND	R3,#%7F		; /6/ BIT = 0 
	JR	$NEXT		; /10/
$SER_O_1:
	OR	R3,#%80		; BIT = 1 /6/
	JR	$NEXT		; ВЫРАВНИВАНИЕ ПО СКОРОСТИ /10/
$NEXT:
	DEC	BITCOUNT	; BIT CNT DOWN /6/
	CALL	ADC3		; ИЗМЕРЕНИЕ НАПРЯЖЕНИЙ
	CALL	SCANER		; СКАНИРОВАНИЕ КЛАВИАТУРЫ
	POP	RP

	IF	TEST		;<<<<<<<<<<<<<<<
		OR	P1,#80H	;<<<<<<<<<<<<<<<
	ENDIF			;<<<<<<<<<<<<<<<

	IRET
$NEXT2:
	NOP			; ВЫРАВНИВАНИЕ 48 ТАКТОВ
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CALL	ADC3		; ИЗМЕРЕНИЕ НАПРЯЖЕНИЙ
	CALL	SCANER		; СКАНИРОВАНИЕ КЛАВИАТУРЫ
	POP	RP

	IF	TEST
		OR	P1,#80H		;<<<<<<<<<<<<<<<
	ENDIF

	IRET

