;**********************************************
;	����� � ���
;**********************************************

	SECTION	ICODE

PRG_CRC:
	LD	A,0
	LD	HL,0
	CALL	ROM_CRC
	PUSH	BC
	LD	A,0
	LD	HL,4000H
	CALL	ROM_CRC
	POP	HL
	ADD	HL,BC
	RET

;**********************************************
; ����஫쭠� �㬬� �����
;INP	A	Hight Adres
;INP	HL	Adres
;OUT	BC	CRC
;**********************************************
ROM_CRC:
	PUSH	HL
	PUSH	DE
	CALL	ROM_ENA
	LD	HL,4000H
	LD	DE,4000H
	LD	BC,0
ROM_CRC_0:
	LD	A,(HL)
	ADD	C
	LD	C,A
	LD	A,(HL)
	ADC	B
	LD	B,A

	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,ROM_CRC_0
	POP	DE
	POP	HL
	RET

;**********************************************
;	������祭�� ��� 
;INP	A	Hight Adres
;INP	HL	Adres
;OUT	A	Page
;	HL	Adres in Page
;**********************************************
ROM_ENA:
	AND	0FH	; ����訥 64 �� ?

	CALL	ROM_CALC	; RET A=PAGE HL=ADRES

	OUT0	(BBR),A	; new page
	RET

;**********************************************
;	�⥭�� ��� 
;INP	A	Hight Adres
;INP	HL	Adres
;OUT	A	Data
;**********************************************
ROM_RD:
	AND	0FH	; ����訥 64 �� ?

	PUSH	DE
	PUSH	HL

	CALL	ROM_CALC	; RET A=PAGE HL=ADRES

	IN0	D,(BBR)	; old page
	OUT0	(BBR),A	; new page
	LD	A,(HL)
	OUT0	(BBR),D	; restore page

	POP	HL
	POP	DE
	RET

;**********************************************
;	�⥭�� ��� � DSP
;INP	A	Hight Adres SRC
;INP	HL	Adres SRC
;INP	DE	Size
; ⮫쪮 �� ����� ���� 64 ��
;**********************************************
ROM_DSPRD:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC

	AND	0FH	; ����訥 64 �� ?

	CALL	ROM_CALC ; A=��࠭�� HL=���� � ��࠭��
	IN0	C,(BBR)	; ���� ��࠭��

ROM_DSPLOP:
	OUT0	(BBR),A	; ��⠭���� �����

	EX	DE,HL	; HL=�����  DE=���筨�
	PUSH	HL	; (SP)=�����
	LD	HL,8000H
	OR	A
	SBC	HL,DE	; 8000H - ���筨� = �� ���� ��࠭��� (�३�)
	EX	DE,HL	; HL=���筨� DE=�३�
	EX	(SP),HL	; HL=����� (SP)=���筨�
	OR	A
	SBC	HL,DE	; ����� - �३� = ���⮪
	JR	C,ROM_LAST

	EX	(SP),HL	; HL=���筨� (SP)=���⮪ ������ DE=�३� 
	CALL	DSP_LDIR
	LD	HL,4000H ; ���� ���筨�
	ADD	4	; ᫥����� ��࠭��
	POP	DE	; DE=���⮪ ������
	JR	ROM_DSPLOP

ROM_LAST:
	ADD	HL,DE
	EX	DE,HL	; DE=�����
	POP	HL	; HL=���筨�
	CALL	DSP_LDIR

	OUT0	(BBR),C	; restore page
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	RET
;**********************************************
;	�⥭�� ��� � RAM
;INP	A	Hight Adres SRC
;INP	HL	Adres SRC
;INP	DE	Adres DST
;INP	BC	Size BLK
; ⮫쪮 �� ����� ���� 64 ��
;**********************************************
ROM_RAMRD:
	CALL	DMA_LDIR
	RET
;**********************************************
; ���᫥��� ��࠭��� ���
;IN	AHL	ADRES
;OUT	A	PAGE
;OUT	HL	ADRES IN PAGE
;**********************************************
ROM_CALC:
	DI
	PUSH	HL	;A=0000 HHHH, H=ABXX XXXX
	RL	H
	RLA		;A=000H HHHA, H=BXXX XXXX
	RL	H
	RLA		;A=00HH HHAB
	ADD	A
	ADD	A	;A=HHHH AB00
	POP	HL
	SET	6,H
	RES	7,H	;+X4XXXH
	SUB	04H	;-X4XXXH
	RET

;**********************************************
;	������ �� FALSH ������
;INP	CF=1	Check Writes
;INP	A	Hight Adres
;INP	E	data
;INP	HL	Adres
;**********************************************
ROM_WR:
	JR	C,ROM_WRCHK

	PUSH	AF
	PUSH	HL
	PUSH	DE

	AND	0FH	; ����訥 64 �� ?

	CALL	ROM_CALC

	IN0	D,(BBR)	; old page
	OUT0	(BBR),A	; new page
	LD	(HL),E

	OUT0	(BBR),D	; restore page
	POP	DE
	POP	HL
	POP	AF
	RET

ROM_WRCHK:
	PUSH	AF
	PUSH	HL
	PUSH	DE

	AND	0FH

	CALL	ROM_CALC

	IN0	D,(BBR)	; old page
	OUT0	(BBR),A	; new page
	LD	(HL),E

ROM_WRCHKL:
	LD	A,(HL)
	CP	E
	JR	Z,RWR_OK

	BIT	5,A	; TIME OUT
	JR	Z,ROM_WRCHKL

	OUT0	(BBR),D	; restore page
	POP	DE
	POP	HL
	POP	AF
	SCF
	RET

RWR_OK:
	OUT0	(BBR),D	; restore page
	POP	DE
	POP	HL
	POP	AF
	OR	A
	RET


;**********************************************
; ����������������  ����
;INP	A	Hight Adres
;INP	E	data
;INP	HL	Adres
;**********************************************

FPR:	MACRO	ADR,DAT
	LD	A,DAT
	LD	(ADR),A
	ENDM


FLASH_PRG:
	IF	RAM

	DI
	PUSH	AF
	PUSH	DE
	IN0	D,(BBR)
	XOR	A
	OUT0	(BBR),A

	FPR	5555H,0AAH
	FPR	2AAAH,055H
	FPR	5555H,0A0H

	OUT0	(BBR),D
	POP	DE
	POP	AF
	SCF		; �஢�ઠ �����
	CALL	ROM_WR

	ENDIF

	RET
;**********************************************
; ������� ������� ����
;INP	A	Hight Adres (SECTOR ADRES)
;	HL	Low Adres
;**********************************************
FLASH_SCLR:
	IF	RAM

	DI
	PUSH	DE
	PUSH	AF
	PUSH	HL		;HL,AF,DE,...
	IN0	D,(BBR)
	XOR	A
	OUT0	(BBR),A

	FPR	5555H,0AAH
	FPR	2AAAH,055H
	FPR	5555H,080H
	FPR	5555H,0AAH
	FPR	2AAAH,055H

	OUT0	(BBR),D

	POP	HL
	POP	AF	; SECTOR ADRES
	LD	E,30H	; CMD sector erase
	OR	A	; CF=0 ��� �஢�ન �����
	CALL	ROM_WR
	POP	DE
	PUSH	AF

FSCLR_WAIT:
	LD	A,(0)
	BIT	7,A
	JR	NZ,FSCLR_END
	BIT	5,A
	JR	Z,FSCLR_WAIT
	POP	AF
	SCF
	RET

FSCLR_END:
	POP	AF
	OR	A

	ENDIF

	RET
;**********************************************
; �������  ����
;**********************************************
FLASH_CLR:

	IF	RAM

	DI
	PUSH	AF
	PUSH	DE
	IN0	D,(BBR)
	XOR	A
	OUT0	(BBR),A

	FPR	5555H,0AAH
	FPR	2AAAH,055H
	FPR	5555H,080H
	FPR	5555H,0AAH
	FPR	2AAAH,055H
	FPR	5555H,010H

FCLR_WAIT:
	LD	A,(0)
	BIT	7,A
	JR	NZ,FCLR_END
	BIT	5,A
	JR	Z,FCLR_WAIT
	POP	DE
	POP	AF
	SCF
	RET

FCLR_END:
	OUT0	(BBR),D
	POP	DE
	POP	AF
	OR	A

	ENDIF

	RET
