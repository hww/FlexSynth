;**********************************************
;       РАБОТА С МИДИ ФАЙЛОМ
;**********************************************
        SECTION WORK


MIDION:         DB      0
M_RECCH:        DB      0       ; запись в канал ( was 3)
REC_PNTR:       DW      0       ; поинтер на запись

M_BEGIN0:       DW      0       ; начало адрес в байтах трек 0
M_BEGIN1:       DW      0       ; начало адрес в байтах трек 1
;M_BEGIN2:       DW      0       ; начало адрес в байтах трек 2
;M_BEGIN3:       DW      0       ; начало адрес в байтах трек 3
M_END:          DW      0       ; конец адрес в байтах трек 3

M_PNTR0:        DW      0       ; поинтер указывает текущую позицию
M_PNTR1:        DW      0       ; поинтер указывает текущую позицию
;M_PNTR2:        DW      0       ; поинтер указывает текущую позицию
;M_PNTR3:        DW      0       ; поинтер указывает текущую позицию

MARK_FL:        DB      0       ; флаги для пометки блока

L_MIDION:       DB      0
L_PNTR0:        DW      0       ; зацикливание в байтах
L_PNTR1:        DW      0       ; зацикливание в байтах
;L_PNTR2:        DW      0       ; зацикливание в байтах
;L_PNTR3:        DW      0       ; зацикливание в байтах
L_TMRL:         DW      0       ; таимер для зацикливания
L_TMRH:         DW      0
L1_TMRL:        DW      0       ; таймер для конечного зацикливания
L1_TMRH:        DW      0

L_DTIME0L:      DW      0       ; делдьта тиме для каналов
L_DTIME0H:      DW      0
L_DTIME1L:      DW      0
L_DTIME1H:      DW      0
;L_DTIME2L:      DW      0
;L_DTIME2H:      DW      0
;L_DTIME3L:      DW      0
;L_DTIME3H:      DW      0

PREV_CMD:       DB      0,0
T_SIG:          DB      4,2,24,8
TEMP:           DB      20H,0A1H,07H,0

SRCH_Q:         DW      0       ; четверти для поиска
SPEED:          DB      0

        SECTION ICODE

;**********************************************
;       Формирование темпа
;**********************************************
;**********************************************
; Установка на начало файла
;**********************************************
INIT_F:
        LD      A,(TRK_NUM)     ; количество треков
        LD      HL,T0_MEM
; A = количество треков HL =  начало трека      0
                                ; HL = начало трека
        LD      (M_BEGIN0),HL   ; начало файла трек 0
        CALL    LDSIZE          ; DE = размер
        ADD     HL,DE
        DEC     A
        JR      Z,INIT_F0

        LD      (M_BEGIN1),HL   ; начало трека 1
        CALL    LDSIZE          ; DE = размер
        ADD     HL,DE
;        DEC     A
;        JR      Z,INIT_F0

;        LD      (M_BEGIN2),HL   ; начало трека 2
;       CALL    LDSIZE          ; DE = размер
;        ADD     HL,DE
;        DEC     A
;        JR      Z,INIT_F0

;        LD      (M_BEGIN3),HL   ; начало трека 3
;       CALL    LDSIZE          ; DE = размер
;        ADD     HL,DE

INIT_F0:
        LD      A,(TRK_NUM)
;        CP      4
;        JR      Z,INIT_F4
;        CP      3
;        JR      Z,INIT_F3
        CP      2
        JR      Z,INIT_F2
INIT_F1:
        LD      (M_BEGIN1),HL   ; начало трека 1
        CALL    ADD_ZEROTRK
INIT_F2:
;        LD      (M_BEGIN2),HL   ; начало трека 2
;        CALL    ADD_ZEROTRK
;INIT_F3:
;        LD      (M_BEGIN3),HL   ; начало трека 3
;        CALL    ADD_ZEROTRK
;INIT_F4:
        LD      (M_END),HL

UNJOIN:
;        LD      DE,(M_BEGIN3)
;       OR      A
;      SBC     HL,DE
;        PUSH    HL
;        POP     BC
;        LD      HL,T3_MEM
;        EX      DE,HL
;        LDIR
;
;        LD      HL,(M_BEGIN3)
;        LD      DE,(M_BEGIN2)
;        OR      A
;        SBC     HL,DE
;        PUSH    HL
;        POP     BC
;        LD      HL,T2_MEM
;        EX      DE,HL
;        LDIR
;
;        LD      HL,(M_BEGIN2)
        LD      DE,(M_BEGIN1)
        OR      A
        SBC     HL,DE
        PUSH    HL
        POP     BC
        LD      HL,T1_MEM
        EX      DE,HL
        LDIR
;
        LD      HL,T1_MEM
        LD      (M_BEGIN1),HL
;        LD      HL,T2_MEM
;        LD      (M_BEGIN2),HL
;       LD      HL,T3_MEM
;        LD      (M_BEGIN3),HL
        RET

LDSIZE:
        LD      DE,6
        ADD     HL,DE   ; пропустили заголовок Chuck

        LD      D,(HL)
        INC     HL
        LD      E,(HL)
        INC     HL
        RET

ADD_ZEROTRK:
        LD      DE,TRK_ZERO
        LD      BC,12
        EX      DE,HL
        LDIR
        EX      DE,HL
        RET

TRK_ZERO:
        DB      "MTrk",0,0,0,4
        DB      000H,0FFH,02FH,000H

;**********************************************
; Пометка файла
;**********************************************
REMARK:
        XOR     A
        LD      (MARK_FL),A

        LD      A,0FH
        LD      (L_MIDION),A

        LD      HL,(M_PNTR0)
        LD      (L_PNTR0),HL
        LD      HL,(M_PNTR1)
        LD      (L_PNTR1),HL
;        LD      HL,(M_PNTR1) 	это была ошибка
;        LD      (L_PNTR1),HL
;        LD      HL,(M_PNTR1)
;        LD      (L_PNTR1),HL

        LD      HL,0
        LD      (L_DTIME0L),HL
        LD      (L_DTIME0H),HL
        LD      (L_DTIME1L),HL
        LD      (L_DTIME1H),HL
;        LD      (L_DTIME2L),HL
;       LD      (L_DTIME2H),HL
;        LD      (L_DTIME3L),HL
;        LD      (L_DTIME3H),HL

        LD      (L_TMRL),HL
        LD      (L_TMRH),HL
        DEC     HL
        LD      (L1_TMRL),HL
        LD      (L1_TMRH),HL
        RET

MARK_F:
        LD      A,(MARK_FL)
        BIT     0,A
        JR      NZ,MARK_B
MARK_T:                         ; >>>>>>>>>>>>>T.............B<<<<<<<<<<<
        LD      A,3
        LD      (MARK_FL),A

        LD      A,(MIDION)
        LD      (L_MIDION),A    ; MIDION

        LD      HL,(M_PNTR0)
        LD      (L_PNTR0),HL    ; PNTR 0
        LD      HL,(M_PNTR1)
        LD      (L_PNTR1),HL    ; PNTR 1
;        LD      HL,(M_PNTR2)
;       LD      (L_PNTR2),HL    ; PNTR 2
;        LD      HL,(M_PNTR3)
;        LD      (L_PNTR3),HL    ; PNTR 3

        LD      HL,(G_TMRL)
        LD      (L_TMRL),HL
        LD      HL,(G_TMRH)
        LD      (L_TMRH),HL     ; TMRL & TMRH

        LD      DE,(G_DTIME0L)
        LD      HL,(G_DTIME0H)
        LD      (L_DTIME0L),DE
        LD      (L_DTIME0H),HL  ; DTIMEL & DTIMEH

        LD      DE,(G_DTIME1L)
        LD      HL,(G_DTIME1H)
        LD      (L_DTIME1L),DE
        LD      (L_DTIME1H),HL  ; DTIMEL & DTIMEH

;        LD      DE,(G_DTIME2L)
;        LD      HL,(G_DTIME2H)
;        LD      (L_DTIME2L),DE
;        LD      (L_DTIME2H),HL  ; DTIMEL & DTIMEH

;        LD      DE,(G_DTIME3L)
;        LD      HL,(G_DTIME3H)
;        LD      (L_DTIME3L),DE
;        LD      (L_DTIME3H),HL  ; DTIMEL & DTIMEH

        LD      A,CHR_R
        LD      HL,CHR_T
        CALL    PRINT_GRPT
        RET
MARK_B:
        LD      A,2
        LD      (MARK_FL),A

        LD      DE,(G_TMRL)
        LD      HL,(G_TMRH)
        LD      (L1_TMRL),DE
        LD      (L1_TMRH),HL

        LD      A,CHR_R
        LD      HL,CHR_B
        CALL    PRINT_GRPT
        RET

; OUT HL = SEC POINTER
TOMARK:
        LD      A,(L_MIDION)
        AND     CH_MASK
        LD      D,A
        LD      A,(MIDION)
        AND     CH_MASK
        OR      D
        LD      (MIDION),A

        LD      DE,(L_TMRL)
        LD      HL,(L_TMRH)
        LD      (G_TMRL),DE
        LD      (G_TMRH),HL     ; TMRL & TMRH

        LD      DE,(L_DTIME0L)
        LD      HL,(L_DTIME0H)
        LD      (G_DTIME0L),DE
        LD      (G_DTIME0H),HL  ; DTIMEL & DTIMEH

        LD      DE,(L_DTIME1L)
        LD      HL,(L_DTIME1H)
        LD      (G_DTIME1L),DE
        LD      (G_DTIME1H),HL  ; DTIMEL & DTIMEH

;        LD      DE,(L_DTIME2L)
;        LD      HL,(L_DTIME2H)
;        LD      (G_DTIME2L),DE
;        LD      (G_DTIME2H),HL  ; DTIMEL & DTIMEH

;        LD      DE,(L_DTIME3L)
;        LD      HL,(L_DTIME3H)
;        LD      (G_DTIME3L),DE
;        LD      (G_DTIME3H),HL  ; DTIMEL & DTIMEH

        LD      HL,(L_PNTR0)
        LD      (M_PNTR0),HL    ; PNTR & PNTRV

        LD      HL,(L_PNTR1)
        LD      (M_PNTR1),HL    ; PNTR & PNTRV

;        LD      HL,(L_PNTR2)
;        LD      (M_PNTR2),HL    ; PNTR & PNTRV

;        LD      HL,(L_PNTR3)
;        LD      (M_PNTR3),HL    ; PNTR & PNTRV

        LD      A,(L_MIDION)
        BIT     MCLK_F,A
        RET     NZ              ; был плей
        JP      PLAY_F

;**********************************************
;       Останов файла
;**********************************************

STOP_F:
        XOR     A
        CALL    DSP_CNTR
STOP_FM:
        LD      A,(MIDION)
        RES     MCLK_F,A
        RES     MREC_F,A
        RES     MSYN_F,A
        OR      CH_MASK         ; CH[0..3] IS ON
        LD      (MIDION),A
        LD      BC,8            ; размер заголовка
        LD      HL,(M_BEGIN0)
        ADD     HL,BC
        LD      (M_PNTR0),HL
        LD      HL,(M_BEGIN1)
        ADD     HL,BC
        LD      (M_PNTR1),HL
;        LD      HL,(M_BEGIN2)
;        ADD     HL,BC
;        LD      (M_PNTR2),HL
;        LD      HL,(M_BEGIN3)
;       ADD     HL,BC
;        LD      (M_PNTR3),HL

        CALL    RES_RPNTR
        CALL    RES_DTIMER      ; сбросим дельтатаймер
        CALL    REMARK
        RET

RES_RPNTR:
        CALL    GET_RPNTR
        LD      (REC_PNTR),HL
        RET

GET_RPNTR:
        LD      A,(M_RECCH)
        LD      HL,T0_MEM+8
        OR      A
        RET     Z
        LD      HL,T1_MEM+8
;        DEC     A
;        RET     Z
;        LD      HL,T2_MEM+8
;        DEC     A
;        RET     Z
;        LD      HL,T3_MEM+8
        RET

;**********************************************
; ПАУЗА
;**********************************************
PAUSE_F:
        LD      A,(MIDION)
        RES     MCLK_F,A
        RES     MSYN_F,A
        LD      (MIDION),A
        RET

;**********************************************
;       Воспроизведение файла
;**********************************************

PLAY_F:
        LD      A,(MIDION)
        SET     MCLK_F,A
        LD      (MIDION),A
        BIT     MREC_F,A
        JR      Z,PLF_NR

        SET     MSYN_F,A
        LD      (MIDION),A
PLF_NR:
        LD      HL,(M_PNTR0)
        LD      DE,T0_MEM + 8
        LD      A,H
        CP      D
        RET     NZ
        LD      A,L
        CP      E
        RET     NZ

        CALL    PLAY_BF2
        LD      (M_PNTR0),HL
        CALL    SET_DTIME0
        JR      NZ,PLF_NR0
        LD      A,(MIDION)
        RES     MPLA_F0,A
        LD      (MIDION),A
PLF_NR0:

        LD      HL,(M_PNTR1)
        CALL    PLAY_BF2
        LD      (M_PNTR1),HL
        CALL    SET_DTIME1
        JR      NZ,PLF_NR1
        LD      A,(MIDION)
        RES     MPLA_F1,A
        LD      (MIDION),A
PLF_NR1:

;        LD      HL,(M_PNTR2)
;        CALL    PLAY_BF2
;        LD      (M_PNTR2),HL
;        CALL    SET_DTIME2
;        JR      NZ,PLF_NR2
;        LD      A,(MIDION)
;        RES     MPLA_F2,A
;        LD      (MIDION),A
;PLF_NR2:

;        LD      HL,(M_PNTR3)
;        CALL    PLAY_BF2
;        LD      (M_PNTR3),HL
;        CALL    SET_DTIME3
;        JR      NZ,PLF_NR3
;        LD      A,(MIDION)
;        RES     MPLA_F3,A
;        LD      (MIDION),A
;PLF_NR3:
        RET

;**********************************************
;       Воспроизвести кусочек Файла
;**********************************************
PLAY_BF:
        CALL    GET_MCMD
        CALL    NC,MIDIIN
        CP      0FFH
        RET     Z
PLAY_BF2:
        CALL    GET_MVAR
        JR      Z,PLAY_BF
        RET

;**********************************************
; Прочитывает миди команду
;IN     HL      Pointer
;OUT    DE      MidiParam
;OUT    A       MidiCommand
;OUT    CF      1 special comand
;**********************************************
GET_MCMD:
        LD      A,(HL)
        OR      A
        JP      M,MAIN_CMD
        LD      A,(PREV_CMD)
        JR      PREV_CMDF
;миди команда в A
MAIN_CMD:
        INC     HL
        LD      (PREV_CMD),A    ; предыдущая команда
PREV_CMDF:
        LD      E,A
        AND     0F0H
        CP      0F0H
        JR      Z,CMD_F
        CP      0C0H
        JR      Z,ONE_PARAM
        CP      0D0H
        JR      Z,ONE_PARAM
;два параметра
        LD      A,E
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        OR      A
        RET
;один параметр
ONE_PARAM:
        LD      A,D
        LD      E,(HL)
        INC     HL
        OR      A
        RET
CMD_F:
        LD      A,(HL)
        INC     HL
        CP      51H
        JR      Z,SET_TEMP
        CP      58H
        JR      Z,TIME_SIGN
        CP      2FH
        JR      Z,EOF_TRK
; разнодлинные клманды
        CALL    GET_MVAR
        LD      A,D
        OR      E
        JR      NZ,BAD_LENGHT
        ADD     HL,BC
        XOR     A
        SCF
        RET
BAD_LENGHT:
        LD      A,0FFH
        SCF
        RET
; Установка темпа
SET_TEMP:
        LD      C,(HL)
        INC     HL
        LD      B,0
        PUSH    HL
        PUSH    BC

        LD      D,0
        LD      E,(HL)
        INC     HL
        LD      B,(HL)
        INC     HL
        LD      C,(HL)
        CALL    SET_TIME

        POP     BC
        POP     HL
        ADD     HL,BC
        XOR     A
        SCF
        RET

; Установка временной сигнатуры
TIME_SIGN:
        LD      DE,T_SIG
        LD      C,(HL)
        LD      B,0
        INC     HL

        LDIR
        XOR     A
        SCF
        RET
; Конец трека
EOF_TRK:
        LD      A,0FFH
        SCF
        RET

;**********************************************
; Прочитывает миди переменную
;IN     HL      Pointer
;OUT    DEBC    Midi Var
;OUT    Z       DEBC=0
;**********************************************
GET_MVAR:
        LD      DE,0
        LD      BC,0    ; VAR = 0

GET_MVARN:
        LD      A,(HL)
        OR      A
        JP      M,NOENDVAR

        OR      C
        LD      C,A
        INC     HL
        OR      B
        OR      E
        OR      D
        RET

NOENDVAR:
        AND     7FH
        OR      C
        LD      C,A

        LD      D,E
        LD      E,B
        LD      B,C
        LD      C,0     ;DEBC=EBC0

        RR      D
        RR      E
        RR      B
        RR      C       ;DEBC=0DDDDDDD DEEEEEEE EBBBBBBB B0000000

        INC     HL
        JR      GET_MVARN
;**********************************************
; Запись миди сообщения
;IN     C DE миди сообщение
;OUT    C DE ---- ---------
;**********************************************

REC_MIDI:
        LD      A,(MIDION)
        BIT     MREC_F,A
        RET     Z

        BIT     MSYN_F,A
        JR      NZ,NO_SYNC

        PUSH    BC
        PUSH    DE
        CALL    PLAY_F
        POP     DE
        POP     BC

NO_SYNC:
        LD      A,C
        AND     0F0H
        LD      B,A
        LD      A,(M_RECCH)
        OR      B

REC_MIDI_ON:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        CALL    CALC_DTIME      ; DEBC = dtime
        LD      HL,(REC_PNTR)
        CALL    PUT_MVAR
        POP     DE
        POP     BC
        POP     AF

        LD      (HL),A
        INC     HL
        LD      (HL),E
        INC     HL
        LD      (HL),D
        INC     HL
        LD      (REC_PNTR),HL
        RET

;**********************************************
; Запишем миди переменную
;IN     HL      Pointer
;IN     DEBC    Midi Var
;OUT    Z       DEBC=0
;**********************************************
PUT_MVAR:
        LD      A,D
        OR      E
        OR      B
        OR      C
        JR      Z,PUT_V4 ; DEBC = 0

        XOR     A

        CALL    RLDEBC
        RL      A
        OR      A       ; CF=0
        RR      C       ; C =0VVV VVVV

        CALL    RLDEB
        RL      A
        SCF             ; CF=1
        RR      B       ; B =1VVV VVVV

        CALL    RLDE
        RL      A
        SCF             ; CF=1
        RR      E       ; E =1VVV VVVV

        RL      D
        RL      A
        SCF             ; CF=1
        RR      D       ; D =1VVV VVVV

        OR      80H     ; A =1000 VVVV

        CP      80H
        JR      NZ,PUT_V0
        LD      A,D
        CP      80H
        JR      NZ,PUT_V1
        LD      A,E
        CP      80H
        JR      NZ,PUT_V2
        LD      A,B
        CP      80H
        JR      NZ,PUT_V3
        JR      PUT_V4

PUT_V0:
        LD      (HL),A
        INC     HL
PUT_V1:
        LD      (HL),D
        INC     HL
PUT_V2:
        LD      (HL),E
        INC     HL
PUT_V3:
        LD      (HL),B
        INC     HL
PUT_V4:
        LD      (HL),C
        INC     HL
        RET

RLDEBC:
        RL      C
        RL      B
        RL      E
        RL      D
        RET
RLDEB:
        RL      B
        RL      E
        RL      D
        RET
RLDE:
        RL      E
        RL      D
        RET
