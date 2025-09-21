;--------------------------------------
; Seed storage (must be defined before use for one-pass assembler)
RND8_SEED: FCB 1
RND16_SEED: FDB 1

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
RND8:
    PSHS A, X            ; save A and X (B will hold result)

    LDA RND8_SEED        ; load 8-bit seed into A
    LDB #33              ; multiplier
    MUL                  ; D = A * B (16-bit product)

    LDX #251             ; divisor (prime-ish) to keep values in 0..250
    JSR DIVMOD16         ; divide D by X -> remainder left in D (A:B)

    STB RND8_SEED        ; store low byte of remainder as new seed

    PULS A, X, PC        ; restore A/X and return with random byte in B

;--------------------------------------
; Generate random number [0..65535]
; Input: none
; Return: random 16b value in D
;--------------------------------------
RND16:
    ; PSHS A, X           ; preserve A and X

    ; JSR RND8            ; get low byte in B
    ; STB RND16_SEED      ; store low byte to low-half of seed

    ; JSR RND8            ; get next byte in B (treat this as high byte)
    ; TBA                 ; transfer B -> A (A = high)
    ; LDB RND16_SEED      ; load previously stored low into B
    ; STD RND16_SEED      ; store combined 16-bit seed (A:B)

    ; LDD RND16_SEED      ; load 16-bit random into D (return value)
    ; PULS A, X, PC       ; restore and return


