;KIDVRFG/ASM - LDOS Keyboard driver Model IV - 12/06/83
;*=*=*
;       Change Log
; this version for FRENCH and GERMAN keyboards 06/06/83
; 06/14/83 - corrected to have Screen Print work
; ignore @PUT and oddball CTL requests 06/30/83
; made CAPS lock work for umlaut chars if GERMAN 08/12/83
; moved type buffer to extra video RAM 12/06/83

	SUBTTL	'<Keyboard Driver FR/GE>'
*MOD
;
;*=*=*
; Type-ahead buffer size - must be power of 2 and <256
;*=*=*

TBUFSZ	EQU	64
SPRN	EQU	6		;Ctl value for screen-print
;
LF	EQU	10
CR	EQU	13
KB0	EQU	0F401H		;Start of matrix
; Header for driver
KIDVR	JR	KIBGN		;Branch around linkage
	DW	KILAST		;Last byte used
	DB	3,'$KI'		;Driver name
	DW	KIDCB$		;Pointer to DCB
	DW	0		;Spare
;Data for driver use
KIDATA$	DB	0		;Last key entered
	DB	0		;Repeat time check
RPTINIT	EQU	$-KIDATA$
	DB	22		;22 * 33.3ms = .733 sec
RPTRATE	EQU	$-KIDATA$
	DB	2		;2 x RTC rate
KBROW0	EQU	$-KIDATA$
	DB	-1,-1,-1,-1	;Image of rows 0-3
KBROW4	EQU	$-KIDATA$
	DB	-1,-1		;Image of rows 4-5
KBROW6	EQU	$-KIDATA$
	DB	-1
KBROW7	EQU	$-KIDATA$
	DB	-1		;Image of rows 6-7
EXDATA	EQU	$-KIDATA$
	DB	0		;0,1,or 2 for spcl chars
TABPTR	DW	TABLE1		;Pointer to unshift chars
EXTPTR	DW	EXTBL		;Pointer to extra keys
;*=*=*
;       Entry to keyboard driver
;*****
KIBGN	LD	A,C		;Save possible ctl value
	PUSH	AF		;Save flags
	CALL	@KITSK		;Hook for KI task
	POP	AF		;Restore flags
;*=*=*
;       keyboard request handler
;*=*=*
	CALL	ENADIS_DO_RAM	;Bring in keyboard
;(KB disable is now on stack)
	LD	HL,TYPBUF	;P/u start of type buffer
	LD	(HL),0FFH	;Turn off type ahead
	JR	C,GETKB		;Go on @GET
	JR	Z,TYPON		;Ignore @PUT
; request via @CTL...
;Note: type-ahead stays off until after next @GET call
	CP	3		;@CTL-3??
	JP	Z,CLRTYP	;Clear buffer if so
	CP	SPRN
	JP	Z,SCREENP	;Then do a screen-print
CTLFFX	INC	A		;@CTL-255??
	JR	Z,USCAN
	XOR	A		;Set nothing error
	JR	TYPON
;*=*=*
;       Handle CTL-255 - scan keyboard into user rowbuf
;*=*=*
USCAN	PUSH	IY		;Xfer passed ptr
	POP	HL		;To HL
SCNMAT	LD	DE,0		;Put 0 on stack
	PUSH	DE
	LD	BC,KB0		;Load start of keyboard
SCNLP	INC	D		;Bump the row counter
	LD	A,(BC)		;Load 1st char from kbd
	LD	A,(BC)		;Twice
	LD	E,A		;Keep byte
	XOR	(HL)		;XOR with old value
	LD	(HL),E		;Save new value
	JR	Z,NONEW		;Go if no chg
	EX	(SP),HL		;P/u stored value
	INC	L		;Priority to 1st new press
	DEC	L		;Ck for no press or release
	JR	NZ,KEEP1	;Go if not 1st press
	AND	E		;0 if chg is release
	LD	L,A		;Save chg'd bit (col)
	LD	H,D		;And row (+1)
KEEP1	EX	(SP),HL		;Back on stack
NONEW	INC	HL		;Bump image pointer
	RLC	C		;Go to next row
	JR	NC,SCNLP	;Loop for 7 rows
	POP	DE		;Ck for chg
	LD	A,D		;Row of chg (if any) +1
	OR	A		;Z=no new keys
	RET			;(disables KB first)
;*=*=*
;   Input request for keyboard - check buffer first
;*=*=*
GETKB	PUSH	HL		;Save ptr to switch
	INC	HL		;Bump to PUT pointer
	LD	A,(HL)		;  & pick it up
	LD	C,A		;Hold onto PUT ptr
	INC	HL		;Bump to GET pointer
	LD	E,(HL)		; p/u GET ptr
	CP	E		;The same?
	JR	Z,REALKI	; no char if same
	LD	D,0		;DE=offset in buffer
	INC	E		;Pt to next /allow for bfst
	LD	A,E		;Next GET
	AND	TBUFSZ-1	;End wraps to 0
	LD	(HL),A		;Reset for next char
	ADD	HL,DE		;Point to char posn
	CP	C		;Does this empty buffer?
	LD	A,(HL)		;GET the stored char
	CALL	Z,R7KFLG	;Reset bit-7 if empty now
	CP	A		;Set Z for good char
	JR	FIXTSW		;Turn type back on
;*****
;       no character in type ahead buffer - get from kbd
;*****
REALKI	CALL	KISCAN		;Call keyboard driver
FIXTSW	POP	HL		;Rcvr switch
TYPON	LD	(HL),0		;Type ahead back on
	RET			;W/char fm scan
;*=*=*
;       Driver to scan the keyboard
;*=*=*
KISCAN	LD	HL,KIDATA$+KBROW0	;Load kbd image start
	CALL	SCNMAT		;Scan matrix
	LD	HL,KIDATA$	;=> data area
	JR	NZ,ISCHG	;Go if change
;*=*=*
; no change - check for repeat of current key
; don't repeat if either (TYPBUF) or (KIDATA$)=0
;*=*=*
	LD	A,(HL)		;Any key to repeat?
	OR	A
	JR	Z,NOCHAR	;Quit if not
	LD	A,(TYPBUF)	;P/u type-ahead switch
	LD	B,A		;Save it
	CALL	STIME		;Advance timer
	RET	NZ		;Quit if no repeat
	INC	B		;Set Z if not in type
	RET	Z		;Return char
	JR	NOCHAR		;Quit if in type-ahead
STIME	LD	A,(TIMER$)	;Is it time to repeat?
	LD	C,A
	INC	HL		;=>time check
	SUB	(HL)		; same key yet?
	INC	HL		;=>RPTINIT
	SUB	(HL)		;Beyond 0.75 seconds?
	JR	C,DORPT		;Go if yes
NOCHAR	OR	0FFH		;Else don't repeat
	CPL			;Show NZ with A=0
	RET
;Repeating - set time for next
DORPT	LD	A,C		;Advance time check
	INC	HL		;=>RPTRATE
	ADD	A,(HL)		; by 0.067 seconds
	DEC	HL
	JR	RPTKEY		;Go output the key
;*****
;       Found change in key matrix - debounce it
;*****
ISCHG	LD	BC,0184H	;Debounce delay (5.66ms)
	CALL	PAUSE@
	XOR	A
	LD	(HL),A		;Clear last char
	EX	DE,HL		;Row,col to HL
	LD	D,A		;D=0
	OR	L		;Is chg'd press or release?
	JR	Z,NOCHAR	;Go if new is none
;*****
;       Convert the depressed key to table index
;*****
	LD	A,H		;Calculate 8 * row
	DEC	A		;Remember offset fm 1
	ADD	A,A		;X2
	ADD	A,A		;X4
	ADD	A,A		;X8
	LD	E,A		;Save 8 * row
	LD	A,L		;Add 8 * row + column
	DEC	E		;Init for loop
FNDBIT	INC	E		; add 0 -7 for bit offset
	RRCA			;Count over to bit
	JR	NC,FNDBIT	;Go if not there
;DE=offset..
	CALL	KEYTBL		;Get indicated char
	RET	NZ		;No char or EOF fcn
;
	CP	80H		;BREAK key?
	JR	NZ,KEYOK	;Ck on <BREAK> disable
	LD	HL,SFLAG$	;Break disabled?
	BIT	4,(HL)
	JR	NZ,NOCHAR	;Ignore if off
	LD	HL,KFLAG$
	SET	0,(HL)
;
KEYOK	LD	HL,KIDATA$
	LD	(HL),A		;Store new char
	LD	A,(TIMER$)	;Set initialization
	INC	HL
	INC	HL		;=>RPTINIT
	ADD	A,(HL)		; repeat key delay
RPTKEY	DEC	HL		;=>time check
	LD	(HL),A		;Save new repeat time
	DEC	HL		;=>char
	LD	A,(HL)		;Get char
	CP	A		;Set Z-flag
	RET
;
;*****
;       type ahead task 10 - scans keyboard & saves key
;*****
TYPTSK$	DW	TYPEPT		;Task entry for processor
TYPEPT	LD	A,(DFLAG$)	;If type-ahead suppressed
	AND	2H		;  then return
	RET	Z		;Otherwise A=2
	CALL	ENADIS_DO_RAM	;Bring in KB,RAM
	LD	HL,TYPBUF	;Chk type switch for FFH
	AND	(HL)		;If previous driver in
	RET	NZ		;  do not stack more keys
	INC	HL		;Bump to PUTPTR
	LD	A,(HL)		;P/u PUTPTR & compare
	LD	E,A		;Save put posn
	INC	A		;Calc next put posn
	AND	TBUFSZ-1	;If end then make 0
	LD	D,A		;Save NEXT put posn
	INC	HL		;=>GETPTR,if NEXT PUT posn
	CP	(HL)		;=GET, then buffer is full
	RET	Z		;So don't get more keys
; go get KB char
	PUSH	DE		;Next put/this put offsets
	CALL	KISCAN		;And scan for a character
	POP	DE		;Restore offset posns
	RET	NZ		;Done if no char
; got a char, stuff in buffer
	CP	80H		;Was it BREAK?
	CALL	Z,CLRTYP	;Then clear type-ahead
	LD	HL,TYPBUF+1	;=> PUTPTR
	LD	(HL),D		;Save new pointer
	LD	D,0		; calculate PUT offset
PASTB2	INC	HL		;Pt to start of keybuf
	INC	HL
	ADD	HL,DE		;Pt to posn
	LD	(HL),A		;Store the char
	LD	HL,KFLAG$	;Show type buffer
	SET	7,(HL)		;Is not empty
	RET
;*=*=*
;DE=offset into matrix, set B=(ROW7) C=(ROW6)
;*=*=*
KEYTBL	LD	BC,(KIDATA$+KBROW6)	;Get CLEAR key /row7
	LD	HL,(TABPTR)	;=>table 1
	PUSH	HL		;Save start
	ADD	HL,DE
	LD	E,64		;Offset to shift-table
	LD	A,3		;Check left & right
	AND	B		;Shift keys?
	JR	Z,GETCHR	;Go if unshift
	ADD	HL,DE		;Move to shift table
GETCHR	LD	A,(HL)		;P/u char
	POP	HL		;=>table start
	OR	A		;A zero?
	JR	Z,NZRET		;Ignore completely
	CP	0FAH		;Reserved values
	JR	NC,HAVCHR	;Fcn value fm table
	ADD	HL,DE
	ADD	HL,DE		;Pt to spec tbl1
	LD	E,1		;Offset to sub/char
	BIT	2,B		;CTL key?
	JR	NZ,CTLS		;Yes, look up first
	INC	E		;Bump offset - E=2
	BIT	1,C		;CLEAR?
	JR	Z,EXTRAS	;Not clr/ctl - ck deadkey
CTLS	CALL	ODDCHR		;Look through spcl tbl
	JR	C,HAVCHR	;Go if match found
	DEC	E		;No match, E=1 means CTL key
	JR	NZ,CKY2		;Go if E was 2/CLR key only
	AND	1FH		;Make ctl value
	BIT	1,C		;CLR also?
	JR	Z,GIVCHR	;No, ret ctl char
	INC	E		;Or set hi bit also
;CLEAR is down - toggle case & set hi bit
CKY2	LD	D,A		;Save char
	RES	5,A		;Set to U/C for test
	SUB	'A'		;A-Z range only
	CP	'Z'-'A'+1
	LD	A,D		;Restore actual char
	JR	NC,NOTALF
	XOR	20H		;Reverse case (convention)
NOTALF	OR	80H		;Clear is down,  set hi bit
	JR	GIVE1		;Set E=0, return char
;*=*=*
; make U/C if CAPS LOCK - check for special chars
;*=*=*
	IF	FREN		;Do trans for DEADKEY
EXTRAS	LD	E,A		;Save code
	CP	'a'		;If a-z
	JR	C,KEYGD
	CP	'z'+1
	JR	NC,KEYGD
	LD	A,(KFLAG$)	;And caps lock
	AND	20H
	XOR	E		;Toggle bit 5 if set
KEYGD	LD	HL,KIDATA$+EXDATA
	LD	E,(HL)		;1 or 2 if set for spcl
	INC	E
	DEC	E		;If 0.., not spcl
	LD	HL,(EXTPTR)	;Pt to spcl tbl2
	CALL	NZ,ODDCHR	;Look up if ptr set
	ENDIF
	IF	GERM		;Caps lock for umlaut chars also
EXTRAS	LD	E,A		;Hold char while..
	LD	A,(KFLAG$)	;Ck caps lock
	AND	20H		;Only bit 5
	LD	C,A		;Save 20H
	LD	A,E		;Char
	JR	Z,HAVCHR	;No caps, done here
	CP	'a'		;If a-z
	JR	C,HAVCHR	;Ok if < a
	CP	'z'+1	
	JR	NC,CKUML	;Ck for others
	XOR	C		;Flip bit 5 if alpha
CKUML	CP	0D6H		;Char w/umlaut
	JR	C,HAVCHR
	CP	0D8H+1
	JR	NC,HAVCHR
	SUB	5		;Make caps
	ENDIF
;*=*=*
; test for the special functions FA - FFH
;*=*=*
HAVCHR	LD	C,A		;Keep char
	INC	C
	JR	Z,FCN2		;CAPLOCK      = FFH
	INC	C	
	JR	Z,FCN3		;EOF          = FEH
	INC	C
	JR	Z,FCN4		;Screen-print =FDH
	INC	C
	JR	Z,FCN5		;Clear type-ahead = FCH
	LD	E,2		;Spcl2
	INC	C		;=FBH
	JR	Z,SETSPC
	DEC	E		;=1
	INC	C		;Spcl1 = FAH
	JR	Z,SETSPC
; clear spcl char pointer - ret w/char
GIVE1	DEC	E		;=0
GIVCHR	CP	A		;Force Z flag
GIVE2	LD	HL,KIDATA$+EXDATA
	LD	(HL),E
	RET
; set spcl char pointer for next
SETSPC	XOR	A		;Get 0 w/NZ
	INC	C
	JR	GIVE2
;*=*=*
;       Toggle the caps lock bit in the KFLAG$
;*=*=*
FCN2	LD	A,20H
	LD	HL,KFLAG$	;Reverse case by
	XOR	(HL)		;  flipping bit 5
	LD	(HL),A
	DB	21H		;Skip next instruct..
; ret EOF like file, 1CH w/NZ
FCN3	LD	C,1CH		;EOF error number
; ret NO char - A=0 w/NZ
FCN1	LD	A,C		;No char (c=0)
NZRET	INC	C		;Make NZ status
	RET
;
FCN5	XOR	A		;Clear type ahead
	INC	C		;Get 0 w/NZ
;*****
; clear the type-ahead buffer
;*****
CLRTYP	LD	HL,0		;Set buffer pointers
	LD	(TYPBUF+1),HL	;To 0 offset
R7KFLG	LD	HL,KFLAG$	;Show buffer empty
	RES	7,(HL)
	RET
; screen - print
FCN4	LD	A,(TYPBUF)	;Screen prt only works if
	OR	A		;Not in type-ahead
	CALL	NZ,SCREENP
	JR	FCN1		;No char returned
;*=*=*
; look up special combinations
;*=*=*
ODDCHR	LD	B,A		;Save input char
XLTLP1	LD	A,(HL)		;P/u possible match
	CP	B		;Does it match?
	JR	Z,MAT1		;Get it if so...
	INC	HL		;Bump past replacement chars
	INC	HL
	INC	HL		;To next match char
	OR	A		;Was this the end
	JR	NZ,XLTLP1	;No, keep going
	LD	A,B		;Restore char
	RET			;NC if no match
MAT1	ADD	HL,DE		;1 or 2 
	LD	A,(HL)		;Get xlate char
	SCF			;Carry set if sub found
	RET
;*=*=*
;       Perform a screen print
;*=*=*
@PRTSCR	EQU	$
SCREENP	CALL	RKFL		;Clear BREAK bit
	LD	HL,00
SCP2	LD	B,1		;Get a character
	CALL	@VDCTL
	RET	NZ		;Quit if error
	CP	20H		;Printable??
	JR	NC,NTLCTC	;Convert control codes
	ADD	A,40H		;To cap A-Z, +
NTLCTC	LD	D,A		;Save char
	RLCA			;Graphic??
	JR	NC,NGRP		;No, print actual
	LD	A,(DFLAG$)	;Check on Graphic bit
	RLCA			;If not set..
	LD	A,'.'		;Print a period
	JR	NC,PRTPER
NGRP	LD	A,D		;Restore actual char
PRTPER	CALL	@PRT		;Print the char
	RET	NZ		;Quit if output error
	INC	L		;Bump column counter
	LD	A,L		;Check for end-of-line
	CP	80		;Past 79?
	JR	NZ,SCP2		;Loop if not EOL
	CALL	LINEN		;Send CR / check Break
	RET	NZ		;Quit if error/break pressed
	INC	H		;Bump row counter
	LD	A,H		;Test for end of screen
	SUB	24
	JR	NZ,SCP2		;Loop till done
	RET	
LINEN	LD	A,CR		;
	CALL	@PRT		;
	RET	NZ		;Error
RKFL	PUSH	HL
	LD	HL,KFLAG$
	XOR	A		;Get 0
	BIT	0,(HL)		;Test BREAK bit
	RES	0,(HL)		;  & reset BREAK bit
	POP	HL
	LD	L,A		;Pt to start of line
	RET
;
	IF	FREN
;Table for French keyboard
;Lookup table for KB rows 1-7 (no shift) 64 chars
; zero is ignored - FAH to FFH are spcl functions
TABLE1	DB	'>qbcdefg'
	DB	'hijkl,no'
	DB	'parstuvz'
	DB	'xyw',0FBH,'@m',0DCH,7DH
	DB	0C1H,'&',0DBH,022H,027H,028H,0C9H,0DDH
	DB	'!',0C2H,')-$;:='
	DB	0DH,00H,80H,0BH,0AH,08H,09H,20H
	DB	00H,00H,00H,0FFH,81H,82H,83H,00H
; chars w/SHIFT - 64 chars
	DB	'<QBCDEFG'
	DB	'HIJKL?NO'
	DB	'PARSTUVZ'
	DB	'XYW',0FAH,'*M%',07BH
	DB	'01234567'
	DB	'89',0C6H,'_#./+'
	DB	1DH,1FH,00H,1BH,1AH,18H,19H,20H
	DB	00H,00H,00H,0FFH,91H,92H,93H,00H
; special chars table 1
;            char ! ctl-char ! clr-char
	DB	1FH,1FH,1FH	;CLEAR
	DB	0DH,0DH,'_'
	DB	1DH,1DH,127
	DB	',',27,91
	DB	'<',27,123
	DB	'.',29,93
	DB	'>',29,125
	DB	'/',28,92
	DB	'?',28,124
	DB	';',30,94
	DB	'+',30,126
	DB	':',0FDH,186	;Screen prnt
	DB	'@',00H,0FCH	;Null, clear type
	DB	'*',0FEH,'*'!80H	;EOF
	DB	0		;End of 1st table
;
EXTBL
;               char, w/umlaut, w/circumflex
	DB	'a',0D6H,0E0H	
	DB	'e',0E6H,0E1H
	DB	'i',0E7H,0E2H
	DB	'o',0D7H,0E3H
	DB	'u',0D8H,0E4H
	DB	' ',0DEH,0E5H
	DB	0		;End of table
	ENDIF
	IF	GERM
;Table for GERMAN keyboard (deadkey not used)
;Lookup table for KB rows 1-7 (no shift) 64 chars
; zero is ignored - FAH to FFH are spcl functions
TABLE1	DB	'>abcdefg'
	DB	'hijklmno'
	DB	'pqrstuvw'
	DB	'xzy',0D8H,'+',0D7H,0D6H,'#'
	DB	'01234567'
	DB	'89',0D9H,0C0H,'@,.-'
	DB	0DH,00H,80H,0BH,0AH,08H,09H,20H
	DB	00H,00H,00H,0FFH,81H,82H,83H,00H
; chars w/SHIFT - 64 chars
	DB	'<ABCDEFG'
	DB	'HIJKLMNO'
	DB	'PQRSTUVW'
	DB	'XZY',0D3H,'*',0D2H,0D1H,027H
	DB	'=!"',0C9H,'$%&/'
	DB	'()?',0C4H,60H,';:_'
	DB	1DH,1FH,00H,1BH,1AH,18H,19H,20H
	DB	00H,00H,00H,0FFH,91H,92H,93H,00H
; special chars table 1
;            char ! ctl-char ! clr-char
	DB	1FH,1FH,1FH	;CLEAR
	DB	0DH,0DH,'_'
	DB	1DH,1DH,127
	DB	',',27,91
	DB	'<',27,123
	DB	'.',29,93
	DB	'>',29,125
	DB	'/',28,92
	DB	'?',28,124
	DB	';',30,94
	DB	'+',30,126
	DB	':',0FDH,186	;Screen prnt
	DB	'@',60H,0FCH	; clear type
	DB	'*',0FEH,'*'!80H	;EOF
	DB	0		;End of 1st table
;
EXTBL
; deadkey not used for German KB..
	DB	0		;End of table
	ENDIF
;*=*=*
;       Type ahead buffer area
;*=*=*
TYPBUF	EQU	0FF80H
;TYPEBUF+0 = On/off flag
;TYPEBUF+1 = Store pointer
;TYPEBUF+2 = Retrieve pointer
;TYPEBUF+3 = Start of actual buffer
;
KILAST	EQU	$-1
