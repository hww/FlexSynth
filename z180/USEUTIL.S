;*********************************************************
;
;   List 3.4	cluster dump
;
;		this program must link List 3.3
;
;*********************************************************
;
	EXTRN	GETARG		;Note: The first 128 bytes of an arbitrary
	EXTRN	STOHEX		;      cluster specified in the command
	EXTRN	PUTHEX		;      line are dumped.
	EXTRN	PUTCHR
	EXTRN	DUMP8B

BDOS	EQU	0005H

;----- program start -----

	LD	A,1
	CALL	GETARG		;[DE] := 1st argument of command line
	CALL	STOHEX		;HL := evaluate [DE] as hexadecimal
				;      this is the target cluster No.
	PUSH	HL
	LD	E,00H		;requests the default drive
	LD	C,1BH		;get disk information
	CALL	BDOS
	POP	HL
	CP	0FFH		;fail ?
	JR	NZ,L2		;if not fail, A := sector/cluster and goto L2

	LD	DE,ERMSG1	;[DE] := 'Cannot get Disk information'
	LD	C,09H		;string putput function
	CALL	BDOS
	RET			;error return

L2:	LD	E,(IX+12)	;DE := 1st sector of data area
	LD	D,(IX+13)
	DEC	HL
	DEC	HL		;HL := Cluster No. - 2
	LD	B,H
	LD	C,L		;BC := Cluster No. - 2
LOOP:	DEC	A		;Count N times
	JR	Z,RESULT
	ADD	HL,BC
	JR	LOOP
RESULT: ADD	HL,DE		;HL := sector of target cluster
	PUSH	HL		;save target sector
	LD	DE,NEWDMA	;we reserved 1024 bytes area for DMA
	LD	C,1AH		;Set DMA address function
	CALL	BDOS
	LD	C,19H
	CALL	BDOS		;default drive ?
	LD	L,A
	POP	DE		;DE := target sector
	LD	H,1		;H := 1 (read 1 sector only)
	LD	C,2FH		;absolute read function
	CALL	BDOS		;data will be set into DMA

DUMP:	LD	HL,NEWDMA	;HL := DMA address
	LD	DE,0000H	;DE := relative address from cluster top
	LD	B,16		;dump 16 lines
DLOOP:	PUSH	BC
	LD	A,D
	CALL	PUTHEX
	LD	A,E
	CALL	PUTHEX
	LD	A," "
	CALL	PUTCHR
	PUSH	HL
	LD	HL,8
	ADD	HL,DE
	EX	DE,HL		;DE := DE+8
	POP	HL
	CALL	DUMP8B		;8 bytes dump subroutine (in another file)
	POP	BC
	DJNZ	DLOOP
	RET			;all work have done.

;----- work area -----

NEWDMA: DS	1024		;Private DMA area
ADRS:	DS	2

ERMSG1: DB	"Cannot get Disk information.$"
ERMSG2: DB	"Cannot read that cluster.$"

	END

;=========================================================================
;List 3.5  File dump
;=========================================================================

;********************************************************
;
;   List 3.5	file dump
;
;		this program must link List 3.3
;
;********************************************************
;
	EXTRN	GETARG		;Note: gets the dump list of the file
	EXTRN	STOHEX		;      specified at the command line
	EXTRN	PUTCHR
	EXTRN	PUTHEX
	EXTRN	DUMP8B

BDOS:	EQU	0005H		;Note: The file name specified as the first
FCB:	EQU	005CH		;      parameter of the command line is
				;      stored in the default FCB area
				;      from (005CH)

;----- program start -----

	LD	DE,FCB		;DE := default FCB address
	LD	C,0FH		;open file function
	CALL	BDOS
	OR	A		;success ?
	JR	Z,READ		;if so, goto READ

	LD	DE,ERMSG1	;[DE] := 'Cannot open that file'
	LD	C,09H		;string output function
	CALL	BDOS
	RET			;error return

READ:	LD	A,2
	CALL	GETARG		;get 2nd argument of command line
	CALL	STOHEX		;HL := value of the argument
	LD	(ADRS),HL	;set address counter

	LD	DE,NEWDMA
	LD	C,1AH		;set DMA address function
	CALL	BDOS

	LD	HL,8
	LD	(FCB+14),HL	;record size := 8

	LD	HL,0
	LD	(FCB+33),HL
	LD	(FCB+35),HL	;random record := 0

RD1:	LD	HL,NEWDMA	;clear DMA area
	LD	B,8
RD2:	LD	(HL)," "
	INC	HL
	DJNZ	RD2

	LD	HL,1		;read 1 record
	LD	DE,FCB
	LD	C,27H		;random block read function
	CALL	BDOS
	OR	A		;success ?
	JR	Z,DUMP		;if so, goto DUMP

	LD	DE,ERMSG2	;[DE] := 'Ok.'
	LD	C,09H		;string output function
	CALL	BDOS
	RET

DUMP:	LD	HL,(ADRS)
	LD	A,H
	CALL	PUTHEX
	LD	A,L
	CALL	PUTHEX
	LD	A," "
	CALL	PUTCHR
	LD	DE,8
	ADD	HL,DE
	LD	(ADRS),HL

	LD	HL,NEWDMA
	CALL	DUMP8B		;dump 8 bytes

	JR	RD1

;----- work area -----

ADRS:	DS	2
NEWDMA: DS	8

;----- error message -----

ERMSG1: DB	"Cannot open that file.$"
ERMSG2: DB	"Ok.$"

	END

;=========================================================================
