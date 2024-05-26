;--------------------------------
; Return the length of a string
;
; Input: ptr to string in X
; Return: length in A
;--------------------------------
STRLEN
    PSHS B, X
    CLRA

STRLEN01
    LDB ,X+
    CMPB #0
    INCA
    BNE STRLEN01

    PULS B, X, PC

;-------------------------------------
; Find first occurence of c in string
;
; Input: ptr to string in X, char in A
; Return: ptr to c or NULL in X
;-------------------------------------
STRCHR
    PSHS B

    CLRB

STRCHR01
    CMPA ,X           ; see if we match char
    BEQ STRCHR_DONE     ; if so return X

    CMPB ,X           ; end of string?
    BEQ STRCHR02        ; if so return NULL

    LEAX 1,X            ; point to next char
    BRA STRCHR01        ; do it again

STRCHR02
    LDX #NULL

STRCHR_DONE
    PULS B, PC

;--------------------------------
; Compare two strings
;
; Input: ptr to strings in X, Y
; Return: Zero set on not-equal
;--------------------------------
STRCMP
    PSHS A, B

    CLRB

STRCMP01
    LDA ,X              ; get char from str1
    CMPA ,Y             ; compare to char from str2
    BNE STRCMP_DONE     ; different, so strings don't match

    ; chars match but check for both zeros, if so then strings match
    CMPB ,X             ; see if str1 finished
    BEQ STRCMP_DONE     ; if so strings match

STRCMP02
    LEAX 1, X           ; advance both string pointers
    LEAY 1, Y

    BRA STRCMP01

STRCMP_DONE
    PULS A, B, PC

;--------------------------------
; Reverse a string in place
;
; Input: ptr to string in X
; Return: none
;--------------------------------
STRREV
    RTS
