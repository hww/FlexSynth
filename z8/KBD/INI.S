; MAIN
; HEADER
; *******************************************************************
;	ПРОГРАММА МУЗЫКАЛЬНОЙ КЛАВИАТУРЫ
; *******************************************************************

	DEFINE	IDATA , SPACE = RFILE , ORG = 0H
	DEFINE	ICODE , SPACE = ROM , ORG = 0H

; *******************************************************************
;	НАЧАЛО ПАМЯТИ ПРОГРАММ ВЕКТОРЫ ПРЕРЫВАНИЙ	 
; *******************************************************************

	SEGMENT	ICODE
	ORG	0000H
	DW	DUMMY	;P3.2 (НЕ ИСПОЛЬЗУЕТСЯ)
	DW	DUMMY	;P3.3 REF (НЕ ИСПОЛЬЗУЕТСЯ)
	DW	DUMMY	;P3.1 ПРЕРЫВАНИЕ ОТ ADC (НЕ ИСПОЛЬЗУЕТСЯ)
	DW	INT3	;P3.0 ГОТОВНОСТЬ ПРИЕМНИКА (НЕ ИСПОЛЬЗУЕТСЯ)
	DW	T0_INT	;T0 ПЕРЕДАТЧИК 
	DW	DUMMY	;T1 (НЕ ИСПОЛЬЗУЕТСЯ)
; *******************************************************************
	ORG	%0C
; *******************************************************************
;	РЕГИСТРЫ ПРОЦЕССОВ
RG_SCC	EQU	%0
RG_MAIN	EQU	%10
; *******************************************************************
;	СТЕК ПРОЦЕССОВ
;
SP_MAIN	EQU	%EF
; *******************************************************************
;	НАЧАЛО ПРОГРАММЫ
; *******************************************************************
START:
	DI
; *******************************************************************
; ОСНОВНАЯ ИНИЦИАЛИЗАЦИЯ
; *******************************************************************
	LD	RP,#0FH
	LD	0BH,#2	; CLK=XTAL
	LD	RP,#0H
; -------------------------------------------------------------------
	LD	IPR,#1	;INT. PRIORITY
; -------------------------------------------------------------------
; ИНИЦИАЛИЗАЦИЯ ПОРТОВ  ПРОЦЕССОРА
	LD	P01M,#01000101B ;P0-INPUT, P1-OUTPUT, INTERNAL STACK
	LD	P2M, #10000000B ;P2.7-INPUT OTHER-OUTPUT
	LD	P3M, #00000011B ;P3-ANALOG MODE P2-OPEN DRAIN
	LD	P1,#07FH	; RESET = 0
	LD	P2,#0FFH
	NOP			;ФОРМИРУЕМ СИГНАЛ RESET
	NOP
	NOP
	NOP
	NOP
	OR	P1,#80H		;RESET= 1
; -------------------------------------------------------------------
	LD	RP,#RG_SCC	; НАБОР ПРЕРЫВАНИЙ
	CLR	SPH
	LD	SPL,#SP_MAIN 	;СТЕК ПРОГРАММ
	CALL	MAININIT
	LD	RP,#RG_MAIN
DIE:
	EI			;ОСНОВНОЙ ЦИКЛ ПРОЦЕССОРА
	CALL	SRCH2SEND
	JR	DIE
; *******************************************************************
;	ПРОСТО ВЫХОД ИЗПРЕРЫВАНИЯ
; *******************************************************************
DUMMY:	IRET
; *******************************************************************
;ИНИЦИАЛИЗАЦИЯ ВНУТРЕННИХ ПОДПРОГРАММ
; *******************************************************************
MAININIT:
	DI
	SCOPE
	CALL	SER_INIT
	CALL	ADC3_INIT
	CALL	SCANER_INIT
	RET
; *******************************************************************
; *******************************************************************
