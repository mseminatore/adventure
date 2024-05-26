    ;--------------
    ; ROM routines
    ;--------------
    CHAROUT EQU $A002
    CHARIN  EQU $A000

    ;--------------
    ; Hardware registers
    ;--------------
    PIA0 EQU $FF00      ; peripheral interface adaptor 0
    PIA1 EQU $FF20      ; peripheral interface adaptor 1
    SAMREG EQU $FFC0    ; SAM control register
    
    ;--------------
    ; int vectors
    ;--------------
    RESET_VECTOR    EQU $FFFE
    NMI_VECTOR      EQU $FFFC
    SWI_VECTOR      EQU $FFFA
    IRQ_VECTOR      EQU $FFF8
    FIRQ_VECTOR     EQU $FFF6
    SWI2_VECTOR     EQU $FFF4
    SWI3_VECTOR     EQU $FFF2

    ;------------------
    ; register flags
    ;------------------
    FLAG_C EQU 1
    FLAG_V EQU 2
    FLAG_Z EQU 4
    FLAG_N EQU 8
    FLAG_I EQU 16
    FLAG_H EQU 32
    FLAG_F EQU 64
    FLAG_E EQU 128
    
    ;------------------
    ; common char defs
    ;------------------
    BS      EQU 8
    CR      EQU 13
    SPACE   EQU 32
    EOS     EQU 0
    CLEAR   EQU 12
    BREAK   EQU 03
    BLANK   EQU $60

    ;------------------
    ; memory locations
    ;------------------
    RSTFLG EQU $71
    VIDRAM EQU $400
    VIDEND EQU $5FF
    VIDSCROLL EQU $5E0
    RAMEND EQU $7FFF
    STACKSIZE EQU 256
    STACKGUARD EQU 16
    STACKEND EQU RAMEND - STACKSIZE
