STRTMP  RMB 7
STRTMP_TOP

;--------------------------------
; Print decimal byte
;
; Input: byte to print in A
; Return: none
;--------------------------------
PRINT_DEC_BYTE
    PSHS A, B, U        ; preserve A and U
    LDU #STRTMP_TOP     ; set U stack at end of temp string
    CLRB
    PSHU B              ; store string terminator

PDB01
    TFR A, B            ; move A to B (divisor)
    LDA #10             ; divide by 10
    JSR DIVMOD          ; get remainder
    ADDB #'0'           ; make ascii digit    
    PSHU B              ; put digit on stack
    CMPA #0             ; done?
    BNE PDB01           ; do it again

    TFR U, X            ; put string ptr in X
    JSR PUTS            ; print it!

    ; CMPA #0             ; test for negative
    PULS A, B, U, PC

;--------------------------------
; Print decimal word
;
; Input: word to print in D
; Return: none
;--------------------------------
PRINT_DEC_WORD
    PSHS D, U           ; preserve D and U
    LDU #STRTMP_TOP     ; set U stack at end of temp string
    PSHS A              ; save A for later
    LDA #0              ; put string terminator in A
    PSHU A              ; put it in temp string
    PULS A              ; restore A
    
PDW01

    PULS D, U, PC

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
