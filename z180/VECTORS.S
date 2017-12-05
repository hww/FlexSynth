	SECTION	ICODE
	IF	RAM
	PHASE	8000H
	ELSE
	PHASE	0H
	ENDIF
;**********************************************
;	V E C T O R S   T A B L E
;**********************************************
BS:	
;0000	CHKRAM
	JP	CHKRAM
STATION: DB	0AAH,55H	; NN номер рабочей станции

;0005
	JP	BS
	
;0008	INKEY
	JP	BS	
	NOP

;000C	RDSLT
	JP	BS
	NOP

;0010	INPUT
	JP	BS
	NOP

;0014	WRTSLT
	JP	BS
	NOP

;0018	SYMBOL
	JP	BS
	NOP

;001C	CALSLT
	JP	BS
	NOP

;0020	CPHLDE
	JP	CPHLDE
	NOP

;0024	ENASLT
	JP	BS
	NOP

;0028	CPHLBC
	JP	CPHLBC
	NOP

;002C	SAVESLT
	JP	BS
	NOP

;0030	CALLF
	JP	BS
	NOP

;0034	LOADSLT
	JP	BS
	NOP

;0038	INT38
	JP	RETURN