
;--------------------------------
; Print lower nibble of hex byte
; Input: byte in A
; Return: none
;--------------------------------
PRINT_HEX_NIBBLE
    PSHS A
    CMPA #9
    BGT PRINT_HEX_LETTER

    ADDA #'0'
    JSR PUTC
    BRA PRINT_HEX_DONE

PRINT_HEX_LETTER
    SUBA #10
    ADDA #'A'
    JSR PUTC

PRINT_HEX_DONE
    PULS A, PC

;-------------------
; Print hex byte
;
; Input: byte in A
; Return: none
;-------------------
PRINT_HEX_BYTE
    PSHS A              ; save A
    PSHS A              ; make a copy of A

    ANDA #$F0           ; get top nibble
    LSRA                ; shift top nibble to bottom
    LSRA
    LSRA
    LSRA
    JSR PRINT_HEX_NIBBLE ; print hex digit

    PULS A               ; get original copy of A
    ANDA #$0F            ; get lower nibble
    JSR PRINT_HEX_NIBBLE ; print hex digit

    PULS A, PC

;-------------------
; Print hex word
;
; Input: word in X
; Return: none
;-------------------
PRINT_HEX_WORD
    PSHS D, X
    TFR X, D

    JSR PRINT_HEX_BYTE
    TFR B, A
    JSR PRINT_HEX_BYTE

    PULS D, X, PC
