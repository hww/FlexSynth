;**********************************************
;	�ᨭ�஭�� �ਠ��� ����䥩�
;
;	ASCI0	EXTERNAL PORT
;	ASCI1	INTERNAL KBD
;
;**********************************************

NOTHING:	EQU	50

;STATUS -------------------------------------------------------

RDRF:	EQU	80H	;R | 1 Receive Register Data Full
OVRN:	EQU	40H	;R | 1 Overrun
PE:	EQU	20H	;R | 1 Paryty Error
FE:	EQU	10H	;R | 1 Frame Error
RIE:	EQU	8H	;RW| 1 INT Receive Enable
DCD0:	EQU	4H	;R | DCD (CHANEL 0)
CTS1E:	EQU	4H	;RW| 1 PIN52=CTS1, 0 PIN52=RXS (CHANEL 1)
TDRE:	EQU	2H	;R | 1 Transmit Data Register Is Empty
TIE:	EQU	1H	;RW| 1 Transmit INT Enable

; CONTROL A ---------------------------------------------------

MPE:	EQU	80H	;1=Multiprocessor Format
RE:	EQU	40H	;1=Receivern Enable
TE:	EQU	20H	;1=Transmiter Enable
RTS0:	EQU	10H	;RTS (CHANEL 0)
CKA1D:	EQU	10H	;(CKA1/TEND pin) = (TEND & CKA1D) OR (CKA1 & !CKA1D)
			;(CHANEL 1)
MPBR_EFR: EQU	8H	;Multiprocessor Bit Receive/Error Flag Reset Bit
MOD2:	EQU	4H	;MODE
MOD1:	EQU	2H
MOD0:	EQU	1H

BCNTRA1: EQU	RE OR MOD2
BCNTRA0: EQU	TE OR RE OR MOD2 OR MOD0 OR MPE

; CONTROL B ---------------------------------------------------

MPBT:	EQU	80H	;Multiprocessor Bit Transmit
MP:	EQU	40H	;Multiprocessor Mode
CTS_PS:	EQU	20H	;Read CTS, Write PS=1->PRESCALE=30, PS=0->PRESCALE=10
PEO:	EQU	10H	;1=ODD, 0=EVEN Parity
DR:	EQU	8H	;DR=0->DIVIDE BY 16, DR=1->DIVIDE BY 64
SS2:	EQU	4H	;SOURCE SPEED
SS1:	EQU	2H
SS0:	EQU	1H

BCNTRB1: EQU	SS2	; CLK/2560		
BCNTRB0: EQU	MP	; CLK/160		

	SECTION WORK

KEYB0:		DB	0
KEYB1:		DB	0
NETB0:		DB	0
NETB1:		DB	0
NET_MODE:	DB	0
KBD_REL: 	DB	24
				; ⥪�騩 �����
; ���ﭨ� ᯥ樠���� ������ � ����஫�஢�
SPITCH:		DB	0
SMODUL:		DB	0
SVOL:		DB	0
SKEY3:		DB	0
MAIN_VOL:	DB	80H
VOL_A:		DB	80H
VOL_B:		DB	80H

KBD_MODE:	DB	0
ANY_KEY:	DB	0
VELOCITY:	DB	0
PITCH_D:	DB	0
VOL_D:		DB	0
SXU:		DB	0
SPLIT:		DB	0

	SECTION	ICODE
;**********************************************
; ���������� ������
;**********************************************
TX_OFFW:
	LD	A,BCNTRA0 XOR MPE ; MPE=0 RTS=0
	OUT0	(CNTLA0),A
	RET
TX_ON:
	LD	A,BCNTRA0 OR RTS0 XOR MPE ; MPE=0 RTS=1
	OUT0	(CNTLA0),A
	RET
TX_OFF:
	LD	A,BCNTRA0	         ; MPE=1 RTS=0
	OUT0	(CNTLA0),A
	RET

MPBT0:
	LD	A,BCNTRB0 
	OUT0	(CNTLB0),A
	RET
MPBT1:
	LD	A,BCNTRB0 OR MPBT
	OUT0	(CNTLB0),A
	RET
;**********************************************
; ���樠������ ������ 1
;**********************************************
ASCI1_INIT:
	DI
	LD	HL,ASCI1_INT
	LD	(VASCI_1),HL	; vectors
	LD	A,BCNTRA1
	OUT0	(CNTLA1),A
	LD	A,BCNTRB1
	OUT0	(CNTLB1),A
	LD	A,RIE
	OUT0	(STAT1),A	; receive INT ON

	IF 	NETWORK
	
	LD	HL,ASCI0_INT
	LD	(VASCI_0),HL	; vectors
	LD	A,BCNTRA0
	OUT0	(CNTLA0),A      ; RTS=0
	LD	A,BCNTRB0
	OUT0	(CNTLB0),A
	CALL	TX_OFF		; RTS=0 MPE=1 ����� ������ ����������
	LD	A,RIE           ; ��������� ���������� 
	OUT0	(STAT0),A
	ENDIF

	RET
;**********************************************
; �室 ���뢠��� ������ 0
;**********************************************

	IF	NETWORK

ASCI0_INT:
	PUSH	AF		; Save registers
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	PUSH	IY

	IN0	A,(STAT0) 	; Read Status
	LD	B,A

	AND	0F0H		; Mask info
	JP	Z,ASCI0_INT 	; No rec related int....

	AND	070H		; any errors ?
	JP	NZ,REC0_ERR
;----------------------------------------------
; ����� �ਭ��� ���� ᤥ��
	IN0	A,(RDR0) 	; Read Char
	IN0	C,(CNTLA0)	; Bit MPE
	PUSH	BC
	CALL	ASCI0_RX	; HOOK
	POP	BC
	JP	ASCI0_INT1 	; jump to Tx check
;----------------------------------------------
; ��ࠡ�⪠ �訡�� ᤥ��
REC0_ERR:
	IN0	A,(RDR0) 	; Read Char
	IN0	A,(CNTLA0)
	OR	BCNTRA0
	OUT0	(CNTLA0),A	; Reset error
	CALL	ASCI0_ER	; HOOK
;----------------------------------------------
ASCI0_INT1:
	BIT	1,B
	JP	Z,ASCI0_INT4
;----------------------------------------------
; ����୮ �㦭� ��� ��ࠢ���
        PUSH	BC
	CALL	ASCI0_TX	; HOOK
        POP	BC
;----------------------------------------------
ASCI0_INT4:
	BIT	2,B		;/DCD INT ?
	JP	Z,ASCI0_EXIT
;----------------------------------------------
; DCD ����ணࠬ�� ᤥ��

;----------------------------------------------
ASCI0_EXIT:
	POP	IY
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	EI
	RET

;**********************************************
;**********************************************
ASCI0_ER:
	RET

;**********************************************
; �������� ����� � �������
;**********************************************
ASCI0_TX:
	RET

NET_TX:
	LD	C,A       	; ����
	CALL	ASCI_TXWAIT
	CALL	TX_ON
	CALL	MPBT0		; ���⨯�����
	OUT0	(TDR0),C
	RET

;**********************************************
; ������� ������
;**********************************************

NET_MARKER:
	AND	0FH
	LD	C,A		; � = ����� ������
	LD	A,(STATION)     ; ����� ���� �������
	AND	0F0H
	OR	C		; SSSS CCCC  S- ��� ������� C- ���������		
	LD	C,A

	CALL	ASCI_TXWAIT
	CALL	TX_ON		; RTS=0 MPE=0
	CALL	MPBT1		; ���⨯�����
	OUT0	(TDR0),C
	LD	A,1
	LD	(NET_MODE),A	; �������� �������
	RET

ASCI_TXWAIT:
	IN0	A,(STAT0)
	AND	TDRE		; 1 TX RG EMPTY
	JR	Z,ASCI_TXWAIT
	RET

;**********************************************
;**********************************************
ASCI0_RX:
	BIT	3,C		; C = CNTLA0
	JP	NZ,MULTI_CPU	; ���������� ���� ����

;	LD	B,A
;	LD	A,(NET_MODE)
;	BIT	0,A
;	RET	Z		; �����
;**********************************************
; ���� �������� ������� �������
;**********************************************
;	LD	A,B
	OR	A
	JP	M,ASB0_2	; ��ன ����
	LD	(NETB0),A
	RET
ASB0_2:
	AND	7FH
	LD	(NETB1),A
	CALL	NET_KEY		; ⥯��� ࠧ��� ⮣� �� �੧�諮
	RET

;**********************************************
; ���� �������� �������
;**********************************************

MULTI_CPU:			; A = ����
	LD	C,A		; 
        AND	0FH             ; 
	LD	B,A             ; B = ����� ������ � ������� ���������������

	CP	10		; �����������������
	JR	Z,WIDE_NET

	LD	A,(STATION)	; ����� �������
	AND	0FH
	CP	B  		; ������� ������
	JP	Z,NET_ON1

	CALL	TX_OFF		; RTS=1 MPE=1 ��������� ������ ���� �����

	IF	NETTEST
	 LD	A,0		; ������� ����
	ELSE
	 LD	A,2		; �� ������� ����
	ENDIF

	LD	(NET_MODE),A	; �� ������� ������
	LD	A,NOTHING       ; ���� ������ �� ������
	LD	(NETB0),A
	
	LD	A,C     	; ����� �������
	RRCA
	RRCA
	RRCA
	RRCA                	; /16
	AND	0FH             ; ����� �⠭樨 ����� ��⥫�᪠�
	CALL	BIN2CHAR        ;
	LD	HL,CHR_B * 256 + CHR_Y
        CALL	PRINT_GRPT
	RET
WIDE_NET:
	CALL	TX_OFFW
	JR	NET_ON2

NET_ON1:
	CALL	TX_ON		; RTS=0 MPE=0 ��������� ��� �����
NET_ON2:                
	IF	NETTEST
	 LD	A,1             ; ������� ������
	ELSE
	 LD	A,3		; ������ ������		
	ENDIF

	LD	(NET_MODE),A	; �� ������� ������
	LD	A,NOTHING       ; ���� ������ �� ������
	LD	(NETB0),A

	LD	A,C
	RRCA
	RRCA
	RRCA
	RRCA
	AND	0FH
	CALL	BIN2CHAR
	LD	HL,CHR_H * 256 + CHR_I
        CALL	PRINT_GRPT
	RET
	ENDIF


;**********************************************
; �室 ���뢠��� ������ 1
;**********************************************

ASCI1_INT:
	PUSH	AF		; Save registers
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	PUSH	IY

	IN0	A,(STAT1) 	; Read Status
	LD	B,A

	AND	0F0H		; Mask info
	JP	Z,ASCI1_INT1 	; No rec related int....

	AND	070H		; any errors ?
	JP	NZ,REC_ERR
;----------------------------------------------
; ����� �ਭ��� ���� ᤥ��
	IN0	A,(RDR1) 	; Read Char
	PUSH	BC
	CALL	ASCI1_RX	; HOOK
	POP	BC
	JP	ASCI1_INT1 	; jump to Tx check
;----------------------------------------------
; ��ࠡ�⪠ �訡�� ᤥ��
REC_ERR:
	IN0	A,(RDR1) 	; Read Char
	LD	A,BCNTRA1
	OUT0	(CNTLA1),A	; Reset error
	CALL	ASCI1_ER	; HOOK
;----------------------------------------------
ASCI1_INT1:
	BIT	1,B
	JP	Z,ASCI1_INT4
;----------------------------------------------
; ����୮ �㦭� ��� ��ࠢ���

	CALL	ASCI1_TX	; HOOK

;----------------------------------------------
ASCI1_INT4:
	BIT	2,B		;/DCD INT ?
	JP	Z,ASCI1_EXIT
;----------------------------------------------
; DCD ����ணࠬ�� ᤥ��


;----------------------------------------------
ASCI1_EXIT:
	POP	IY
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	EI
	RET

;**********************************************
;**********************************************
ASCI1_ER:
	RET

;**********************************************
;**********************************************
ASCI1_TX:
	RET

;**********************************************
;**********************************************
ASCI1_RX:
	OR	A
	JP	M,ASB_2		; ��ன ����
	LD	(KEYB0),A
	CALL	NET_TXB0
	RET
ASB_2:
	PUSH	AF
	CALL	NET_TXB0
	POP	AF
	AND	7FH
	LD	(KEYB1),A
;**********************************************
; ⥯��� ࠧ��� ⮣� �� �੧�諮
;**********************************************
; �������⥫�� ������
	LD	A,(KEYB0)
	AND	3FH
	CP	49
	JP	NC,OTHER_KEY 	; ����� ������ ����� 48
; ०�� ����������
	LD	A,(KBD_MODE)
	OR	A		; ������ SEL ?
	JP	Z,MUSIK_KEY	; �� �����
; �������� ������
	LD	A,(KEYB0)
	AND	3FH
	CP	36
	JP	NC,SP_KEY
	CP	12
	JP	NC,MUSIK_KEY
; ᯥ樠��� ������
SP_KEY:
	LD	A,(KEYB0)
	CALL	INKEY	
	LD	A,1
	LD	(ANY_KEY),A	; �ਧ��� ��宦����� ������
	RET
;**********************************************
; D=velocyty E=key
;**********************************************
NET_KEY:
	LD	A,(NETB0)
	AND	3FH
	CP	NOTHING
	RET	NC

	LD	A,(NETB1)
	OUT0	(MTST0),A
	CALL	GET_VEL
	LD	D,A		; �८�ࠧ����� �� ⠡��� �஬�����

	LD	A,(NETB0)
	OUT0	(MTST1),A
	BIT	6,A
	JP	Z,NK_PRES
;**********************************************
; ���᪠��� NET ��몠�쭮� ������
;**********************************************
NK_UP:	
	AND	3FH
	LD	E,A
	LD	A,(KBD_REL)
	ADD	E
	LD	E,A
	LD	A,80H + NET_MCH
	CALL	MIDIIN
	RET
;**********************************************
; ����⨥ NET ��몠�쭮� ������
;**********************************************
NK_PRES:	
	LD	E,A
	LD	A,(KBD_REL)
	ADD	E
	LD	E,A
	LD	A,90H + NET_MCH
	CALL	MIDIIN
	RET
;**********************************************
; D=velocyty E=key
;**********************************************
NET_TXB0:
	LD	C,A		; ��� -> �
	LD	A,(NET_MODE)
	BIT	0,A
	RET	Z               ; �����

	CALL	K_TST		; �������� � ����������� �� �������
        RET	C

	LD	A,C
	CALL	NET_TX
	RET

K_TST:
	LD	A,(KEYB0)
	AND	3FH
	CP	49
	CCF
	RET	C	 	; ����� ������ ����� 48
; ०�� ����������
	LD	A,(KBD_MODE)
	OR	A		; ������ SEL ?
	RET	Z		; �� �����
; �������� ������
	CP	36
	CCF
	RET	C
	CP	12
	RET	C
	OR	A
	RET

MUSIK_KEY:
	LD	A,(KEYB1)
	CALL	GET_VEL
	LD	D,A		; �८�ࠧ����� �� ⠡��� �஬�����

	LD	A,(KEYB0)
	BIT	6,A
	JP	Z,K_PRES
;**********************************************
; ���᪠��� ��몠�쭮� ������
;**********************************************
K_UP:	AND	3FH
	LD	L,A
	LD	E,A
	LD	A,(KBD_REL)
	ADD	E
	LD	E,A
	LD	A,(SPLIT)
	OR	A
	JR	Z,SPL_1
        LD	A,L
	CP	24
	JR	NC,SPL_1
        LD	A,80H
	CALL	MIDIIN
	RET
SPL_1:
	LD	A,80H + KBD_MCH
	CALL	MIDIIN
	RET
;**********************************************
; ����⨥ ��몠�쭮� ������
;**********************************************
K_PRES:	
	AND	3FH
	PUSH	AF
	LD	E,A
	LD	A,(KBD_REL)
	ADD	E
	LD	E,A
; -------  ��� ���
	LD	HL,GM_INPUT
	LD	A,(HL)
	LD	B,0
	LD	C,A
	INC	A
	AND	7
	LD	(HL),A
	ADD	HL,BC
	INC	HL
	LD	A,(TRANSB)
	NEG	A
	ADD	E
	LD	(HL),A
; --------- 
	LD	A,(SPLIT)
	OR	A
	JR	Z,SPL_0
        POP	AF
	CP	24
	JR	NC,SPL_01
        LD	A,90H
	CALL	MIDIIN
	RET
SPL_0:
	POP	AF
SPL_01:
	LD	A,90H + KBD_MCH
	CALL	MIDIIN
	RET
;**********************************************
; ��������� ᯥ樠���� ������ � ����஫��஢
;**********************************************
OTHER_KEY:
	CP	63
	JP	Z,KEYS
	LD	HL,SPITCH - 60
	LD	E,A
	LD	D,0
	ADD	HL,DE
	LD	A,(KEYB1)
	LD	(HL),A		; ����� ���ﭨ�
;**********************************************
; ����� ��������� �������
;**********************************************
	LD	A,E
;	CP	NOTHING	; ������
;	RET	Z
;	CP	61
;	RET	Z	; MODULAT
;	CP	60
;	JP	Z,PITCH
;	RET	Z
	CP	62	; VOLUME
	RET	NZ

	LD	A,(MAIN_VOL)
	CALL	CONV_VOL
	LD	(MAIN_VOL),A
	RET
;**********************************************
; �८�ࠧ������ �஬���� � ��ଠ��� ���
;
;IN/OUT	A	�஬�����
;**********************************************
CONV_VOL:
	LD	H,A	; H = MAIN VOL
	LD	A,(VOL_D)
	LD	L,A	; L = OLD POINT
	LD	A,(SVOL)
	ADD	A
	LD	(VOL_D),A

	SUB	L	; A = DELTA 
	BIT	7,A
	JP	NZ,CONV_MINUS

	SRA	A
	LD	L,A	
	LD	A,H
	ADD	L
	CP	80H
	RET	C
	LD	A,80H
	RET

CONV_MINUS:
	NEG	A
	SRA	A
	LD	L,A
	LD	A,H
	SUB	L
	RET	NC
	LD	A,0
	RET


;**********************************************
; ������ �������
;**********************************************
	IF	MODPITCH
PITCH:
	LD	A,(PITCH_D)
	LD	L,A
	LD	A,(SPITCH)
	ADD	A
	LD	(PITCH_D),A
	SUB	L	; A = DELTA

	BIT	7,A
	JP	NZ,PITCH_MINUS

	SRA	A
	LD	L,A
	LD	A,(SXU)
	ADD	L
	LD	(SXU),A
	JP	BALANCE

PITCH_MINUS:
	NEG	A
	SRA	A
	LD	L,A
	LD	A,(SXU)
	SUB	L
	LD	(SXU),A

BALANCE:
	LD	L,A	
	BIT	7,A
	JP	NZ,BAL_MINUS

	LD	A,80H
	LD	(VOL_A),A
	SUB	L
	SUB	L
	LD	(VOL_B),A
	RET

BAL_MINUS:
	LD	A,80H
	LD	(VOL_B),A
	ADD	L
	LD	(VOL_A),A
	RET

	ENDIF
;**********************************************
;
;**********************************************
KEYS:
	LD	HL,SKEY3
	LD	A,(KEYB1)
	LD	E,A
	LD	A,(HL)	
	LD	(HL),E	; ����� ���ﭨ�
	XOR	E	; A = ���������
	RET	Z
;
	LD	D,A
	LD	A,E	; ����� ���ﭨ�
	BIT	0,D
	JP	Z,N_UP
	PUSH	DE
	CALL	KEY_UP
	POP	DE
N_UP:
	BIT	1,D
	JP	Z,N_DOWN
	PUSH	DE
	CALL	KEY_DOWN
	POP	DE
N_DOWN:
	BIT	2,D
	RET	Z
	BIT	2,E
	JP	Z,ENTR_UP	; ���᪠��� SEL
; ����⨥ SEL
;	LD	A,(KBD_MODE)
;	OR	A
;	JP	NZ,SP_MODE_OFF	; �᫨ �� ᯥ樠��� ०��
;	CALL	SPM_ON
	LD	A,1
	LD	(KBD_MODE),A	; ����稬 ᯥ樠��� ०��
	LD	A,80H
	LD	(DISP_MASK),A
	RET
; ���᪠��� SEL 	
ENTR_UP:
;	LD	A,(ANY_KEY)
;	OR	A		; �� ���� ������ �� �뫠 ����⮩
;	RET	Z		; ०�� � 䨪�樥�
;SP_MODE_OFF:
;	CALL	SPM_OFF
	XOR	A
	LD	(KBD_MODE),A	; �ந��讫 ENTER
	LD	(DISP_MASK),A
	RET

;SPM_ON:
;	XOR	A
;	LD	(ANY_KEY),A
;	INC	A
;	LD	A,1
;	LD	(KBD_MODE),A	; ����稬 ᯥ樠��� ०��
;	LD	A,80H
;	LD	(DISP_MASK),A
;	RET
;SPM_OFF:
;	XOR	A
;	LD	(KBD_MODE),A	; �ந��讫 ENTER
;	LD	(DISP_MASK),A
;	RET
;**********************************************
; ⠡��� ���⢨⥫쭮�� ����������
;**********************************************
GET_VEL:
	CP	30H
	JP	C,G_V_0
	LD	A,2FH
G_V_0:
	LD	L,A
	LD	A,(VELOCITY)
	AND	07H
VEL_DIV:
	SUB	1
	JP	C,VEL_DIVEND
	OR	A
	RR	L
	JP	VEL_DIV

VEL_DIVEND:
	LD	H,0
	LD	BC,VEL_TABLE
	ADD	HL,BC
	LD	A,(HL)	; �८�ࠧ����� �� ⠡��� �஬�����
	RET

VEL_TABLE:
	DB	127,127,100,80,65,55,50,45,41,37,33,30,27,24,22,20,18,16,15,14
	DB	13,12,11,10,9,8,8,7,7,6,6,5,5,4,4,4,4,3,3,3,3,2,2,2,2,1,1,1