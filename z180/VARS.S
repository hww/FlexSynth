	SECTION	ICODE

;**********************************************
; Таблица переменных системы
;**********************************************
;	Порядковый номер соответствует номеру переменной
;+0	DW	0	адрес переменной
;+2	DW	0	тип и размер переменной
;+4	DW	0,0	минимальное, максимальное значение
;+8	DW	0	программа обработки вывода на дисплей
;+A	DW	0	программа обработки изменения
;+C	DW	0	маска вывода на дисплей
;+E	DW	0

VAR_TABLE:

;**********************************************
; instrument
	DW	MCH_AREA    ,0,   0,   1,      RFSHM,     DID,0000H,0
	DW	MCH_AREA+8  ,0,   0,   1,      RFSHM,     DID,0000H,0
	DW	MCH_AREA+16 ,0,   0,   1,      RFSHM,     DID,0000H,0
	DW	MCH_AREA+24 ,0,   0,   1,      RFSHM,     DID,0000H,0
	DW	MCH_AREA+36 ,0,   0,   1,      RFSHM,     DID,0000H,0
	DW	MCH_AREA+48 ,0,   0,   1,      RFSHM,     DID,0000H,0
;**********************************************
; tranpose
	DW	MCH_AREA+1  ,0, -24,  24,      RFSHM, 	DID,0000H,0	
	DW	MCH_AREA+9  ,0, -24,  24,      RFSHM, 	DID,0000H,0	
	DW	MCH_AREA+17 ,0, -24,  24,      RFSHM, 	DID,0000H,0	
	DW	MCH_AREA+25 ,0, -24,  24,      RFSHM, 	DID,0000H,0	
	DW	MCH_AREA+33 ,0, -24,  24,      RFSHM, 	DID,0000H,0	
	DW	MCH_AREA+41 ,0, -24,  24,      RFSHM, 	DID,0000H,0	
;**********************************************
; сдвиг клавиатуры
	DW	KBD_REL     ,0,   0, 36,      RFSHM,     DID,0000H,24	
;**********************************************
; сдвиг строя всех треко
V_TRANSB	EQU	($-VAR_TABLE)/16
	DW	TRANSB     ,0, -36,    36,     RFSHM,CHNG_TRANS,0000H,0	
;**********************************************
; Текущий миди файл
V_SEC_FILE	EQU	($-VAR_TABLE)/16
	DW	SEC_FILE    ,0,   0,  42,      RFSHM,   DID,0000H,0	
;**********************************************
; Текущий инструмент
V_SEC_INST	EQU	($-VAR_TABLE)/16
	DW	SEC_INST    ,0,   0,   1,VIEV_INST,CHANGE_INST,0000H,0	
;**********************************************
; подстройка VELOCITY
	DW	VELOCITY    ,0,   0,    7,     RFSHM,     DID,0000H,0	
;**********************************************
; MAIN TEMP
V_TEMP:	EQU	($-VAR_TABLE)/16
	DW	G_TEMP      ,1,   0,  256,     RFSHM,CHNG_TEMP,0000H,120	
;**********************************************
; MAIN QUADR_CTR
V_POS:	EQU	($-VAR_TABLE)/16
	DW	G_Q_NUM   ,81H,   0,  256,     RFSHM,     DID,0000H,0	
;**********************************************
; METR_SEC
	DW	G_METR      ,0,   0,   64,     RFSHM,     DID,0000H,0	
;**********************************************
; T_SIG
	DW	T_SIG       ,0,   0,   64,     RFSHM,     DID,0000H,0	
	DW	T_SIG+1     ,0,   0,  255,     RFSHM,     DID,0000H,0	
	DW	T_SIG+2     ,0,   0,  255,     RFSHM,     DID,0000H,0	
	DW	T_SIG+3     ,0,   0,  255,     RFSHM,     DID,0000H,0	
	DW	G_QUANT     ,0,   0,  255,     RFSHM,     DID,0000H,0	
;**********************************************
; MAIN SECOND CONTROLERS
V_CONTR: EQU	($-VAR_TABLE)/16
	DW	SPITCH      ,0,-127,  128,     RFSHM,     DID,0000H,0
	DW	SMODUL      ,0,-127,  128,     RFSHM,     DID,0000H,0
	DW	SVOL        ,0,-127,  128,     RFSHM,     DID,0000H,0
;**********************************************
; MAIN VOL
V_GVOL:	EQU	($-VAR_TABLE)/16
	DW	MAIN_VOL    ,0,-127,  128,     RFSHM,     DID,0000H,0
; MAIN VOLA
	DW	VOL_A       ,0,-127,  128,     RFSHM,     DID,0000H,0
; MAIN VOLB
	DW	VOL_B       ,0,-127,  128,     RFSHM,     DID,0000H,0
;**********************************************
; подстройка TUNE
	DW	TUNE        ,3,8000H,7FFFH,    RFSHM,     DID,7638H,0	
;**********************************************
; MAIN MIDI
	DW	MARK_FL     ,0,-127,  128,     RFSHM,     DID,0000H,0
	DW	MIDION      ,0,-127,  128,     RFSHM,     DID,0000H,0

;**********************************************
; TMR
	DW	REC_PNTR    ,3,8000H,7FFFH,    RFSHM,     DID,7638H,0	
;**********************************************
; games
	DW	GM_PHASE    ,4,-127,  128,     RFSHM,     DID,0000H,0
	DW	GM_INPUT    ,4,-127,  128,     RFSHM,     DID,0000H,0
	DW	GM_PNTR     ,4,-127,  128,     RFSHM,     DID,0000H,0
	DW	GM_NOTE     ,4,-127,  128,     RFSHM,     DID,0000H,0
	DW	GM_STAGE    ,4,-127,  128,     RFSHM,     DID,0000H,0	
V_GM_BOUNUS:	EQU	($-VAR_TABLE)/16
	DW	GM_BOUNUS   ,4,-127,  128,     RFSHM,     DID,0000H,0	
;**********************************************
; Генератор последовательности
	DW	GM_NBUF     ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+1   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+2   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+3   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+4   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+5   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+6   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+7   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	DW	GM_NBUF+8   ,4,-127,  128,     RFSHM,     DID,0000H,0	
	
;**********************************************
	DW	NET_MODE    ,4,-127,  128,     RFSHM,     DID,0000H,0	

VAR_NMAX:	EQU	($-VAR_TABLE)/16-1
