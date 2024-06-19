
;-------------------------
; Set cursor x,y
;
; Input: A = col, B = row
; Return: none
;-------------------------
SETCURSOR:
    PSHS D
    ANDA #$1F       ; clamp col [0..31]
    ANDB #$F        ; clamp row [0..15]
    MUL             ; compute vidbuf address
    STD CURPOS      ; store cursor value

    PULS D, PC      ; restore regs and return

;---------------------------------
; Get cursor X, Y
;
; Input: none
; Return: A = row, B = col
;---------------------------------
GETCURSOR:
    LDD CURPOS
    ANDB #$1F       ; col is [0..31]

    ASLB            ; shot B top 3 bits into A
    ROLA            ; the lower 4 bits of A are now row

    ASLB
    ROLA

    ASLB
    ROLA

    RTS

;-------------------
; wait for keypress
;
; Input: none
; Return: none
;-------------------
WAIT:
    ; PSHS A, DP, Y, U
    JSR [CHARIN]    ; poll keyboard
    BEQ WAIT        ; wait for keypress
    ; PULS A, DP, Y, U, PC
    RTS
    
;--------------
; clear screen
;
; Input: none
; Return: none
;--------------
CLS:
    PSHS A, B, X
    LDX #VIDRAM
    STX CURPOS      ; RESET CURSOR POSITION

    LDA #BLANK
    TFR A, B

CLS01:
    STD , X++
    CMPX #VIDEND
    BLT CLS01
    PULS A, B, X, PC

;-------------------------------------
; SCROLL THE SCREEN
;
; Input: none
; Return: none
;-------------------------------------
SCROLL:
    PSHS A, B, X
    LDX #VIDRAM         ; get start of video ram

SCROLL01:
    LDD 32, X           ; get two chars from next line
    STD ,X++            ; store them in current line
    CMPX #VIDSCROLL     ; continue until last-1 line
    BLT SCROLL01

    STX CURPOS          ; cursor is at start of last line
    LDD #$6060          ; load up blanks
    BRA CLS01           ; blank last line

    ; !! should never get here!!
    ; PULS A, B, X, PC

;-------------------------------------
; PUT A CHAR ON SCREEN
;
; Input: A is char to print
; Return: none
;-------------------------------------
PUTC:
    PSHS A, B, X
    LDX CURPOS          ; get cursor position
    CMPA #BS            ; check for backspace
    BNE PUTC01          ; if not, skip ahead

    CMPX #VIDRAM        ; see if we are at top of screen
    BEQ PUTC_DONE       ; yes, do nothing
    
    LDA #BLANK          ; blank char
    STA ,-X             ; erase current char
    BRA PUTC06          ; update cursor, check scroll and done

PUTC01:
    CMPA #CR            ; check for carriage return
    BNE PUTC03          ; if not, skip
    LDX CURPOS          ; get cursor pos

PUTC02:                  ; blank rest of line
    LDA #BLANK          ; (re)load blank char
    STA ,X+             ; store it at curpos
    TFR X, D            ; copy curpos (note: destroys A)
    BITB #$1F           ; test for start of newline
    BNE PUTC02          ; if not, do it again
    BRA PUTC06          ; done blanking rest of line

PUTC03:
    CMPA #SPACE
    BCS PUTC_DONE       ; skip control chars
    TSTA
    BMI PUTC05          ; if graphics char print it
    CMPA #$40           ; check for number or special chars
    BCS PUTC04          ; if so, invert them
    CMPA #$60           ; check for upper/lower
    BCS PUTC05          ; if upper alpha print it
    ANDA #$DF           ; clear bit 5, force lower to upper

PUTC04:
    EORA #$40           ; toggle bit 6, upper/lower case

PUTC05:
    STA ,X+             ; store A to screen and inc cursor

PUTC06:
    STX CURPOS          ; save new cursor position
    CMPX #VIDEND        ; see if we need to scroll
    BLS PUTC_DONE       ; finished!

    JSR SCROLL          ; scroll the screen

PUTC_DONE:
    PULS A, B, X, PC

;-------------------------------------
; Count chars in next word of string
;
; Input: X ptr to string
; Return: count of chars in A
;-------------------------------------
CHARS_IN_WORD:
    PSHS B, X

    CLRA            ; clear count

CHARS_IN_WORD01:
    LDB ,X+                     ; get next char
    CMPB #EOS                   ; reached end of string?
    BEQ CHARS_IN_WORD_DONE      ; if so return

    CMPB #SPACE                 ; found a space?
    BEQ CHARS_IN_WORD_DONE      ; if so return

    INCA
    BRA CHARS_IN_WORD01

CHARS_IN_WORD_DONE:
    PULS B, X, PC

;-------------------------------------
; Return chars left before EOL
;
; Input: none
; Return: count of chars in A
;-------------------------------------
CHARS_LEFT:
    PSHS B, X

    LDD CURPOS          ; get cursor pos
    ANDB #31            ; get current column num
    PSHS B              ; save on stack
    LDA #31             ; load line length
    SUBA ,S             ; compute chars left
    PULS B              ; pop B off stack

    PULS B, X, PC

;-------------------------------------
; See if word wrap is required
;
; Input: X ptr to string
; Return: Z = 1 if wrap required
;-------------------------------------
WORD_WRAP:
    PSHS A

    JSR CHARS_IN_WORD   ; get count of chars in next word
    PSHS A              ; save count on stack

    JSR CHARS_LEFT      ; get count of cols left

    CMPA ,S             ; 
    BLT WORD_WRAP_NEEDED

    CLRZ
    PULS A
    PULS A, PC

WORD_WRAP_NEEDED:
    SETZ
    PULS A
    PULS A, PC

;-------------------------------------
; PUT A STRING ON SCREEN
;
; Input: X ptr to string
; Return: none
;-------------------------------------
PUTS:
    PSHS A, X       ; save A and X

PUTS01:
    JSR WORD_WRAP   ; see if word wrap needed
    BNE PUTS02      ; if not skip

    LDA #CR
    JSR PUTC

 PUTS02:   
    LDA ,X+         ; get next char
    CMPA #EOS       ; see if end of string
    BEQ PUTS_DONE   ; if so we are done

    JSR PUTC        ; otherwise put char on screen
    BRA PUTS01      ; do it again

PUTS_DONE:
    PULS A, X, PC   ; restore regs and return

;-------------------
; GET INPUT CHAR
;
; Input: none
; Return: char in A
;-------------------
GETC:
    PSHS B, DP, X, Y, U       ; save regs

    LDU #CURSOR     ; get cursor ptr
    CLRB            ; clear cursor index
    LDY CURPOS      ; get cursor screen loc
    LDX #0          ; clear cursor index counter

GETC01:
    PSHS X          ; save X on stack
    PULS B          ; get XH in B
    PULS A          ; discard XL
    ANDB #3         ; clamp B [0..3]

    LDA B, U        ; get cursor char
    EORA #$40       ; toggle case
    STA ,Y          ; put it on screen
    LEAX 1, X       ; inc cursor index counter

    JSR [CHARIN]    ; poll keyboard
    BEQ GETC01      ; wait for keypress

    LDB #BLANK      ; replace cursor char with blank
    STB ,Y

    PULS B, DP, X, Y, U, PC   ; restore regs and return

;---------------------------
; GET CHAR STRING
; Input: X points to buffer
; Return: string in buffer
;---------------------------
GETS:
    PSHS A, X       ; save A and X

GETS01:
    JSR GETC        ; read an input char
    CMPA #CR        ; check for return
    BEQ GETS_DONE   ; if so we are done

    CMPA #BS        ; check for backspace
    BNE GETS02      ; if not, skip

    CMPX #INBUF     ; see if buffer is empty
    BEQ GETS01      ; if so, do it again

    LEAX -1,X       ; erase last char from buffer
    BRA GETS03

GETS02:
    STA ,X+         ; otherwise add char to buf

GETS03:
    JSR PUTC        ; echo char to screen
    BRA GETS01      ; get another char

GETS_DONE:
    CLRA            ; asciiz terminator
    STA ,X          ; make asciiz
    PULS A, X, PC   ; restore regs and return

;--------------
; quit program
;--------------
RESET:
    CLR RSTFLG          ; warm/cold reset?
    JMP [RESET_VECTOR]  ; reboot

;---------------------------------
; data variables
;---------------------------------
    INBUF: RMB 32        ; input buffer
    INCUR: FDB INBUF     ; input cursor
    CURPOS: FDB VIDRAM   ; current cursor position
