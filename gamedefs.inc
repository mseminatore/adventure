;------------------------------------
; Common game defines
;
;------------------------------------

    NULL EQU 0                  ; nullptr

    STARTING_HEALTH EQU 100

    ; door locations
    NORTH_WALL  EQU 0
    SOUTH_WALL  EQU 1
    EAST_WALL   EQU 2
    WEST_WALL   EQU 3

    ; door struct
    DOOR_SIZE EQU 4
    DOOR_PTR_OFFSET EQU 0
    DOOR_ROOM_OFFSET EQU 2
    DOOR_WALL_OFFSET EQU 3

    DOBJ_DESC_OFFSET EQU 0
    DOBJ_PROP_OFFSET EQU 2
    
    ; door states
    OPEN_STATE      EQU 1
    LOCKED_STATE    EQU 2

    ; room definitions
    ROOM_START  EQU 0
    CARRYING EQU $FF            ; item is carried
    ROOM_DEAD   EQU 254         ; where dead players go
    ROOM_DUMP   EQU 253         ; where broken/used items go

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

    ; health
    FALL_DMG EQU 20             ; damage taken from falling
    POISON_DMG EQU 20           ; damage taken from poison
    FIRE_DMG EQU 20             ; damage take from fire

    ; object properties
    TAKEABLE    EQU 1           ; can be taken/carried
    EATABLE     EQU 2           ; can be eaten
    DRINKABLE   EQU 4           ; can be drunk
    USABLE      EQU 8           ; can be used
    OPENABLE    EQU 16          ; can be open/closed
    LOCKABLE    EQU 32          ; can be locked/unlocked
    