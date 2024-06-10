;--------------------------------------
; Compute byte quotient and remainder
;
; Input: dividend in B, divisor in A
; Return: quotient in A, remainder in B
;--------------------------------------
DIVMOD:
    PSHS A          ; save divisor on stack
    CLRA            ; zero quotient
    BRA DIVMOD02

DIVMOD01:
    INCA            ; inc quotient
    SUBB ,S         ; subtract divisor from dividend

DIVMOD02:
    CMPB ,S         ; compare remainder to divisor
    BGE DIVMOD01    ; if greater than or equal, keep going

    LEAS 1,S        ; pop A off stack
    RTS

;--------------------------------------
; Compute word quotient and remainder
;
; Input: dividend in D, divisor in X 
; Return: quotient in X, remainder in D
;--------------------------------------
DIVMOD16:
    PSHS X          ; save divisor on stack
    LDX #0          ; zero quotient
    BRA DIVMOD16_02

DIVMOD16_01:
    LEAX 1, X       ; inc quotient
    SUBD ,S         ; subtract divisor from dividend

DIVMOD16_02:
    CMPD ,S         ; compare remainder to divisor
    BGE DIVMOD16_01 ; if greater than or equal, keep going

    LEAS 2,S        ; pop X off stack
    RTS

;--------------------------------------
; Generate random number [0..255]
; Input: none
; Return: random 8b value in B
;--------------------------------------
; RND8:
;     PSHS A, X

;     LDA RND8_SEED
;     LDB #33
;     MUL

;     LDX #251
;     JSR DIVMOD16

;     STB RND8_SEED

;     PULS A, X, PC

;--------------------------------------
; Generate random number [0..65535]
; Input: none
; Return: random 16b value in D
;--------------------------------------
; RND16:
;     RTS

; RND8_SEED: FCB 1
; RND16_SEED: FDB 1
