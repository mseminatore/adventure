;--------------------------------------
; Compute dividend and remainder
;
; Input: dividend in B, divisor in A
; Result: quotient in A, remainder in B
;--------------------------------------
DIVMOD
    PSHS A          ; save divisor on stack
    CLR A           ; zero quotient
    BRA DIVMOD02

DIVMOD01
    INCA            ; inc quotient
    SUBB ,S         ; subtract divisor from dividend

DIVMOD02
    CMPB ,S         ; compare remainder to divisor
    BGE DIVMOD01    ; if greater than or equal, keep going

    LEAS 1,S        ; pop A off stack
    RTS
    