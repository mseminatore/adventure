;[]******************************************************[]
; Text adventure
;
; Copyright 2024 by Mark Seminatore. All rights reserved.
;[]******************************************************[]
    INCLUDE "stddefs.inc"
    INCLUDE "gamedefs.inc"

    SETDP $0        ; leave direct page at 0
    ORG $3F00       ; set our load origin

START
    LDS #RAMEND     ; setup stack

    LDB #0
    TFR B, DP       ; make sure DP is set to 0

    ; zero out move counter
    LDX #MOVE_COUNT
    STB ,X+
    STB ,X

    JSR CLS         ; clear screen
    
    LDX #WELCOME_MSG1
    JSR PUTS
    JSR WAIT
    JSR CLS

    LDX #START_MSG  ; show start-up message
    JSR PUTS

    BRA GAME_LOOP01 ; skip the initial room description

GAME_LOOP
    JSR LOOK                ; describe current room

    JSR CHECK_DECORATIONS   ; print any room decorations

    JSR CHECK_ITEMS         ; print any items

    JSR CHECK_DOORS         ; print any doors

    JSR CHECK_RULES         ; check for rules

GAME_LOOP01
    LDA #CR         ; newlines
    JSR PUTC

    LDX #PROMPT     ; display input prompt
    JSR PUTS

    LDX #INBUF      ; get input
    JSR GETS

    LDA #CR         ; newlines
    JSR PUTC
    JSR PUTC

    JSR DO_CMD      ; try to execute a command

    JSR INC_MOVES   ; inc move count

    BRA GAME_LOOP   ; back to top of game loop

;----------------------------
; check for room decorations
;----------------------------
CHECK_DECORATIONS
    PSHS A, X

    JSR GET_ROOM_PTR                ; get current room ptr
    LDX ROOM_DECORATOR_OFFSET, X    ; get decorator ptr
    CMPX #NULL                      ; NULL?
    BEQ CHECK_DECORATIONS01         ; if so we're done

    JSR PUTS            ; print description

CHECK_DECORATIONS01
    PULS A, X, PC

;----------------------------
; check for doors
;
; Input: none
; Return: none
;----------------------------
CHECK_DOORS
    RTS

;----------------------------
; Execute room rules
;
; Input: none
; Return: none
;----------------------------
CHECK_RULES
    PSHS X, Y

    LDY #RULES              ; get rules table ptr

CHECK_RULES01
    LDX ,Y                  ; get rule pred ptr
    CMPX #NULL              ; is it NULL?
    BEQ CHECK_RULES_DONE    ; if so done

    JSR [,Y]                ; call predicate, if THIS
    BNE CHECK_RULES02       ; if false do next rule

    JSR [RULE_ACTIOM_OFFSET,Y]  ; then do the ACTION

CHECK_RULES02
    LEAY RULE_SIZE,Y        ; get next rule ptr
    BRA CHECK_RULES01

CHECK_RULES_DONE
    PULS X, Y, PC

;----------------------------
; check for room items
;
; Input: none
; Return: none
;----------------------------
CHECK_ITEMS
    PSHS A, X, Y, U
    LDY #ITEMS          ; get items table ptr

CHECK_ITEMS01
    LDX ,Y                  ; get item description ptr
    CMPX #NULL              ; done?
    BEQ CHECK_ITEMS_DONE    ; if so quit

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA ROOM               ; in current room?
    BNE CHECK_ITEMS02       ; if not...

    TFR X, U            ; save X
    LDX #ITEM_MSG1      ; get item preamble
    JSR PUTS            ; print it
    TFR U, X            ; restore X
    JSR PUTS            ; print item description
    LDX #ITEM_MSG2      ; get item postamble
    JSR PUTS            ; print it

CHECK_ITEMS02
    LEAY ITEM_SIZE, Y   ; point to next item
    BRA CHECK_ITEMS01   ; do next item

CHECK_ITEMS_DONE
    PULS A, X, Y, U, PC

;----------------------------
; Display pack items
;
; Input: none
; Return: none
;----------------------------
INVENTORY
    PSHS A, B, X, Y

    LDY #ITEMS          ; get items table ptr
    LDX #PACK_MSG       ; print pack message
    JSR PUTS
    CLRB                ; zero item counter

INV01
    LDX ,Y              ; get item description ptr
    CMPX #NULL          ; done?
    BEQ INV04           ; if yes...

    LDA ITEM_LOC_OFFSET, Y  ; get item loc
    CMPA #IN_PACK           ; in the pack?
    BNE INV03               ; if not...

    CMPB #0                 ; is this the first item?
    BEQ INV02               ; if so...

    PSHS X
    LDX #PACK_GLUE_MSG
    JSR PUTS
    PULS X

INV02
    LDA #'A'
    JSR PUTC
    LDA #SPACE
    JSR PUTC
    JSR PUTS                ; print item description
    INCB                    ; inc item count

INV03
    LEAY ITEM_SIZE, Y       ; point to next item
    BRA INV01

INV04
    CMPB #0                 ; pack empty?
    BNE INV05               ; if not...

    LDX #NOITEMS            ; pack is empty!
    JSR PUTS
    BRA INVENTORY_DONE

INV05
    LDX #END_PACK_MSG
    JSR PUTS

INVENTORY_DONE
    PULS A, B, X, Y, PC

;----------------------------
; increment the move counter
;
; Input: none
; Return: none
;----------------------------
INC_MOVES
    PSHS D
    
    LDD #1
    ADDD MOVE_COUNT
    STD MOVE_COUNT

    PULS D, PC

;----------------------------
; Skip leading spaces in X
;
; Input: ptr to string in X
; Return: ptr to first non-space in X
;----------------------------
SKIP_SPACES
    PSHS A

    LDA #SPACE

SKIP_SPACES01
    CMPA ,X
    BNE SKIP_SPACES_DONE

    LEAX 1, X
    BRA SKIP_SPACES01

SKIP_SPACES_DONE
    PULS A, PC

;----------------------------
; Get an object
;----------------------------
GET
    PSHS D, X

    LDX #INBUF      ; get input buffer

    LDA #SPACE      ; space delimiter
    JSR STRCHR      ; look for space

    JSR SKIP_SPACES

    CMPX #NULL      ; no more words?
    BEQ GET03

    LDX ,X          ; get first two chars of word
    LDY #ITEMS      ; get items table ptr

GET01
    LDD ,Y          ; get item description ptr
    CMPD #NULL
    BEQ GET_DONE

    CMPX [,Y]         ; see if item matches
    BNE GET02       ; if not...

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA ROOM               ; in current room?
    BNE GET02       ; if not...

    LDA #IN_PACK
    STA ITEM_LOC_OFFSET,Y   ; put item in pack
    LDX #PICKUP
    JSR PUTS
    BRA GET_DONE

GET02
    LEAY ITEM_SIZE, Y   ; get next item
    BRA GET01

GET03
    LDX #GETWHAT
    JSR PUTS

GET_DONE
    PULS D, X, PC

;----------------------------
; Drop an object
;----------------------------
DROP
    PSHS D, X

    LDX #INBUF      ; get input buffer

    LDA #SPACE      ; space delimiter
    JSR STRCHR      ; look for space

    JSR SKIP_SPACES

    CMPX #NULL      ; no more words?
    BEQ DROP03

    LDX ,X          ; get first two chars of word
    LDY #ITEMS      ; get items table ptr

DROP01
    LDD ,Y          ; get item description ptr
    CMPD #NULL      ; if NULL we are at end of list
    BEQ DROP_DONE

    CMPX [,Y]       ; see if item matches
    BNE DROP02      ; if not...

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA #IN_PACK           ; in current room?
    BNE DROP02              ; if not...

    LDA ROOM                ; get current room num
    STA ITEM_LOC_OFFSET,Y   ; put item in pack
    LDX #DROPITEM           ; print item drop message
    JSR PUTS
    BRA DROP_DONE

DROP02
    LEAY ITEM_SIZE, Y   ; get next item
    BRA DROP01

DROP03
    LDX #DROPWHAT
    JSR PUTS

DROP_DONE
    PULS D, X, PC

;----------------------------
; Do nothing and return!
;
; Input: none
; Return: none
;----------------------------
PASS
    RTS

;----------------------------
; always true predicate
;----------------------------
ALWAYS
    ORCC #FLAG_Z
    RTS

;----------------------------
; never true predicate
;----------------------------
NEVER
    ANDCC #~FLAG_Z
    RTS

;----------------------------
; Attempt to execute a command
;
; Input: ptr to cmd buf in X
; Return: none
;----------------------------
DO_CMD
    PSHS X, Y

    LDX ,X         ; get cmd chars
    LDY #CMDS       ; Y points to cmd table

CMD_LOOP
    CMPX ,Y         ; see if we found a match
    BEQ EXECCMD     ; yes, do command

    LEAY CMD_TABLE_ENTRY, Y       ; point to next command in table
    TST ,Y          ; see if we are at end of cmds
    BNE CMD_LOOP    ; if not, continue

    LDX #UNKCMD     ; show err message
    JSR PUTS

    BRA CMD_DONE    ; done with commands

EXECCMD
    JSR [CMD_FN_OFFSET, Y]      ; point to cmd function and call it!

CMD_DONE
    PULS X, Y, PC

;-------------------------
; Get ptr to current room
;
; Input: none
; Return: room ptr in X
;-------------------------
GET_ROOM_PTR
    PSHS A, B, Y

    LDA ROOM        ; get current room number
    LDB #RECSIZE     ; room record size in bytes
    MUL             ; compute index offset for room
    LDY #ROOMS      ; get start of room table
    LEAX D, Y        ; get record for current room
    PULS A, B, Y, PC

;-------------------------
; Try to move in given dir
;
; Input: move dir in B
; Return: none
;-------------------------
MOVE
    PSHS A, X

    JSR GET_ROOM_PTR    ; get current room ptr
    LEAX 2,X            ; inc ptr to move tbl
    LDA B, X            ; get next room
    CMPA #-1            ; is invalid?
    BEQ MOVE_ERR        ; if so show err message

    ORCC #FLAG_C        ; set carry
    STA ROOM            ; otherwise update room
    PULS A, X, PC

MOVE_ERR
    LDX #NOMOVE         ; print move err msg
    JSR PUTS
    ANDCC #~FLAG_C      ; clear carry

    PULS A, X, PC

;-------------------------
; try move to north
;-------------------------
NORTH
    PSHS B, X
    LDB #0
    JSR MOVE
    BCC NORTH_DONE

    LDX #NORTH_MOVE
    JSR PUTS

NORTH_DONE
    PULS B, X, PC

;-------------------------
; try move to south
;-------------------------
SOUTH
    PSHS B, X
    LDB #1
    JSR MOVE
    BCC SOUTH_DONE

    LDX #SOUTH_MOVE
    JSR PUTS

SOUTH_DONE
    PULS B, X, PC

;-------------------------
; try move to east
;-------------------------
EAST
    PSHS B, X
    LDB #2
    JSR MOVE
    BCC EAST_DONE

    LDX #EAST_MOVE
    JSR PUTS

EAST_DONE
    PULS B, X, PC

;-------------------------
; try move to west
;-------------------------
WEST
    PSHS B, X
    LDB #3
    JSR MOVE
    BCC WEST_DONE

    LDX #WEST_MOVE
    JSR PUTS

WEST_DONE
    PULS B, X, PC

;-------------------------
; Look command
;
; Input: none
; Return: none
;-------------------------
LOOK
    PSHS X
    JSR GET_ROOM_PTR    ; get current room ptr
    LDX ,X              ; get room description
    JSR PUTS            ; print it out
    PULS X, PC

;-------------------------
; go back to start room
;-------------------------
DBG_HOME
    PSHS A
    CLRA            ; room 0
    STA ROOM        ; set room
    PULS A, PC

;-------------------------
; print current room ptr
;-------------------------
DBG_RP
    PSHS A, X
    JSR GET_ROOM_PTR
    JSR PRINT_HEX_WORD      ; 
    LDA #CR
    JSR PUTC

    PULS A, X, PC

;-------------------------
; display move count
;-------------------------
MOVES
    PSHS A, X

    LDX #MOVE_MSG
    JSR PUTS

    LDX MOVE_COUNT
    JSR PRINT_HEX_WORD
    LDA #CR
    JSR PUTC

    PULS A, X, PC

;-------------------------
; print cur room num
;-------------------------
DBG_ROOM
    PSHS A, X

    LDX #ROOM_MSG
    JSR PUTS

    LDA ROOM
    JSR PRINT_HEX_BYTE
    LDA #CR
    JSR PUTC

    PULS A, X, PC

INCLUDE "print.inc"
INCLUDE "io.inc"
INCLUDE "string.inc"

;[]--------------[]
; Data segment
;[]--------------[]
    PROMPT FCZ ">"

    ; CURSOR FCC "!/-\"

    UNKCMD FCC "I DON'T UNDERSTAND! TRY AGAIN?" FCB CR, CR, EOS

    WELCOME_MSG1 FCZ "\r\r\r\r  WELCOME TO haunted mansion!\r\r           A GAME BY\r  MARK AND MATTHEW SEMINATORE\r\r      COPYRIGHT (C) 2024\r      ALL RIGHTS RESERVED."

    NOMOVE FCC "YOU CAN'T GO THAT WAY!" FCB CR, CR, EOS

    NORTH_MOVE FCC "YOU MOVE TO THE NORTH." FCB CR, CR, EOS
    SOUTH_MOVE FCC "YOU MOVE TO THE SOUTH." FCB CR, CR, EOS
    EAST_MOVE FCC "YOU MOVE TO THE EAST." FCB CR, CR, EOS
    WEST_MOVE FCC "YOU MOVE TO THE WEST." FCB CR, CR, EOS

    ROOM_MSG FCC "ROOM " FCB EOS

    MOVE_MSG FCC "MOVES " FCB EOS

    START_MSG FCC "YOU WAKE UP. YOUR HEAD HURTS. YOU CAN'T REMEMBER...ANYTHING. ALL YOU HAVE IS AN EMPTY BACKPACK. " FCB EOS

    NOITEMS FCC "NOTHING!" FCB CR, CR, EOS

    PACK_MSG FCZ "YOUR PACK CONTAINS: "
    END_PACK_MSG FCC "." FCB CR, CR, EOS
    PACK_GLUE_MSG FCZ ", AND "
    ITEM_MSG1 FCZ " THERE IS A "
    ITEM_MSG2 FCZ " HERE."
    THEREISNO FCZ "THERE IS NO "
    GETWHAT FCZ "GET WHAT?\r\r"
    HELP_MSG FCC "TRY VERBS LIKE: LOOK, NORTH, PACK, GET, DROP" FCB CR, EOS
    PICKUP FCZ "YOU PICK UP THE ITEM.\r\r"
    DROPWHAT FCZ "DROP WHAT?\r\r"
    DROPITEM FCZ "YOU DROP THE ITEM.\r\r"

    MATCH FCZ "Match!\r\r"
    ; ALWAYS_MSG FCZ "ALWAYS!\r"
    ; NEVER_MSG FCZ "NEVER!\r"
    ; PASS_MSG FCZ "PASS!\r"

    ;---------------------------
    ; Room descriptions
    ;---------------------------
    NOSO FCZ "YOU ARE IN A HALLWAY. PASSAGES LEAD NORTH AND SOUTH."
    EAWE FCZ "YOU ARE IN A HALLWAY. PASSAGES LEAD EAST AND WEST."
    NOWE FCZ "YOU ARE IN A HALLWAY. PASSAGES LEAD NORTH AND WEST."
    SOWE FCZ "YOU ARE IN A HALLWAY. PASSAGES LEAD WEST AND SOUTH."

    RD0 FCZ "YOU ARE IN A SMALL DIMLY LIT ROOM. YOU HEAR WATER DRIPPING SOMEWHERE NEARBY. IT MIGHT BE A CLOSET. IT SMELLS LIKE BLEACH. A DOOR IS IN THE EAST WALL."
    RD1 FCZ "YOU ARE IN A HALLWAY. PASSAGES LEAD NORTH AND SOUTH. THERE IS AN OPEN DOOR TO THE WEST."
    RD5 FCZ "YOU ARE IN A NORTH-SOUTH HALLWAY. TO THE SOUTH THERE IS HOLE IN THE FLOOR."
    RD6 FCZ "YOU ARE IN A SMALL RESTROOM."
    RD8 FCZ "YOU ARE IN A LARGE LIBRARY. DUSTY BOOKS LINE SHELVES ON THE NORTH WALL. TO THE EAST IS A HALLWAY. TO THE WEST STAIRS LEAD UPWARDS."
    RD13 FCZ "YOU ARE IN A SMALL SITTING ROOM. OPENINGS LEAD NORTH AND EAST."
    RD14 FCZ "YOU ARE AT THE BOTTOM OF A PIT. THERE IS AN OPENING TO THE SOUTH."
    RD16 FCZ "YOU ARE ON A STAIRWAY. STAIRS LEAD EAST AND WEST."
    RD21 FCZ "YOU ARE IN A LARGE BEDROOM."
    RD25 FCZ "YOU ARE ON A LANDING. STAIRS LEAD NORTH AND EAST."
    RD26 FCZ "YOU ARE ON A STAIRWAY. STAIRS LEAD NORTH AND SOUTH."
    RD29 FCZ "YOU ARE AT THE TOP OF THE STAIRWAY. PASSAGES LEAD EAST, WEST AND STAIRS LEAD SOUTH."
    RD31 FCZ "YOU ARE AT AN INTERSECTION. PASSAGES LEAD NORTH, SOUTH, EAST AND WEST."
    RD34 FCZ "YOU ARE IN THE BASEMENT. RUBBLE BLOCKS THE WAY NORTH. A PASSAGE LEADS TO THE EAST."

    ;---------------------------
    ; Decorator descriptions
    ;---------------------------
    D0 FCZ "THERE IS A SCONCE ON THE WALL."
    D1 FCZ "THE WALLS ARE MADE OF ROUGH STONE."
    D2 FCZ "THE AIR SMELLS MUSTY."
    D3 FCZ "THE FLOOR AND WALLS ARE TILED."
    D4 FCZ "DUST MOTES SWIRL IN THE AIR."

    ;---------------------------
    ; Object descriptions
    ;---------------------------
    RED_KEY FCZ "RED KEY"
    BLUE_KEY FCZ "BLUE KEY"
    GREEN_KEY FCZ "GREEN KEY"
    GOLD_KEY FCZ "GOLD KEY"
    SILVER_KEY FCZ "SILVER KEY"
    BROWN_BOOK FCZ "LEATHER BOOK"
    SMALL_SACK FCZ "SMALL SACK"
    BACKPACK FCZ "BACKPACK"
    MOP FCZ "OLD MOP"
    BLEACH FCZ "BOTTLE OF BLEACH"
    CHEESE FCZ "MOLDY CHEESE"
    WINE FCZ "WINE BOTTLE"
    HAMMER FCZ "HAMMER"
    FLASHLIGHT FCZ "FLASHLIGHT"

;---------------------------
; Object table
; Format: description, room
;---------------------------
ITEMS
    FDB RED_KEY FCB 6
    FDB BLUE_KEY FCB 13
    FDB GREEN_KEY FCB 8
    FDB GOLD_KEY FCB 14
    FDB SILVER_KEY FCB 21
    FDB BROWN_BOOK FCB 24
    FDB MOP FCB 0
    FDB BLEACH FCB 0
    FDB BACKPACK FCB 65
    FDB HAMMER FCB 46
    FDB CHEESE FCB 56
    FDB WINE FCB 63
    FDB NULL

;---------------------------
; Command jump table
;---------------------------
CMDS
    FCC "LO" FDB PASS           ; look around
    FCC "NO" FDB NORTH          ; move dirs
    FCC "SO" FDB SOUTH          
    FCC "EA" FDB EAST
    FCC "WE" FDB WEST
    FCC "QU" FDB RESET          ; quit game
    FCC "IN" FDB INVENTORY      ; display inventory
    FCC "PA" FDB INVENTORY
    FCC "OP" FDB PASS           ; open door
    FCC "DR" FDB DROP           ; drop an object
    FCC "GE" FDB GET            ; get an objectø
    FCC "TA" FDB GET            ; take an object
    FCC "MO" FDB MOVES          ; display move count
    FCC "HE" FDB PASS           ; help command
    FCC "CL" FDB PASS           ; close door

    ; debug commands
    FCC "RO" FDB DBG_ROOM
    FCC "HO" FDB DBG_HOME
    FCC "RP" FDB DBG_RP
    FDB NULL

;---------------------------
; Room table
;
; format: roomdesc,N,S,E,W,Decorator
;---------------------------
ROOMS 
    
    ; room 0
    FDB RD0
    FCB -1, -1, 1, -1   ; , $80 | $04
    FDB NULL

    ; room 1
    FDB RD1
    FCB 2, 3, -1, 0
    FDB NULL

    ; room 2
    FDB NOSO
    FCB 4, 1, -1, -1
    FDB D0

    ; room 3
    FDB NOSO
    FCB 1, 5, -1, -1
    FDB NULL

    ; room 4
    FDB NOSO
    FCB 7, 2, 6, -1
    FDB NULL

    ; room 5
    FDB RD5
    FCB 3, 14, -1, -1
    FDB NULL

    ; room 6
    FDB RD6
    FCB -1, -1, -1, 4
    FDB D3

    ; room 7
    FDB NOSO
    FCB 8, 4, -1, -1
    FDB NULL

    ; room 8
    FDB RD8
    FCB -1, 7, 9, 16
    FDB NULL

    ; room 9
    FDB EAWE
    FCB -1, -1, 10, 8
    FDB NULL

    ; room 10
    FDB SOWE
    FCB -1, 11, -1, 9
    FDB NULL

    ; room 11
    FDB NOSO
    FCB 10, 12, -1, -1
    FDB NULL

    ; room 12
    FDB NOSO
    FCB 11, 13, -1, -1
    FDB NULL

    ; room 13
    FDB RD13
    FCB 12, -1, 17, -1
    FDB NULL

    ; room 14
    FDB RD14
    FCB -1, 15, -1, -1
    FDB D1

    ; room 15
    FDB NOWE
    FCB 14, -1, -1, 30
    FDB D1

    ; room 16
    FDB RD16
    FCB -1, -1, 8, 25
    FDB NULL

    ; room 17
    FDB EAWE
    FCB -1, -1, 18, 13
    FDB NULL

    ; room 18
    FDB NOWE
    FCB 19, 22, -1, 17
    FDB NULL

    ; room 19
    FDB NOSO
    FCB 20, 18, -1, -1
    FDB NULL

    ; room 20
    FDB NOSO
    FCB 21, 19, -1, -1
    FDB NULL

    ; room 21
    FDB RD21
    FCB -1, 20, -1, -1
    FDB D4

    ; room 22
    FDB NOSO
    FCB 18, 23, -1, -1
    FDB NULL

    ; room 23
    FDB NOSO
    FCB 22, 24, -1, -1
    FDB D2

    ; room 24
    FDB RD21
    FCB 23, -1, -1, -1
    FDB D4

    ; room 25
    FDB RD25
    FCB -1, -1, 16, -1
    FDB NULL

    ; room 26
    FDB RD26
    FCB 27, 25, -1, -1
    FDB NULL

    ; room 27
    FDB RD26
    FCB 28, 26, -1, -1
    FDB NULL

    ; room 28
    FDB RD26
    FCB 29, 27, -1, -1
    FDB NULL

    ; room 29
    FDB RD29
    FCB -1, 28, -1, -1
    FDB NULL

    ; room 30
    FDB EAWE
    FCB -1, -1, 15, 31
    FDB NULL

    ; room 31
    FDB RD31
    FCB 32, 51, 30, 35
    FDB NULL

    ; room 32
    FDB NOSO
    FCB 33, 31, -1, -1
    FDB NULL

    ; room 33
    FDB SOWE
    FCB -1, 32, -1, 34
    FDB NULL

    ; room 34
    FDB RD34
    FCB -1, -1, 33, -1
    FDB NULL

    ; room 35
    ; FDB EAWE
    ; FCB 
    
;---------------------------
; Rules table
; format: predicate, action
;---------------------------
RULES
    FDB NEVER, PASS     ; do nothing test rule
    FDB NULL

;---------------------------
; Vars and structures
;---------------------------
    ; PACK RMB PACKSIZE   ; backpack
    ROOM FCB 0          ; current room number
    MOVE_COUNT FDB 0         ; total number of moves
    DARK FCB 0
    HEALTH FCB 0

    END START
