    RECSIZE EQU 8           ; size of room record
    PACKSIZE EQU 8          ; size of backpack
    EMPTY_SLOT EQU $FF           ; empty backpack slot
    CMD_FN_OFFSET EQU 2     ; cmd table fn offset
    CMD_TABLE_ENTRY EQU 4   ; size of cmd table record
    ROOM_DECORATOR_OFFSET EQU 6
    NULL EQU 0
    IN_PACK EQU $FF
    
    ITEM_SIZE EQU 3
    ITEM_LOC_OFFSET EQU 2
    
    RULE_SIZE EQU 4
    RULE_ACTIOM_OFFSET EQU 2