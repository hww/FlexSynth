	SECTION	MCODE

	PHASE	100H
START:	
	LD	A,0FFH
	OUT	(0A8H),A	;SLOTS 3333
	CALL	XCHANGE
	RET

;**********************************************
; Загрузка прграммы обмена
;**********************************************
XCHANGE:
	LD	A,1
	LD	HL,4000H
	CALL	024H		; SET  SLT1 -> 4000H

	LD	IX,4000H
	LD	(IX+10H),0	; RESET
;----------------------------------------------
	IF TEST
	LD	HL,FTEST
	LD	DE,4000H
	LD	BC,16
	LDIR
	LD	(IX+10H),8 ; START TEST

        LD	A,0
LOOP_TEST:
	LD	(IX+15),A
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CP	(IX+14)
        JP	Z,OK_TEST
        PUSH	AF
	LD	A,(IX+14)
	CALL	PUTHEX
	LD	A,'R'
	CALL	PUTCHR
	LD	A,'W'
	CALL	PUTCHR
	POP	AF
	CALL	PUTHEX
	JP	OK_TEST

	INCLUDE	mutil.lib

OK_TEST:
	INC	A
	JP	NZ,LOOP_TEST
	LD	(IX+10H),0 ; STOP TEST
	ENDIF
;----------------------------------------------
	LD	HL,FINIT
	LD	DE,4000H
	LD	BC,16
	LDIR
	LD	(IX+10H),8 ; START INIT

;----------------------------------------------

	LD	HL,FINIT1
	LD	DE,4000H
	LD	BC,15
	LDIR
	LD	(IX+10H),9 ; NMI=0
	LD	(IX+10H),8 ; NMI=1

;----------------------------------------------

	LD	HL,FINIT2
	LD	DE,4000H
	LD	BC,15
	LDIR
	LD	(IX+10H),9 ; NMI=0
	LD	(IX+10H),8 ; NMI=1

;----------------------------------------------
	LD	HL,SEND
	LD	DE,4000H
	LD	BC,15
	LDIR
	LD	HL,XBIOS_B
	LD	DE,3800H
LOOP:
	LD	A,(HL)
	XOR	80H
	LD	(IX+0),A
	XOR	80H
	LD	(IX+7),A ; DATA

	LD	(IX+10H),9 ; NMI=0
	LD	(IX+10H),8 ; NMI=1

WAITING:
	CP	(IX+0)
	JR	NZ,WAITING

	INC	HL
	DEC	DE
	LD	A,E
	OR	D
	JR	NZ,LOOP

;----------------------------------------------

	LD	HL,GO
	LD	DE,4000H
	LD	BC,15
	LDIR
	LD	(IX+10H),9 ; NMI=0 START
	LD	(IX+10H),8 ; NMI=1
	LD	HL,4000H
	LD	A,3
	CALL	024H	; RESTORE SLT 3
	RET

;**********************************************
	IF 	TEST
FTEST:
	LD	A,(15)		;0,1,2
	LD	(14),A		;3,4,5
	JP	0		;6,7,8 
	DB	0		;9
	DB	0,0 		;10,11
	DB	0,0		;12,13
	NOP			;14
	NOP			;15
        ENDIF
;**********************************************
FINIT:
	LD	SP,0FFFFH	;0,1,2
	LD	BC,40H		;3,4,5
	LD	A,0CH		;6,7 /RAM0,RAM1 ON/
	OUT	(C),A		;8,9
	LD	A,84H 		;10,11 /0000-4000-8000/
	LD	C,CBAR		;12,13
	NOP			;14
	HALT			;15

;**********************************************
FINIT1:
	DEFB	0,0,0,0,0,0
	OUT	(C),A 		;6,7 /0000-4000-8000/
	LD	C,CBR		;8,9
	LD	A,0F0H		;10,11 /F0XXX+8000=F800
	OUT	(C),A		;12,13
	POP	DE			;14
	HALT			;15

;**********************************************
FINIT2:
	DEFB	0,0,0,0,0,0
	LD	HL,8000H 	;6,7,8 /RAM START/
	LD	A,(4006)	;9,10,11
	LD	(0),A		;12,13,14
	HALT
;**********************************************
SEND:
	DEFB	0,0,0,0,0,0
	LD	A,0	; 6,7
	LD	(HL),A	; 8
	LD	A,(HL)	; 9
	INC	HL	; 10
	LD	(0),A	; 11,12,13
	POP	DE	; 14 убили адрес возврата
	HALT		; 15
;**********************************************
GO:	
	DEFB	0,0,0,0,0,0
	JP	8000H
	DEFB	0,0,0,0,0,0 ; 9,10,11,12,13,14
;**********************************************

	INCLUDE	MXACCES.LIB

	DB	"ENDMCODE"

XBIOS_B: