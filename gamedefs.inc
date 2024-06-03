    NULL EQU 0                  ; nullptr
    CARRYING EQU $FF            ; item is carried

    ; item carry limits
    DEFAULT_ITEM_LIMIT EQU 2
    SACK_ITEM_LIMIT EQU 4
    PACK_ITEM_LIMIT EQU 6

    ; item ID values
    SACK_ID EQU $5341           ; 'SA'
    PACK_ID EQU $4241           ; 'PA'

    ; room struct
    ROOM_SIZE EQU 6             ; size of room entry 2 + 1 x 4 = 6
    ROOM_MOVE_OFFSET EQU 2      ; offset of move items

    ; cmd struct
    CMD_FN_OFFSET EQU 2         ; cmd table fn offset
    CMD_TABLE_ENTRY EQU 4       ; size of cmd table entry 2 + 2 = 4
    
    ; item struct
    ITEM_SIZE EQU 5             ; size of item table entry
    ITEM_LOC_OFFSET EQU 2       ; offset to item location
    ITEM_READ_OFFSET EQU 3      ; offset to item read

    ; rule struct
    RULE_SIZE EQU 4             ; size of rule table entry
    RULE_ACTIOM_OFFSET EQU 2    ; offset to rule action

    ; decorator struct
    DECORATOR_SIZE EQU 3        ; size of decorator table entry
    DECORATOR_ROOM_OFFSET EQU 2 ; offset to room num

    ; transition struct
    TRANSITION_FROM EQU 2       ; offset to FROM
    TRANSITION_TO   EQU 3       ; offset to TO
    TRANSITION_SIZE EQU 4       ; size of transition table entry

    FALL_DMG EQU 20             ; damage taken from falling
