;**********************************************
;	įØ­åą®­­ė© į„ąØ «ģ­ė© Ø­ā„ąä„©į
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
				; ā„ŖćéØ© Ŗ ­ «
; į®įā®ļ­Ø„ įÆ„ęØ «ģ­ėå Ŗ­®Æ®Ŗ Ø Ŗ®­āą®«„ą®¢¢
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
;  
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
; ­ØęØ «Ø§ ęØļ Ŗ ­ «  1
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
	CALL	TX_OFF		; RTS=0 MPE=1   
	LD	A,RIE           ;   
	OUT0	(STAT0),A
	ENDIF

	RET
;**********************************************
; å®¤ Æą„ąė¢ ­Øļ Ŗ ­ «  0
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
; Æą®ę„įį ÆąØ­ļāØļ ” ©ā  į¤„įģ
	IN0	A,(RDR0) 	; Read Char
	IN0	C,(CNTLA0)	; Bit MPE
	PUSH	BC
	CALL	ASCI0_RX	; HOOK
	POP	BC
	JP	ASCI0_INT1 	; jump to Tx check
;----------------------------------------------
; ®”ą ”®āŖ  ®čØ”ŖØ į¤„įģ
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
; ­ ¢„ą­® ­ć¦­® ēā®ā® ®āÆą ¢Øāģ
        PUSH	BC
	CALL	ASCI0_TX	; HOOK
        POP	BC
;----------------------------------------------
ASCI0_INT4:
	BIT	2,B		;/DCD INT ?
	JP	Z,ASCI0_EXIT
;----------------------------------------------
; DCD Æ®¤Æą®£ą ¬¬  į¤„įģ

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
;    
;**********************************************
ASCI0_TX:
	RET

NET_TX:
	LD	C,A       	; 
	CALL	ASCI_TXWAIT
	CALL	TX_ON
	CALL	MPBT0		; ¬ć«ģāØÆą®ę„įį®ą
	OUT0	(TDR0),C
	RET

;**********************************************
;  
;**********************************************

NET_MARKER:
	AND	0FH
	LD	C,A		;  =  
	LD	A,(STATION)     ;   
	AND	0F0H
	OR	C		; SSSS CCCC  S-   C- š		
	LD	C,A

	CALL	ASCI_TXWAIT
	CALL	TX_ON		; RTS=0 MPE=0
	CALL	MPBT1		; ¬ć«ģāØÆą®ę„įį®ą
	OUT0	(TDR0),C
	LD	A,1
	LD	(NET_MODE),A	;  
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
	JP	NZ,MULTI_CPU	;   

;	LD	B,A
;	LD	A,(NET_MODE)
;	BIT	0,A
;	RET	Z		; 
;**********************************************
;    
;**********************************************
;	LD	A,B
	OR	A
	JP	M,ASB0_2	; ¢ā®ą®© ” ©ā
	LD	(NETB0),A
	RET
ASB0_2:
	AND	7FH
	LD	(NETB1),A
	CALL	NET_KEY		; ā„Æ„ąģ ą §”®ą ā®£® ēā® Æą©§ č«®
	RET

;**********************************************
;   
;**********************************************

MULTI_CPU:			; A = 
	LD	C,A		; 
        AND	0FH             ; 
	LD	B,A             ; B =     

	CP	10		; 
	JR	Z,WIDE_NET

	LD	A,(STATION)	;  
	AND	0FH
	CP	B  		;  
	JP	Z,NET_ON1

	CALL	TX_OFF		; RTS=1 MPE=1    

	IF	NETTEST
	 LD	A,0		;  
	ELSE
	 LD	A,2		;   
	ENDIF

	LD	(NET_MODE),A	;   
	LD	A,NOTHING       ;    
	LD	(NETB0),A
	
	LD	A,C     	;  
	RRCA
	RRCA
	RRCA
	RRCA                	; /16
	AND	0FH             ; ­®¬„ą įā ­ęØØ Ŗ®ā®ą ļ ćēØā„«ģįŖ ļ
	CALL	BIN2CHAR        ;
	LD	HL,CHR_B * 256 + CHR_Y
        CALL	PRINT_GRPT
	RET
WIDE_NET:
	CALL	TX_OFFW
	JR	NET_ON2

NET_ON1:
	CALL	TX_ON		; RTS=0 MPE=0   
NET_ON2:                
	IF	NETTEST
	 LD	A,1             ;  
	ELSE
	 LD	A,3		;  		
	ENDIF

	LD	(NET_MODE),A	;   
	LD	A,NOTHING       ;    
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
; å®¤ Æą„ąė¢ ­Øļ Ŗ ­ «  1
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
; Æą®ę„įį ÆąØ­ļāØļ ” ©ā  į¤„įģ
	IN0	A,(RDR1) 	; Read Char
	PUSH	BC
	CALL	ASCI1_RX	; HOOK
	POP	BC
	JP	ASCI1_INT1 	; jump to Tx check
;----------------------------------------------
; ®”ą ”®āŖ  ®čØ”ŖØ į¤„įģ
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
; ­ ¢„ą­® ­ć¦­® ēā®ā® ®āÆą ¢Øāģ

	CALL	ASCI1_TX	; HOOK

;----------------------------------------------
ASCI1_INT4:
	BIT	2,B		;/DCD INT ?
	JP	Z,ASCI1_EXIT
;----------------------------------------------
; DCD Æ®¤Æą®£ą ¬¬  į¤„įģ


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
	JP	M,ASB_2		; ¢ā®ą®© ” ©ā
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
; ā„Æ„ąģ ą §”®ą ā®£® ēā® Æą©§ č«®
;**********************************************
; ¤®Æ®«­Øā„«ģ­ė„ Ŗ« ¢ØčØ
	LD	A,(KEYB0)
	AND	3FH
	CP	49
	JP	NC,OTHER_KEY 	; ­®¬„ą Ŗ« ¢ØčØ ”®«ģč„ 48
; ą„¦Ø¬ Ŗ« ¢Ø āćąė
	LD	A,(KBD_MODE)
	OR	A		; Ŗ­®ÆŖ  SEL ?
	JP	Z,MUSIK_KEY	; ­„ ­ ¦ ā 
; ¤Ø Æ §®­ Ŗ« ¢Øč
	LD	A,(KEYB0)
	AND	3FH
	CP	36
	JP	NC,SP_KEY
	CP	12
	JP	NC,MUSIK_KEY
; įÆ„ęØ «ģ­ė„ Ŗ« ¢ØčØ
SP_KEY:
	LD	A,(KEYB0)
	CALL	INKEY	
	LD	A,1
	LD	(ANY_KEY),A	; ÆąØ§­®Ŗ Æą®å®¦¤„­Øļ ­ ¦ āØļ
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
	LD	D,A		; Æą„®”ą §®¢ «Ø Æ® ā ”«Øę„ £ą®¬Ŗ®įāģ

	LD	A,(NETB0)
	OUT0	(MTST1),A
	BIT	6,A
	JP	Z,NK_PRES
;**********************************************
; ®āÆćįŖ ­Ø„ NET ¬ć§ėŖ «ģ­®© Ŗ« ¢ØčØ
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
; ­ ¦ āØ„ NET ¬ć§ėŖ «ģ­®© Ŗ« ¢ØčØ
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
	LD	C,A		;  -> 
	LD	A,(NET_MODE)
	BIT	0,A
	RET	Z               ; 

	CALL	K_TST		;     
        RET	C

	LD	A,C
	CALL	NET_TX
	RET

K_TST:
	LD	A,(KEYB0)
	AND	3FH
	CP	49
	CCF
	RET	C	 	; ­®¬„ą Ŗ« ¢ØčØ ”®«ģč„ 48
; ą„¦Ø¬ Ŗ« ¢Ø āćąė
	LD	A,(KBD_MODE)
	OR	A		; Ŗ­®ÆŖ  SEL ?
	RET	Z		; ­„ ­ ¦ ā 
; ¤Ø Æ §®­ Ŗ« ¢Øč
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
	LD	D,A		; Æą„®”ą §®¢ «Ø Æ® ā ”«Øę„ £ą®¬Ŗ®įāģ

	LD	A,(KEYB0)
	BIT	6,A
	JP	Z,K_PRES
;**********************************************
; ®āÆćįŖ ­Ø„ ¬ć§ėŖ «ģ­®© Ŗ« ¢ØčØ
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
; ­ ¦ āØ„ ¬ć§ėŖ «ģ­®© Ŗ« ¢ØčØ
;**********************************************
K_PRES:	
	AND	3FH
	PUSH	AF
	LD	E,A
	LD	A,(KBD_REL)
	ADD	E
	LD	E,A
; -------  ¤«ļ Ø£ą
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
; Ø§¬„­„­Ø„ įÆ„ęØ «ģ­ėå Ŗ­®Æ®Ŗ Ø Ŗ®­āą®««„ą®¢
;**********************************************
OTHER_KEY:
	CP	63
	JP	Z,KEYS
	LD	HL,SPITCH - 60
	LD	E,A
	LD	D,0
	ADD	HL,DE
	LD	A,(KEYB1)
	LD	(HL),A		; ­®¢®„ į®įā®ļ­Ø„
;**********************************************
;   
;**********************************************
	LD	A,E
;	CP	NOTHING	; 
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
; ą„®”ą §®¢ ­Ø„ £ą®¬Ŗ®įāØ ¢ ­®ą¬ «ģ­ė© ¢Ø¤
;
;IN/OUT	A	£ą®¬Ŗ®įāģ
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
;  
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
	LD	(HL),E	; ­®¢®„ į®įā®ļ­Ø„
	XOR	E	; A = Ø§¬„­„­Øļ
	RET	Z
;
	LD	D,A
	LD	A,E	; ­®¢®„ į®įā®ļ­Ø„
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
	JP	Z,ENTR_UP	; ®āÆćįŖ ­Ø„ SEL
; ­ ¦ āØ„ SEL
;	LD	A,(KBD_MODE)
;	OR	A
;	JP	NZ,SP_MODE_OFF	; „į«Ø ”ė« įÆ„ęØ «ģ­ė© ą„¦Ø¬
;	CALL	SPM_ON
	LD	A,1
	LD	(KBD_MODE),A	; ¢Ŗ«īēØ¬ įÆ„ęØ «ģ­ė© ą„¦Ø¬
	LD	A,80H
	LD	(DISP_MASK),A
	RET
; ®āÆćįŖ ­Ø„ SEL 	
ENTR_UP:
;	LD	A,(ANY_KEY)
;	OR	A		; ­Ø ®¤­  Ŗ« ¢Øč  ­„ ”ė«  ­ ¦ ā®©
;	RET	Z		; ą„¦Ø¬ į äØŖį ęØ„©
;SP_MODE_OFF:
;	CALL	SPM_OFF
	XOR	A
	LD	(KBD_MODE),A	; Æą®Ø§ č®« ENTER
	LD	(DISP_MASK),A
	RET

;SPM_ON:
;	XOR	A
;	LD	(ANY_KEY),A
;	INC	A
;	LD	A,1
;	LD	(KBD_MODE),A	; ¢Ŗ«īēØ¬ įÆ„ęØ «ģ­ė© ą„¦Ø¬
;	LD	A,80H
;	LD	(DISP_MASK),A
;	RET
;SPM_OFF:
;	XOR	A
;	LD	(KBD_MODE),A	; Æą®Ø§ č®« ENTER
;	LD	(DISP_MASK),A
;	RET
;**********************************************
; ā ”«Øę  ēćįā¢Øā„«ģ­®įāØ Ŗ« ¢Ø āćąė
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
	LD	A,(HL)	; Æą„®”ą §®¢ «Ø Æ® ā ”«Øę„ £ą®¬Ŗ®įāģ
	RET

VEL_TABLE:
	DB	127,127,100,80,65,55,50,45,41,37,33,30,27,24,22,20,18,16,15,14
	DB	13,12,11,10,9,8,8,7,7,6,6,5,5,4,4,4,4,3,3,3,3,2,2,2,2,1,1,1
