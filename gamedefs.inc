    NULL EQU 0              ; nullptr
    CARRYING EQU $FF         ; item is carried

    DEFAULT_ITEM_LIMIT EQU 2
    SACK_ITEM_LIMIT EQU 4
    PACK_ITEM_LIMIT EQU 6
        
    ROOM_SIZE EQU 6         ; size of room entry 2 + 1 x 4 = 6
    ROOM_MOVE_OFFSET EQU 2  ; offset of move items

    CMD_FN_OFFSET EQU 2     ; cmd table fn offset
    CMD_TABLE_ENTRY EQU 4   ; size of cmd table entry 2 + 2 = 4
    
    ITEM_SIZE EQU 3         ; size of item table entry
    ITEM_LOC_OFFSET EQU 2   ; offset to item location
    
    RULE_SIZE EQU 4             ; size of rule table entry
    RULE_ACTIOM_OFFSET EQU 2    ; offset to rule action

    DECORATOR_SIZE EQU 3
    DECORATOR_ROOM_OFFSET EQU 2
