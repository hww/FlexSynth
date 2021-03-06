;**********************************************
; �������� ���������� ������������
;**********************************************

        SECTION WORK

VAR_NUM:        DB      0
VAR_NUMED:      DB      0       ; ����� ��६����� ��� ।���஢����

VAR_OLD:        DW      0       ; ��᫥ �⮡ࠦ���� ��६����� ��� ���������
                                ; �

VAR_PNTR:       DW      MCH_AREA
VAR_TYPE:       DW      0
VAR_MIN:        DW      0
VAR_MAX:        DW      2
VAR_VIEW:       DW      RFSHM
VAR_RFSH:       DW      DID
VAR_MASK:       DW      0000H
VAR_NORM:       DW      0

TERM_MODE:      DB      0       ; 0=��ଠ� 1=VAR
GEN_MODE:       DB      0       ; 0=��㤨� 1=����

SEC_FILE:       DB      0
SEC_INST:       DB      0

TRANSB:         DB      0       ; �࠭ᯮ�� ��� �������

SHIFT_F:        DB      0       ; ���ﭨ� ���

        SECTION ICODE

;**********************************************
;       � ��室�� ������ ��� �� ��몠����
;       ������
; IN    A       ��� ������ � �ਧ��� ���᪠���
;**********************************************
INKEY:
        PUSH    HL
        PUSH    DE
        PUSH    AF
        LD      L,A
        LD      H,0
        RES     6,L
        ADD     HL,HL
	CALL	GETK_TBL
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        POP     AF
        PUSH    AF
        CALL    KEY_EXE
        POP     AF
        POP     DE
        POP     HL
        RET

KEY_EXE:
        PUSH    DE
        RET

GETK_TBL:
	LD	A,(GEN_MODE)
	OR	A
	JR	NZ,GETK_GM
        LD      DE,KEY_TABLE
        LD      A,(SHIFT_F)
        OR      A
        RET      Z
        LD      DE,KEY_TABLESH
	RET
GETK_GM:
        LD      DE,KEY_TABLEG
        LD      A,(SHIFT_F)
        OR      A
        RET      Z
        LD      DE,KEY_TABLESHG
	RET
;**********************************************
;	������ � ������� �������
;**********************************************
NETS:
        BIT     6,A
        RET     NZ

        SUB     36      ; 36,37,.. -> 0,1,2,..
	LD	L,A
	LD	A,(NET_MODE)
	BIT	1,A
	RET	NZ	; ���� ��� �� ���� �� ��� �����������

	LD	A,L
	PUSH	AF
	CALL	NET_MARKER
	POP	AF
	CALL	BIN2CHAR
	LD	HL,CHR_N *256 + CHR_E
	CALL	PRINT_GRPT
	RET

;**********************************************
;       �ணࠬ�� �ࠢ����� ��६���묨
;       � ��室�� ������ ��஢�� ������
;**********************************************
DIGIT:
        BIT     6,A
        RET     NZ

        SUB     36      ; 36,37,.. -> 0,1,2,..

        CALL    RD_VAR
        ADD     HL,HL   ; HL * 2
        PUSH    HL
        POP     DE      ; DE = HL * 2
        ADD     HL,HL
        ADD     HL,HL   ; HL = HL * 8
        ADD     HL,DE   ; HL = HL + 10
        PUSH    AF
        CALL    VAR_VALID
        POP     AF

        LD      E,A
        LD      D,0
        BIT     7,H
        JR      NZ,DIG_1
        ADD     HL,DE
        JR      DIG_2
DIG_1:
        OR      A
        SBC     HL,DE
DIG_2:
        CALL    VAR_VALID
        CALL    WR_VAR

        LD      HL,(VAR_RFSH)
        PUSH    HL
        RET

;**********************************************
; �������� �� ����
;**********************************************
KEY_UP:
        BIT     0,A
        JR      NZ,KEY_UPP
        XOR     A
        LD      (REP_UP),A
        LD      (SPEED),A
        RET

KEY_UPP:
        BIT     2,A
        JP      NZ,KBD_PL

        LD      A,(REP_DOWN)
        OR      A
        JR      NZ,KEY_NORM

        LD      A,6
        LD      (REP_UP),A
KEY_UPREP:
        CALL    RD_VAR
        INC     HL
        CALL    VAR_VALMAX
        CALL    WR_VAR
        LD      HL,(VAR_RFSH)
        PUSH    HL
        RET
;**********************************************
; ������� �� ����
;**********************************************
KEY_DOWN:
        BIT     1,A
        JR      NZ,KEY_DOWNP
        XOR     A
        LD      (REP_DOWN),A
        RET

KEY_DOWNP:
        BIT     2,A
        JP      NZ,KBD_MI

        LD      A,(REP_UP)
        OR      A
        JR      NZ,KEY_NORM

        LD      A,6
        LD      (REP_DOWN),A
KEY_DOWNREP:
        CALL    RD_VAR
        DEC     HL
        CALL    VAR_VALMIN
        CALL    WR_VAR

        LD      HL,(VAR_RFSH)
        PUSH    HL
        RET

;**********************************************
; �����६����� 㤥ঠ��� ����� � �����
;**********************************************

KEY_NORM:
        LD      HL,(VAR_NORM)
        CALL    WR_VAR

        XOR     A
        LD      (REP_UP),A
        LD      (REP_DOWN),A

        LD      HL,(VAR_RFSH)
        PUSH    HL
        RET
;**********************************************
; ����� ����������
;**********************************************
KBD_PL:
        LD      A,1
        LD      (ANY_KEY),A

        LD      A,(KBD_REL)
        CP      24
        LD      A,24+12
        LD      HL,CHR_HI
        JR      NC,KBD_MAX
        LD      HL,CHR_MIN
        LD      A,24
KBD_MAX:
        LD      (KBD_REL),A
        XOR     A
        CALL    PRINT_GRPT
        RET

KBD_MI:
        LD      A,1
        LD      (ANY_KEY),A

        LD      A,(KBD_REL)
        CP      25
        LD      A,12
        LD      HL,CHR_LO
        JR      C,KBD_MIN
        LD      HL,CHR_MIN
        LD      A,24
KBD_MIN:
        LD      (KBD_REL),A
        XOR     A
        CALL    PRINT_GRPT
        RET

;**********************************************
; ����� �����
;**********************************************
SIGN:
        BIT     6,A
        RET     NZ

        CALL    RD_VAR
        CALL    NEGHL
        CALL    VAR_VALID
        CALL    WR_VAR
        RET

;**********************************************
; ����㧪� ���㧪� ��६�����
;OUT    HL      ��६�����
;**********************************************
RD_VAR:
        PUSH    AF
        LD      HL,(VAR_PNTR)
        LD      A,(VAR_TYPE)
RD_VAR_UND:
        BIT     0,A
        JR      Z,RD_VAR_0
                                ; ��६����� 2 ����
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        POP     AF
        RET

RD_VAR_0:                       ; ��६����� 1 ����
        LD      L,(HL)
        CALL    B2W
        POP     AF
        RET
;**********************************************
; ���㧪� ���㧪� ��६�����
;IN     HL      ��६�����
;**********************************************

WR_VAR:
        PUSH    AF
        PUSH    DE
        PUSH    HL

        EX      DE,HL
        LD      HL,(VAR_PNTR)
        LD      A,(VAR_TYPE)
	BIT	2,A
	JR	NZ,WR_PROTECT
        BIT     0,A
        JR      Z,WR_VAR_0
                                ; ��६����� 2 ����
        LD      (HL),E
        INC     HL
        LD      (HL),D
WR_PROTECT:
        POP     HL
        POP     DE
        POP     AF
        RET

WR_VAR_0:                       ; ��६����� 1 ����
        LD      (HL),E
        POP     HL
        POP     DE
        POP     AF
        RET


;**********************************************
; �஢�ઠ �宦����� � ��������
;**********************************************
VAR_VALID:
        LD      DE,(VAR_MAX)
        EX      DE,HL
        CALL    CPHLDES
        EX      DE,HL
        JR      NC,N_MAX
        LD      HL,0
        RET
N_MAX:
        LD      DE,(VAR_MIN)
        CALL    CPHLDES
        RET     NC
        LD      HL,0
        RET

VAR_VALMIN:
        LD      DE,(VAR_MIN)
        CALL    CPHLDES
        RET     NC
        LD      HL,(VAR_MAX)
        RET

; �஢�ઠ �� ���ᨬ��쭮� ���祭��
VAR_VALMAX:
        LD      DE,(VAR_MAX)
        EX      DE,HL
        CALL    CPHLDES
        EX      DE,HL
        RET     NC
        LD      HL,(VAR_MIN)
        RET

;**********************************************
; �����窠 DISPLAY
; ����砥� ��� ।���஢����
;**********************************************
DISP:
        BIT     6,A
        RET     NZ

        LD      A,(TERM_MODE)
        OR      A
        JR      NZ,DISP_ENTR
        LD      A,1
        LD      (TERM_MODE),A   ; ०�� �롮� ��६�����

        LD      A,(VAR_NUM)
        LD      (VAR_NUMED),A

        LD      HL,VAR_CASE
        LD      DE,VAR_PNTR
        LD      BC,16
        LDIR
        LD      HL,(VAR_VIEW)
        PUSH    HL
        RET

DISP_ENTR:
        XOR     A
        LD      (TERM_MODE),A

        LD      A,(VAR_NUMED)
DISP_INT:
        LD      (VAR_NUM),A
        LD      L,A
        LD      H,16
        MLT     HL
        LD      DE,VAR_TABLE
        ADD     HL,DE
;
        LD      DE,VAR_PNTR
        LD      BC,16
        LDIR
;
        LD      HL,(VAR_VIEW)
        PUSH    HL
        RET
;
VAR_CASE:
        DW      VAR_NUMED
        DW      0               ; 1 ����
        DW      0,VAR_NMAX
        DW      RFSHM
        DW      DID
        DW      CHR_N
        DW      0

;**********************************************
; �⮡ࠦ���� ��६����� �� ��ᯫ��
;**********************************************
RFSHM:
        CALL    RD_VAR
        JR      RFSH_0
RFSH:
        CALL    RD_VAR
        LD      DE,(VAR_OLD)
        CALL    CPHLDE
        RET     Z
        LD      (VAR_OLD),HL
RFSH_0:
        LD      A,(VAR_TYPE)
        BIT     0,A     ; 1 ����
        JR      Z,RFSHD_0
        BIT     1,A     ; �ਧ��� HEX
        JR      Z,RFSHD_0
; �⮡ࠦ���� �� 2 ࠧ� ��. ��. ����� � � HEX
        PUSH    HL
        LD      L,H
        LD      H,0
        LD      A,(VAR_MASK+1)
        CALL    PRINT_BCDT

        POP     HL
        LD      H,0
        LD      A,(VAR_MASK)
        CALL    PRINT_BCD
        RET

RFSHD_0:
        CALL    BIN2DEC
        LD      A,(VAR_MASK)
        CALL    PRINT_BCD
        RET

;**********************************************
; ������������ ����������� ������
;**********************************************
MODE:
        BIT     6,A
        RET     NZ
	CALL	ALL_ROYAL
	CALL	ALL_ON
	CALL	TRANS_RES

        LD      A,(GEN_MODE)
        OR      A
        JR      Z,MODE_0

        XOR     A
        LD      (GEN_MODE),A

        CALL    DSP_CNTR

        ADD     A,V_GMODE
        CALL    PLAY_V
        RET
MODE_0:
        INC     A
        LD      (GEN_MODE),A
	CALL	STOP_F

        LD      A,V_GMODE+1
        CALL    PLAY_V

        LD      A,V_GM_BOUNUS
        CALL    DISP_INT

	LD	HL,120
	LD	(G_TEMP),HL
	CALL	CHNG_TEMP

        CALL    GAME_INIT
        RET
SHOW_B:
        LD      A,V_GM_BOUNUS
        CALL    DISP_INT
        RET

;**********************************************
; �࠭ᯮ�� ���� ��஦��
;**********************************************
TRANS:
        BIT     6,A
        RET     NZ

        LD      A,CHR_T
        LD      HL,CHR_R * 256 + CHR_A
        CALL    PRINT_GRPT

        LD      A,V_TRANSB
        CALL    DISP_INT

        RET
TRANS_RES:
	XOR	A
	LD	(TRANSB),A
CHNG_TRANS:

        LD      B,4
        LD      HL,MCH_AREA+MCH_TRANS
        LD      DE,8
        LD      A,(TRANSB)
CHTR_0:
        LD      (HL),A
        ADD     HL,DE
        DJNZ    CHTR_0
        RET
;**********************************************
; �࠭ᯮ�� ���� ��஦��
;**********************************************
TEMPO:
        BIT     6,A
        RET     NZ

        LD      A,CHR_NOP
        LD      HL,CHR_T * 256 + CHR_E
        CALL    PRINT_GRPT

        LD      A,V_TEMP
        CALL    DISP_INT

        RET

;**********************************************
; �롮� �����㬥��
;**********************************************
INSTR:
        BIT     6,A
        RET     NZ

        LD      A,CHR_S
        LD      HL,CHR_O * 256 + CHR_U
        CALL    PRINT_GRPT

        LD      A,V_SEC_INST
        CALL    DISP_INT

        RET

VIEV_INST:
        LD      L,KBD_MCH
        LD      A,(MIDION)
        BIT     MREC_F,A
        JR      Z,VI_0

        LD      A,(M_RECCH)
        LD      L,A
VI_0:
        LD      H,8
        MLT     HL
        LD      DE,MCH_AREA + MCH_PRG
        ADD     HL,DE
        LD      A,(HL)
        LD      (SEC_INST),A
        RET

CHANGE_INST:
        LD      L,KBD_MCH
        LD      A,(MIDION)
        BIT     MREC_F,A
        JR      Z,CI_0

        LD      A,(M_RECCH)
        LD      L,A
CI_0:
        LD      H,8
        MLT     HL
        LD      DE,MCH_AREA + MCH_PRG
        ADD     HL,DE
        LD      A,(SEC_INST)
        LD      (HL),A
        RET


;**********************************************
; �롮� �������
;**********************************************
MELODY:
        BIT     6,A
        RET     NZ

        LD      A,CHR_F
        LD      HL,CHR_I * 256 + CHR_L
        CALL    PRINT_GRPT

        LD      A,V_SEC_FILE
        CALL    DISP_INT
        RET

CHANGE_FILE:
	CALL	STOP_F
	CALL	ALL_ROYAL
	CALL	ALL_ON
	CALL	TRANS_RES

        LD      A,(SEC_FILE)
	OR	A
	JR	Z,FILE_0
	LD      C,A
        LD      B,05H           ; �ᥢ����⠫�� 䠩��
        LD      DE,LO_MEM
        CALL    LOAD_F
        JR      C,FILE_0ERR    ; HL = SIZE FILE

        CALL    INIT_F
        CALL    STOP_F
        RET

FILE_0ERR:
	CALL      PRINT_ERRT    ; HL = SIZE FILE
FILE_0:
        XOR     A
        LD      (SEC_FILE),A
        LD      HL,EMP_FILE
        LD      DE,LO_MEM
        LD      BC,MTRK_E - EMP_FILE
        LDIR

        CALL    INIT_F
        CALL    STOP_F
	RET
FILE_0M:
	CALL	FILE_0
	LD	A,CHR_C
	LD	HL,CHR_L * 256 + CHR_R
	CALL	PRINT_GRPT
        RET
EMP_FILE:
        DB      "MThd",00,00,00,06
        DB      00,00,00,01,00,96
        DB      "MTrk",00,00,00,MTRK_E - MTRK_B
MTRK_B:
        DB      000H,0FFH,058H,004H,004H,002H,018H,008H
;       DB      000H,0FFH,051H,003H,007H,0A1H,020H
        DB      0,0FFH,02FH,000H
MTRK_E:

FILE_1:
        XOR     A
        LD      (SEC_FILE),A
        LD      HL,EMP_FILE1
        LD      DE,LO_MEM
        LD      BC,MTRK_E1 - EMP_FILE1
        LDIR

        CALL    INIT_F
        CALL    STOP_FM
        RET
EMP_FILE1:
        DB      "MThd",00,00,00,06
        DB      00,00,00,01,00,96
        DB      "MTrk",00,00,00,MTRK_E1 - MTRK_B1
MTRK_B1:
        DB      000H,0FFH,058H,004H,004H,002H,018H,008H
;       DB      000H,0FFH,051H,003H,007H,0A1H,020H
        DB      48,91H,76,127
        DB      24,81H,76,127,0,91H,67,127
        DB      24,81H,67,127,0,91H,72,127
        DB      48,81H,72,127
        DB      0,0FFH,02FH,000H
MTRK_E1:
FILE_2:
        XOR     A
        LD      (SEC_FILE),A
        LD      HL,EMP_FILE2
        LD      DE,LO_MEM
        LD      BC,MTRK_E2 - EMP_FILE2
        LDIR

        CALL    INIT_F
        CALL   STOP_FM
        RET
EMP_FILE2:
        DB      "MThd",00,00,00,06
        DB      00,00,00,01,00,96
        DB      "MTrk",00,00,00,MTRK_E2 - MTRK_B2
MTRK_B2:
        DB      000H,0FFH,058H,004H,004H,002H,018H,008H
;       DB      000H,0FFH,051H,003H,007H,0A1H,020H
        DB      48,91H,73,127,0,92H,67,127
        DB      96,81H,73,127,0,82H,67,127,0,91H,72,127
        DB      24,81H,72,127
        DB      0,0FFH,02FH,000H
MTRK_E2:
;**********************************************
; ���
;**********************************************
LAD:
        BIT     6,A
        RET     NZ

        LD      A,(GM_LAD)
        INC     A
        AND     3
        LD      (GM_LAD),A
        ADD     V_LAD
        CALL    PLAY_V

        CALL    GAME_INIT
        RET
;**********************************************
; ��㪮��
;**********************************************
SND_LINE:
        BIT     6,A
        RET     NZ

        LD      A,(GM_ZVUK)
        INC     A
        AND     1
        LD      (GM_ZVUK),A

        ADD     V_ZVUK
        CALL    PLAY_V

        CALL    GAME_INIT
        RET
;**********************************************
; �������� ���
;**********************************************

VERSION:                ; ��ਠ��
        BIT     6,A
        RET     NZ

        LD      A,(GM_MODE)
        INC     A
        CP      6
        JR      C,VERS_0
        XOR     A
VERS_0:
        LD      (GM_MODE),A
        ADD     V_VER
        CALL    PLAY_V

        CALL    GAME_INIT
        RET
;**********************************************
; ���஭��
;**********************************************
METR:
        BIT     6,A
        RET     NZ

        LD      A,(GEN_MODE)
        OR      A
        JR      NZ,METR_GM

        LD      A,(MIDION)
        BIT     MMET_F,A
        JP      NZ,METROFF


        SET     MMET_F,A
        LD      (MIDION),A
        LD      A,CHR_NOP
        LD      HL,CHR_O * 256 + CHR_N
        CALL    PRINT_GRPT
        RET

METROFF:
        RES     MMET_F,A
        LD      (MIDION),A
        LD      A,CHR_O
        LD      HL,CHR_F * 256 + CHR_F
        CALL    PRINT_GRPT

        LD      A,80H + METR_CH
        LD      DE,METR_H
        CALL    MIDIIN

        LD      A,80H + METR_CH
        LD      DE,METR_L
        CALL    MIDIIN
        RET

METR_GM:
        LD      A,(GM_METR)
        AND     1
        XOR     1
        LD      (GM_METR),A
        ADD     2
        CALL    BIN2CHAR
        LD      HL,CHR_D * 256 + CHR_O
        CALL    PRINT_GRPT
        RET

;**********************************************
; �⮯
;**********************************************
STOP:
        BIT     6,A
        RET     NZ

        LD      A,(MIDION)
        BIT     MREC_F,A
        JP      NZ,RECORD_OFF

        CALL    STOP_F

        LD      A,CHR_S
        LD      HL,CHR_T * 256 + CHR_O
        CALL    PRINT_GRPT
        RET

;**********************************************
; ��㧠
;**********************************************
PAUSE:
        BIT     6,A
        RET     NZ

        LD      A,(MIDION)
        BIT     MCLK_F,A
        JR      NZ,PAUSE_0

        LD      A,CHR_P
        LD      HL,CHR_L * 256 + CHR_A
        CALL    PRINT_GRPT

        CALL    PLAY_F
        RET

PAUSE_0:
        CALL    PAUSE_F

        XOR     A
        CALL    DSP_CNTR

        LD      A,CHR_P
        LD      HL,CHR_A * 256 + CHR_U
        CALL    PRINT_GRPT
        RET
;**********************************************
; ������
;**********************************************
RECORD:
        BIT     6,A
        RET     NZ

        LD      A,(MIDION)
        BIT     MREC_F,A
        JP      NZ,RECORD_OFF

        SET     MREC_F,A
        LD      (MIDION),A
REC_CHANEL:
        LD      A,(M_RECCH)
        CALL    BIN2CHAR
        LD      HL,CHR_R * 256 + CHR_E
        CALL    PRINT_GRPT
        CALL    RES_RPNTR
        RET

RECORD_OFF:
        LD      A,CHR_S
        LD      HL,CHR_T * 256 + CHR_O
        CALL    PRINT_GRPT

        LD      A,(MIDION)
        RES     MREC_F,A
        LD      (MIDION),A
        BIT     MSYN_F,A
        RET     Z
        RES     MSYN_F,A
        LD      (MIDION),A

        LD      A,0FFH
        LD      DE,2FH
        CALL    REC_MIDI_ON     ; EOF TRK

        CALL    STOP_F
        RET

;**********************************************
; ����⪠ �����
;**********************************************
MARK:
        BIT     6,A
        RET     NZ

        CALL    MARK_F
        RET

;**********************************************
; ������ SHIFT
;**********************************************
SHIFT:
        BIT     6,A
        JR      NZ,SHIFT_UP
        LD      A,1
        LD      (SHIFT_F),A
        RET
SHIFT_UP:
        XOR     A
        LD      (SHIFT_F),A
        RET
;**********************************************
; ��ࠢ����� ��������
;**********************************************
CHANELS:
        BIT     6,A
        RET     NZ

        SUB     36      ; 36,37,.. -> 0,1,2,..

        LD      E,A
        LD      A,(MIDION)
        BIT     MREC_F,A
        JR      Z,NO_REC
; �᫨ ������ � ����� ����� �� ������
        LD      A,E
        LD      (M_RECCH),A
        CALL    REC_CHANEL
        RET
; ���� ������� �몫���� �����
NO_REC:
        LD      A,E
        LD      D,8
        MLT     DE
        LD      HL,MCH_AREA+MCH_OFF
        ADD     HL,DE
        LD      E,A     ; REST TMP
        LD      A,(HL)
        XOR     1
        LD      (HL),A
        JR      Z,CHS_ON
; ����� �몫�祭
CHS_OFF:
        LD      A,E
        CALL    BIN2CHAR
        LD      HL,CHR_O * 256 + CHR_F
        CALL    PRINT_GRPT
        RET
CHS_ON:
        LD      A,E
        CALL    BIN2CHAR
        LD      HL,CHR_O * 256 + CHR_N
        CALL    PRINT_GRPT
        RET
;**********************************************
; ������ �������
;**********************************************
CHANELSR:
        BIT     6,A
        RET     NZ

        SUB     36+5

        LD      E,A
        LD      D,8
        MLT     DE
        LD      HL,MCH_AREA+MCH_PRG
        ADD     HL,DE
        LD      E,A     ; SAVE TMP
        LD      A,(HL)
        AND     1
        XOR     1
        LD      (HL),A
        JR      Z,CHS_ONB
; ����� ����祭 � A
        LD      A,E
        CALL    BIN2CHAR
        LD      HL,CHR_V * 256 + CHR_O
        CALL    PRINT_GRPT
        RET
CHS_ONB:
        LD      A,E
        CALL    BIN2CHAR
        LD      HL,CHR_R * 256 + CHR_O
        CALL    PRINT_GRPT
        RET
OLLV:
        BIT     6,A
        RET     NZ
ALL_ON:
        LD      A,0
        LD      (MCH_AREA+MCH_OFF),A
        LD      (MCH_AREA+MCH_OFF+8),A
;        LD      (MCH_AREA+MCH_OFF+16),A
;        LD      (MCH_AREA+MCH_OFF+24),A
        RET

ALL_ROYAL:
	XOR	A
	JR	OLLR_0
OLLR:
        BIT     6,A
        RET     NZ

        LD      A,(MCH_AREA+MCH_PRG)
        XOR     1
OLLR_0:
        LD      (MCH_AREA+MCH_PRG),A
        LD      (MCH_AREA+MCH_PRG+8),A
;        LD      (MCH_AREA+MCH_PRG+16),A
;        LD      (MCH_AREA+MCH_PRG+24),A
        RET

KBINS:
        BIT     6,A
        RET     NZ

        LD      A,(MCH_AREA+MCH_PRG+(8*KBD_MCH))
        XOR     1
        LD      (MCH_AREA+MCH_PRG+(8*KBD_MCH)),A
        OR      A
        LD      A,CHR_R
        LD      HL,CHR_O * 256 + CHR_Y
        JP      Z,PRINT_GRPT
        LD      A,CHR_V
        LD      HL,CHR_O * 256 + CHR_I
        JP      PRINT_GRPT

;**********************************************
; 㡨�� ������
;**********************************************
DID:
        RET


;CNTR1:
;        BIT     6,A
;        RET     NZ
;	LD	A,V_CONTR
;	JP	DISP_INT
;CNTR2:
;        BIT     6,A
;        RET     NZ
;	LD	A,V_CONTR+1
;	JP	DISP_INT
;CNTR3:
;        BIT     6,A
;        RET     NZ
;	LD	A,V_CONTR+2
;	JP	DISP_INT

SPLITM:
	BIT	6,A
	RET	NZ
	LD	A,(SPLIT)
	XOR	1
	LD	(SPLIT),A

	JR	Z,SPL_OFF
	LD	A,CHR_S
	LD	HL,CHR_P * 256 + CHR_L
	CALL	PRINT_GRPT
	RET
SPL_OFF:
	LD	A,CHR_F
	LD	HL,CHR_U * 256 + CHR_L
	CALL	PRINT_GRPT
	RET


		
;**********************************************
; �� ����� ����� ������ ���� �ணࠬ�� ��ࠡ�⪨
;**********************************************
KEY_TABLE:
        DW      MODE            ; ०�� ࠡ���
        DW      MELODY          ; * �롮� �������
        DW      STOP            ; ���ந�������� - �⮯
        DW      RECORD          ; * ������
        DW      PAUSE           ; ��㧠
        DW      MARK            ; ����⪠ ��થࠬ�
;
        DW      TEMPO           ; �࠭ᯮ��
        DW      TRANS           ; �࠭ᯮ��
;
        DW      METR            ; * ���஭�� ���-�몫
        DW      DID             ; ��� ( ���� )
        DW      DID             ; * ��ਠ�� ( ���� )
        DW      DID             ; ��㪮�� ( ���� )
;

        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID                                 ;30

        DW      CHANELS,CHANELS,DID,DID,OLLV
        DW      CHANELSR,CHANELSR,CHANELSR,SPLITM,OLLR

        DW      FILE_0M,SHIFT
        DW      CHANGE_FILE     ; ��� ����������

KEY_TABLESH:
        DW      DID	   ; ०�� ࠡ���
        DW      SHOW_B     ; * �롮� �������
        DW      DID        ; ���ந�������� - �⮯
        DW      DID        ; * ������
        DW      DID        ; ��㧠
        DW      DID        ; ����⪠ ��થࠬ�
;
        DW      DID        ; �࠭ᯮ��
        DW      DID        ; �࠭ᯮ��
;
        DW      DID        ; * ���஭�� ���-�몫
        DW      DID        ; ��� ( ���� )
        DW      DID        ; * ��ਠ�� ( ���� )
        DW      DID        ; ��㪮�� ( ���� )
;
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID

	IF	NETWORK
        DW      NETS,NETS,NETS,NETS,NETS,NETS,NETS,NETS
        DW      NETS,NETS,NETS
        ELSE
        DW      DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT
        DW      DIGIT,DIGIT,SIGN
	ENDIF

	DW	SHIFT,DISP

KEY_TABLEG:
        DW      MODE            ; ०�� ࠡ���
        DW      SHOW_B          ; * ����� �����
        DW      DID             ; ���ந�������� - �⮯
        DW      DID             ; * ������
        DW      DID             ; ��㧠
        DW      DID             ; ����⪠ ��થࠬ�
;
        DW      TEMPO           ; �࠭ᯮ��
        DW      TRANS           ; �࠭ᯮ��
;
        DW      METR            ; * ���஭�� 2-3 � �����
        DW      LAD             ; ��� ( ���� )
        DW      VERSION         ; * ��ਠ�� ( ���� )
        DW      SND_LINE        ; ��㪮�� ( ���� )
;

        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID                                 ;30

        DW      DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID

        DW      DID,SHIFT
        DW      DID


KEY_TABLESHG:
        DW      DID             ; ०�� ࠡ���
        DW      DID             ; * �롮� �������
        DW      DID ;CNTR1           ; ���ந�������� - �⮯
        DW      DID ;CNTR2           ; * ������
        DW      DID ;CNTR3           ; ��㧠
        DW      DID             ; ����⪠ ��થࠬ�
;
        DW      DID             ; �࠭ᯮ��
        DW      DID             ; �࠭ᯮ��
;
        DW      DID             ; * ���஭�� ���-�몫
        DW      DID             ; ��� ( ���� )
        DW      DID             ; * ��ਠ�� ( ���� )
        DW      DID             ; ��㪮�� ( ���� )
;
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID,DID

	IF	RAM

        DW      DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT,DIGIT
        DW      DIGIT,DIGIT

        DW      SIGN,SHIFT
        DW      DISP

	ELSE

        DW      DID,DID,DID,DID,DID
        DW      DID,DID,DID,DID,DID

        DW      DID,SHIFT
        DW      DID
	
	ENDIF