	SECTION	ICODE

;**********************************************
;	AHL= адрес источника
;	DE = адрес при,мника
;	BC = длина блока
;**********************************************

DMA_LDIR: 
	PUSH	AF
DMA_LDIR_W:
	IN0	A,(DSTAT)
	BIT	6,A
	JR	NZ,DMA_LDIR_W

	POP	AF
	PUSH	AF
	OUT0	(SAR0L),L
	OUT0	(SAR0H),H
	OUT0	(SAR0B),A

	OUT0	(DAR0L),E
	OUT0	(DAR0H),D
	LD	A,0FH		; 0F0000 or DE
	OUT0	(DAR0B),A

	LD	A,2		; MMOD=1 BURST MODE DMA
	OUT0	(DMODE),A	; (MEMORY)+ -> (MEMORY)+

	OUT0	(BCR0L),C
	OUT0	(BCR0H),B

	LD	A,40H		; DMA0 & DMAWR0 ENABEL
	OUT0	(DSTAT),A
	POP	AF
	RET

DMA_WAIT:
	IN0	A,(DSTAT)
	BIT	6,A
	JR	NZ,DMA_WAIT
	RET

;**********************************************
;	AHL= адрес источника
;	DE  = адрес при,мника I/O
;	BC = длина блока
;**********************************************

DMA_OUTIR: 
	PUSH	AF
	OUT0	(SAR0L),L
	OUT0	(SAR0H),H
	OUT0	(SAR0B),A

	OUT0	(DAR0L),E
	OUT0	(DAR0H),D
	XOR	A
	OUT0	(DAR0B),A

	LD	A,32H		; MMOD=1 BURST MODE DMA
	OUT0	(DMODE),A	; (I/O) -> (MEMORY)+

	OUT0	(BCR0L),C
	OUT0	(BCR0H),B

	LD	A,40H		; DMA0 & DMAWR0 ENABEL
	OUT0	(DSTAT),A
	POP	AF
	RET
	
