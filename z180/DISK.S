;**********************************************
;	�ࠩ��� �����஭���� ��᪠
;**********************************************

	SECTION	WORK

ROMA_L:	DW	0
ROMA_H: DB	0
DSPA_L:	DW	0
DSPA_H:	DB	0
C_F:	DB	0

	SECTION	ICODE

;**********************************************
; ����� ���������� ����� �� �����
;OUT	AHL	ADRES
;**********************************************
FREE_FAIND:
	CALL	FIRST_F
FREE_LOOP:
	PUSH	AF
	PUSH	HL
	CALL	ROM_RD2
	LD	A,D
	AND	E
	CP	0FFH	;����� = 0FFFFH
	JR	Z,FREE_FOUND

	POP	HL
	POP	AF
	CALL	NEXT_F
	JP	FREE_LOOP
FREE_FOUND:
	POP	HL
	POP	AF
	RET
	
;**********************************************
; ������ ����� 
;IN	HL	FILE NAME
;	DE	ADRES
;OUT	HL	SIZE
;**********************************************
LOAD_F:
	PUSH	DE
	CALL	FIND_F
	POP	DE
	RET	C	; �� ������
			; BC = size
			; AHL = ROM pointer
			; DE = RAM pointer
	DI
	PUSH	BC
	CALL	ROM_RAMRD
	CALL	DMA_WAIT
	POP	HL
	OR	A
	RET

;**********************************************
; ����� ����� �� ��������� ����
;IN	BC	FILE NAME
;OUT	A,HL	ADRES
;OUT	BC	size
;**********************************************
FIND_F:
	CALL	FIRST_F	; HL ���� �室

FIND_F0:
	CALL	ROM_RD2	; DE=(AHL) / ����� 䠩��
	PUSH	DE

	CALL	ROM_RD2	; DE=(AHL) / ��� 䠩��
	PUSH	AF
	PUSH	HL

	EX	DE,HL
	CALL	CPHLBC
	EX	DE,HL
	JR	Z,FOUND_F

	LD	A,D
	AND	E
	CP	0FFH
	JR	Z,FOUND_FERR

	POP	HL
	POP	AF
	POP	DE
	ADD	HL,DE
	ADC	0	; NEXT FILE
	JR	FIND_F0

FOUND_F:
	POP	HL
	POP	AF
	POP	BC
	OR	A
	RET

FOUND_FERR:
	POP	HL
	POP	AF
	POP	BC
	SCF
	RET

;**********************************************
; DISK FIRST
;**********************************************
FIRST_F:
	LD	HL,0000H
	LD	A,1
	RET


;**********************************************
; ������� �� ��������� ����
;IN	A,HL	ADRES
;OUT	A,HL	ADRES
;**********************************************
NEXT_F:
	PUSH	DE

	CALL	ROM_RD2	;DE=(HL) / ����� 䠩��
			;AHL=AHL+2	
	ADD	HL,DE
	ADC	0
	LD	DE,2	;AHL=AHL+2 /�ய��⨬ ���
	ADD	HL,DE
	ADC	D

	POP	DE
	RET
;**********************************************
; DE=(AHL)
; AHL=AHL+2
;**********************************************
ROM_RD2:
	PUSH	BC
	PUSH	AF
	CALL	ROM_RD
	LD	E,A
	POP	AF
	LD	BC,1
	ADD	HL,BC
	ADC	B
	PUSH	AF	; ���६��� ����
	CALL	ROM_RD
	LD	D,A
	POP	AF
	LD	BC,1
	ADD	HL,BC
	ADC	B
	POP	BC
	RET

;**********************************************
; ��६����� ROM � RAM
;**********************************************
MOVE_ROM:
	DI
	XOR	A
	LD	(C_F),A ;0-䠩�
	LD	HL,0
	LD	(DSPA_L),HL
	LD	(DSPA_H),A
	LD	E,A
	CALL	DSP_SET	; ��⠭���� ���� � 0

	CALL	FIRST_F	; ��砫� ROM ��᪠
	LD	(ROMA_H),A
	LD	(ROMA_L),HL

	PUSH	IX
	LD	IX,ITABLE
	CALL	MOVE_R
	POP	IX
	RET

MOVE_R:
	LD	HL,(ROMA_L)
	LD	A,(ROMA_H)
	CALL	ROM_RD2 ; DE=ࠧ��� 䠩��

	LD	C,A
	LD	A,D
	AND	E
	CP	0FFH	; �᫨ ��� = 0FFFFH
	RET	Z
	LD	A,C
	PUSH	DE	; (SP) = Size

	CALL	ROM_RD2	; DE=��� 䠨��
;-----			; HL=�ய��⨫� ��������� 䠩��
;	LD	C,A
	LD	A,D
	CP	05H	; ���� 䠩�� � ���
	JR	NC,N_FILE
;	LD	A,C
;-----
	LD	HL,(ROMA_L)
	LD	A,(ROMA_H)
	LD	BC,4
	ADD	HL,BC
	ADC	B	; �ய��⨫� ���������
			; AHL=��砫� 䠩�� ��� ���������	
	LD	BC,16	; ��������� 16 ����
	PUSH	IX
	POP	DE
	CALL	ROM_RAMRD
			; ॣ����� �� ����������
	CALL	MOV_CALC
	LD	BC,16
	ADD	IX,BC	; ᫥����� ������ � ����

	POP	HL
	PUSH	HL	; ࠧ��� 䠩��
	LD	DE,16
	OR	A
	SBC	HL,DE	; ��� ���������
	PUSH	HL	; (SP)=Size - 16
	EX	DE,HL

	LD	A,(ROMA_H)
	LD	HL,(ROMA_L)
	LD	BC,16+4	; ࠧ��� ��������� ����� !	
	ADD	HL,BC
	ADC	B
	CALL	ROM_DSPRD

	POP	DE	; DE=Size - 16
;----------------------------------------------
	LD	A,(C_F)
	INC	A
	LD	(C_F),A
	CP	4
	JR	NC,NORMAL_F

	LD	A,(DSPA_H)
	LD	HL,(DSPA_L)
	ADD	HL,DE
	ADC	0	; AHL ��砫� ������ 䠩�

	LD	L,0	
	RES	0,H
	RES	1,H
	RES	2,H
	RES	3,H	; HL = AAAA0000 00000000

	LD	DE,1000H ; ᫥���騩 ����
	ADD	HL,DE		
	ADC	0	; AHL = AHL + 10000 00000000

	LD	(DSPA_H),A
	LD	(DSPA_L),HL
	LD	E,A
	CALL	DSP_SET
	JR	N_FILE
NORMAL_F:
	LD	A,(DSPA_H)
	LD	HL,(DSPA_L)
	ADD	HL,DE
	ADC	0
	LD	(DSPA_H),A
	LD	(DSPA_L),HL
N_FILE:
	POP	DE	; DE=Size
	LD	A,(ROMA_H)
	LD	HL,(ROMA_L)
	ADD	HL,DE
	ADC	0
	LD	DE,4
	ADD	HL,DE
	ADC	D
	LD	(ROMA_H),A
	LD	(ROMA_L),HL

	JP	MOVE_R

; AHL = ���� �����㬥�� � ��㪮��� �����
; IX  = 㪠�뢠�� �� �����㬥�� + 16
MOV_CALC:
	PUSH	AF
	PUSH	HL
	PUSH	DE
	LD	A,(DSPA_H)
	LD	HL,(DSPA_L)
	LD	D,H	; TMP

	RLC	D
	RLA
	RLC	D
	RLA
	RLC	D
	RLA
	RLC	D
	RLA		; A=PAGE
	LD	(IX+6),A

	LD	A,H
	AND	0FH
	LD	H,A
	EX	DE,HL	; DE = ofset
	LD	L,(IX)
	LD	H,(IX+1)
	ADD	HL,DE
	LD	(IX),L
	LD	(IX+1)H

	LD	L,(IX+2)
	LD	H,(IX+3)
	ADD	HL,DE
	LD	(IX+2),L
	LD	(IX+3)H

	LD	L,(IX+4)
	LD	H,(IX+5)
	ADD	HL,DE
	LD	(IX+4),L
	LD	(IX+5)H

	POP	DE
	POP	HL
	POP	AF
	RET

	SECTION	WORK
