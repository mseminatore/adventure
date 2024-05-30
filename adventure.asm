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

GAME_LOOP01
    JSR CHECK_RULES         ; check for rules

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
; print all that are round for
; the curent room
;----------------------------
CHECK_DECORATIONS
    PSHS A, B, X, Y

    LDY #DECORATIONS        ; get decorator table ptr
    LDB ROOM                ; get current room number
    LDA #SPACE

CHECK_DECORATIONS01
    LDX ,Y                      ; get decorator descriptor
    CMPX #NULL                  ; end of table?
    BEQ CHECK_DECORATIONS_DONE  ; if yes quit

    CMPB DECORATOR_ROOM_OFFSET, Y   ; see if decorator matches room
    BNE CHECK_DECORATIONS02         ; if room doesn't match, skip it

    JSR PUTC                        ; print space
    JSR PUTS                        ; print description

CHECK_DECORATIONS02
    LEAY DECORATOR_SIZE, Y          ; get next table item
    BRA CHECK_DECORATIONS01

CHECK_DECORATIONS_DONE
    PULS A, B, X, Y, PC

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
    CMPA #CARRYING           ; in the pack?
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
    LDX #END_MSG
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
; Counts items being carried
;
; Input: none
; Return: item count in A
;----------------------------
COUNT_ITEMS
    PSHS B, X, Y            ; save B, X and Y
    LDY #ITEMS              ; get items table ptr
    CLRA                    ; zero item count

COUNT_ITEMS01
    LDX ,Y                  ; get item description ptr
    CMPX #NULL              ; is it null?
    BEQ COUNT_ITEMS_DONE    ; if so we are done

    LDB ITEM_LOC_OFFSET,Y   ; get item loc
    CMPB #CARRYING           ; being carried?
    BNE COUNT_ITEMS02       ; if not, continue

    INCA                    ; otherwise inc counter

COUNT_ITEMS02
    LEAY ITEM_SIZE, Y       ; get next item
    BRA COUNT_ITEMS01       ; keep going

COUNT_ITEMS_DONE
    PULS B, X, Y, PC

;----------------------------
; Get an object
;----------------------------
GET
    PSHS D, X       ; save D and X

    JSR COUNT_ITEMS ; how many items do we have?
    CMPA ITEM_LIMIT ; compare it to our limit
    BEQ GET04       ; if so print msg and quit

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

    CMPX [,Y]       ; see if item matches
    BNE GET02       ; if not...

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA ROOM               ; in current room?
    BNE GET02               ; if not...

    LDA #CARRYING
    STA ITEM_LOC_OFFSET,Y   ; put item in pack
    LDX #PICKUP             ; print pickup msg
    JSR PUTS
    BRA GET_DONE            ; finished!

GET02
    LEAY ITEM_SIZE, Y       ; get next item ptr
    BRA GET01

GET03
    LDX #GETWHAT            ; print can't find item
    JSR PUTS
    BRA GET_DONE

GET04
    LDX #PACK_FULL
    JSR PUTS

GET_DONE
    PULS D, X, PC

;----------------------------
; Drop an object
;----------------------------
DROP
    PSHS D, X       ; save D and X

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
    BEQ DROP03

    CMPX [,Y]       ; see if item matches
    BNE DROP02      ; if not...

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA #CARRYING          ; carrying it?
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
    ORCC #FLAG_Z    ; Z = 1 = true
    RTS

;----------------------------
; never true predicate
;----------------------------
NEVER
    ANDCC #~FLAG_Z  ; z = 0 = false
    RTS

;----------------------------
; true if carrying item
;
; Input: item in X
; Return: z = 1 = true if carrying
;----------------------------
HAVE_ITEM
    PSHS A, Y
    LDY #ITEMS      ; get item table ptr
    PSHS X          ; save copy of X

HAVE_ITEM01
    LDX ,Y              ; get item description ptr
    CMPX #NULL          ; is it null?
    BEQ HAVE_ITEM_FALSE ; if so we are done

    LDX [,Y]            ; get first two chars
    CMPX ,S         ; is item the small sack?
    BNE HAVE_ITEM02     ; if not continue

    LDA ITEM_LOC_OFFSET, Y  ; get item loc
    CMPA #CARRYING           ; are we carrying it?
    BEQ HAVE_ITEM_TRUE      ; if so return true

HAVE_ITEM02
    LEAY ITEM_SIZE, Y   ; get next item
    BRA HAVE_ITEM01     ; continue

HAVE_ITEM_TRUE
    ; ORCC #FLAG_Z    ; z = 1 = true
    SETZ
    BRA HAVE_ITEM_DONE

HAVE_ITEM_FALSE
    ; ANDCC #~FLAG_Z  ; z = 0 = false
    CLRZ

HAVE_ITEM_DONE
    PULS X          ; restore copy of X
    PULS A, Y, PC

;----------------------------
; true if has small sack
;----------------------------
HAVE_SACK
    PSHS X

    LDX #SACK_ID        ; sack ID
    JSR HAVE_ITEM       ; do we have it?

    PULS X, PC

;----------------------------
; true if has backpack
;----------------------------
HAVE_PACK
    PSHS X

    LDX #PACK_ID        ; pack ID
    JSR HAVE_ITEM       ; do we have it>?

    PULS X, PC

;----------------------------
; set default item limit
;----------------------------
SET_ITEMS_DEFAULT
    PSHS A
    LDA #DEFAULT_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

;----------------------------
; set sack item limit
;----------------------------
SET_ITEMS_SACK
    PSHS A
    LDA #SACK_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

;----------------------------
; set pack item limit
;----------------------------
SET_ITEMS_PACK
    PSHS A
    LDA #PACK_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

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
    LDB #ROOM_SIZE  ; room record size in bytes
    MUL             ; compute index offset for room
    LDY #ROOMS      ; get start of room table
    LEAX D, Y       ; get record for current room
    PULS A, B, Y, PC

;-------------------------
; Try to move in given dir
;
; Input: move dir in B
; Return: none
;-------------------------
MOVE
    PSHS A, X

    JSR GET_ROOM_PTR        ; get current room ptr
    LEAX ROOM_MOVE_OFFSET,X ; inc ptr to move tbl
    LDA B, X                ; get next room
    CMPA #-1                ; is invalid?
    BEQ MOVE_ERR            ; if so show err message

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
    LDA #'$'
    JSR PUTC
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
    JSR PRINT_DEC_WORD
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
    JSR PRINT_DEC_BYTE
    LDA #CR
    JSR PUTC

    PULS A, X, PC

;-------------------------
; display health
;-------------------------
HEALTH_CMD
    PSHS A, X
    LDX #HEALTH_START
    JSR PUTS

    LDA HEALTH
    JSR PRINT_DEC_BYTE

    LDX #HEALTH_TAIL
    JSR PUTS
    PULS A, X, PC

;------------------------------------
; display score
;------------------------------------
SCORE_CMD
    PSHS A, X
    LDX #SCORE_START
    JSR PUTS

    LDA SCORE
    JSR PRINT_DEC_BYTE

    LDX #END_MSG
    JSR PUTS
    PULS A, X, PC

;------------------------------------
;
;------------------------------------
DBG_ITEMS
    PSHS A, X
    LDX #PACK_MSG
    JSR PUTS
    JSR COUNT_ITEMS
    JSR PRINT_DEC_BYTE
    LDA #'/'
    JSR PUTC
    LDA ITEM_LIMIT
    JSR PRINT_DEC_BYTE
    LDA #CR
    JSR PUTC
    JSR PUTC

    PULS A, X, PC

;------------------------------------
; Include various function libraries
;------------------------------------
INCLUDE "print.inc"
INCLUDE "io.inc"
INCLUDE "string.inc"
INCLUDE "math.inc"

;[]--------------[]
; Data segment
;[]--------------[]
    PROMPT FCZ ">"

    ; CURSOR FCC "!/-\"

    UNKCMD FCC "I DON'T UNDERSTAND! TRY AGAIN?" FCB CR, CR, EOS

    WELCOME_MSG1 FCZ "\r\r\r\r  WELCOME TO mystery mansion!\r\r           A GAME BY\r  MARK AND MATTHEW SEMINATORE\r\r      COPYRIGHT (C) 2024\r      ALL RIGHTS RESERVED."

    NOMOVE FCC "YOU CAN'T GO THAT WAY!" FCB CR, CR, EOS

    DIED FCZ "YOU HAVE died! TRY AGAIN.\r\r"

    NORTH_MOVE FCC "YOU MOVE TO THE NORTH." FCB CR, CR, EOS
    SOUTH_MOVE FCC "YOU MOVE TO THE SOUTH." FCB CR, CR, EOS
    EAST_MOVE FCC "YOU MOVE TO THE EAST." FCB CR, CR, EOS
    WEST_MOVE FCC "YOU MOVE TO THE WEST." FCB CR, CR, EOS

    ROOM_MSG FCZ "ROOM "
    MOVE_MSG FCZ "MOVES "

    START_MSG FCZ "YOU WAKE UP. YOUR HEAD HURTS. YOU CAN'T REMEMBER...ANYTHING. YOU MUST FIND YOUR WAY OUT. "

    NOITEMS FCZ "NOTHING!\r\r"

    PACK_MSG FCZ "YOU ARE CARRYING: "
    END_MSG FCZ ".\r\r"
    PACK_GLUE_MSG FCZ ", AND "
    PACK_FULL FCZ "YOU CAN'T CARRY ANY MORE!\r\r"

    ITEM_MSG1 FCZ " THERE IS A "
    ITEM_MSG2 FCZ " HERE."
    THEREISNO FCZ "THERE IS NO "
    GETWHAT FCZ "GET WHAT?\r\r"
    HELP_MSG FCZ "TRY VERBS LIKE: LOOK, NORTH, PACK, GET, DROP\r"
    PICKUP FCZ "YOU PICK UP THE ITEM.\r\r"
    DROPWHAT FCZ "DROP WHAT?\r\r"
    DROPITEM FCZ "YOU DROP THE ITEM.\r\r"

    HEALTH_START FCZ "YOU HAVE "
    HEALTH_TAIL FCZ " HP LEFT.\r\r"

    SCORE_START FCZ "YOUR SCORE IS "

    ; MATCH FCZ "Match!\r\r"
    ; ALWAYS_MSG FCZ "ALWAYS!\r"
    ; NEVER_MSG FCZ "NEVER!\r"
    ; PASS_MSG FCZ "PASS!\r"

    ;---------------------------
    ; Room descriptions
    ;---------------------------
    HALL FCZ "YOU ARE IN A HALLWAY."
    STAIRS FCZ "YOU ARE ON A STAIRWAY."
    CELLAR FCZ "YOU ARE IN A CELLAR."
    LANDING FCZ "YOU ARE ON A LANDING."

    RD0 FCZ "YOU ARE IN A SMALL DIMLY LIT ROOM. MAYBE A CLOSET? IT SMELLS LIKE BLEACH. A DOOR IS IN THE EAST WALL."
    RD1 FCZ "THERE IS AN OPEN DOOR TO THE WEST."
    RD5 FCZ "TO THE SOUTH THERE IS HOLE IN THE FLOOR."
    RD6 FCZ "YOU ARE IN A SMALL RESTROOM."
    RD8 FCZ "YOU ARE IN A LARGE LIBRARY. DUSTY BOOKS LINE SHELVES ON THE NORTH WALL. TO THE EAST IS A HALLWAY. TO THE WEST STAIRS LEAD UPWARD."
    RD13 FCZ "YOU ARE IN A SMALL PARLOR."
    RD14 FCZ "YOU ARE AT THE BOTTOM OF A PIT. THERE IS AN OPENING TO THE SOUTH."
    RD21 FCZ "YOU ARE IN A LARGE BEDROOM."
    RD29 FCZ "YOU ARE AT THE TOP OF THE STAIRWAY. PASSAGES LEAD EAST, WEST AND STAIRS LEAD SOUTH."
    RD31 FCZ "YOU ARE AT AN INTERSECTION. PASSAGES LEAD NORTH, SOUTH, EAST AND WEST."
    RD34 FCZ "RUBBLE BLOCKS THE WAY NORTH."
    RD43 FCZ "YOU ARE IN A KITCHEN. THERE IS A DUMBWAITER IN THE CORNER."
    RD46 FCZ "YOU ARE IN A SMALL WORKROOM. A WOODEN BENCH IS ON THE SOUTH WALL."
    RD56 FCZ "YOU ARE IN A SMALL STOREROOM. IT SMELLS LIKE ROTTEN CHEESE."
    RD63 FCZ "YOU ARE IN A SMALL STOREROOM. IT SMELLS LIKE SOUR WINE."
    RD65 FCZ "YOU ARE IN A DINING ROOM."
    RD70 FCZ "YOU ARE IN A SITTING ROOM."

    ;---------------------------
    ; Decorator descriptions
    ;---------------------------
    SCONCE FCZ "LIGHT FLICKERS IN A WALL SCONCE."
    SLIMY_STONE FCZ "THE WALLS ARE SLIMY AND MADE OF ROUGH STONE."
    TILED FCZ "THE FLOOR AND WALLS ARE TILED."
    DUSTY FCZ "DUST MOTES SWIRL IN THE AIR."

    ; smells
    MUSTY FCZ "THE AIR SMELLS MUSTY."

    ; sounds
    DRIPPING FCZ "YOU HEAR WATER DRIPPING NEARBY."
    INSECTS FCZ "A CRICKET CHIRPS SOFTLY."

    ; passages
    NOSO FCZ "PASSAGES LEAD NORTH AND SOUTH."
    EAWE FCZ "PASSAGES LEAD EAST AND WEST."
    NOWE FCZ "PASSAGES LEAD NORTH AND WEST."
    SOWE FCZ "PASSAGES LEAD WEST AND SOUTH."
    NOEA FCZ "PASSAGES LEAD NORTH AND EAST."
    SOEA FCZ "PASSAGES LEAD SOUTH AND EAST."

    NOSOWE FCZ "PASSAGES LEAD NORTH, SOUTH AND WEST."
    EAWESO FCZ "PASSAGES LEAD EAST, WEST AND SOUTH."

    NORD FCZ "A PASSAGE LEADS NORTH."
    EST FCZ "A PASSAGE LEADS EAST."
    SUD FCZ "A PASSAGE LEADS SOUTH."
    OEST FCZ "A PASSAGE LEADS WEST."

    ST_EAWE FCZ "STAIRS LEAD EAST AND WEST."
    ST_NOSO FCZ "STAIRS LEAD NORTH AND SOUTH."
    ST_NOEA FCZ "STAIRS LEAD NORTH AND EAST."

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
    MOP FCZ "MOP"
    BLEACH FCZ "BOTTLE OF BLEACH"
    CHEESE FCZ "SWISS CHEESE"
    WINE FCZ "WINE BOTTLE"
    HAMMER FCZ "HAMMER"
    FLASHLIGHT FCZ "FLASHLIGHT"
    BUCKET FCZ "BUCKET"
    RING FCZ "RING"
    ROPE FCZ "ROPE"

;---------------------------
; Item table
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
    FDB SMALL_SACK FCB 0
    FDB HAMMER FCB 46
    FDB CHEESE FCB 56
    FDB WINE FCB 63
    FDB BUCKET FCB 33
    FDB RING FCB 65
    FDB ROPE FCB 43
    ; FDB FLASHLIGHT FCB 0
    FDB NULL    ; end of table

;---------------------------
; Command jump table
; Format: char, function
;---------------------------
CMDS
    FCC "LO" FDB PASS           ; look around
    FCC "NO" FDB NORTH          ; move dirs
    FCC "SO" FDB SOUTH          
    FCC "EA" FDB EAST
    FCC "WE" FDB WEST
    FCC "QU" FDB RESET          ; quit game
    FCC "IN" FDB INVENTORY      ; display inventory
    FCC "PA" FDB INVENTORY      ; display inventory
    FCC "OP" FDB PASS           ; open door
    FCC "DR" FDB DROP           ; drop an object
    FCC "GE" FDB GET            ; get an objectø
    FCC "TA" FDB GET            ; take an object
    FCC "MO" FDB MOVES          ; display move count
    FCC "??" FDB PASS           ; help command
    FCC "CL" FDB PASS           ; close door
    FCC "HE" FDB HEALTH_CMD     ; display health
    FCC "SC" FDB SCORE_CMD      ; display score

    ; debug commands
    FCC "RO" FDB DBG_ROOM
    FCC "HO" FDB DBG_HOME
    FCC "RP" FDB DBG_RP
    FCC "IT" FDB DBG_ITEMS
    FDB NULL    ; end of table

;---------------------------
; Decorations table
; Format: descriptor, room
;---------------------------
DECORATIONS
    FDB DRIPPING FCB 0
    FDB NOSO FCB 1 FDB RD1 FCB 1
    FDB NOSO FCB 2 FDB SCONCE FCB 2
    FDB NOSO FCB 3 FDB SCONCE FCB 3
    FDB NOSO FCB 4
    FDB NOSO FCB 5 FDB MUSTY FCB 5 FDB RD5 FCB 5
    FDB TILED FCB 6
    FDB NOSO FCB 7 FDB SCONCE FCB 7
    FDB DUSTY FCB 8
    FDB EAWE FCB 9
    FDB SOWE FCB 10
    FDB NOSO FCB 11
    FDB NOSO FCB 12
    FDB NOEA FCB 13
    FDB SLIMY_STONE FCB 14
    FDB SLIMY_STONE FCB 15 FDB NOWE FCB 15
    FDB ST_EAWE FCB 16
    FDB EAWE FCB 17
    FDB NOSOWE FCB 18
    FDB NOSO FCB 19
    FDB NOSO FCB 20
    FDB DUSTY FCB 21
    FDB NOSO FCB 22
    FDB NOSO FCB 23 FDB MUSTY FCB 23
    FDB DRIPPING FCB 24
    FDB ST_NOEA FCB 25
    FDB ST_NOSO FCB 26
    FDB ST_NOSO FCB 27
    FDB ST_NOSO FCB 28
    FDB EAWE FCB 30
    FDB RD31 FCB 31
    FDB NOSO FCB 32
    FDB SOWE FCB 33
    FDB RD34 FCB 34 FDB EST FCB 34
    FDB EAWE FCB 35
    FDB EAWESO FCB 36
    FDB EAWE FCB 37
    FDB RD31 FCB 38
    FDB NOSO FCB 39
    FDB SOEA FCB 40
    FDB RD34 FCB 41 FDB OEST FCB 41
    FDB EAWE FCB 42
    FDB NOSO FCB 44
    FDB NOSO FCB 45
    FDB NOSO FCB 47
    FDB EAWE FCB 64
    FDB EAWE FCB 65
    FDB EAWE FCB 66
    FDB NOWE FCB 67
    FDB NOSO FCB 68
    FDB NOSO FCB 69

    FDB NULL    ; end of table

;---------------------------
; Room table
; Format: roomdesc,N,S,E,W
;---------------------------
ROOMS
    ; room 0
    FDB RD0
    FCB -1, -1, 1, -1   ; , $80 | $04

    ; room 1
    FDB HALL
    FCB 2, 3, -1, 0

    ; room 2
    FDB HALL
    FCB 4, 1, -1, -1

    ; room 3
    FDB HALL
    FCB 1, 5, -1, -1

    ; room 4
    FDB HALL
    FCB 7, 2, 6, -1

    ; room 5
    FDB HALL
    FCB 3, 14, -1, -1

    ; room 6
    FDB RD6
    FCB -1, -1, -1, 4

    ; room 7
    FDB HALL
    FCB 8, 4, -1, -1

    ; room 8
    FDB RD8
    FCB -1, 7, 9, 16

    ; room 9
    FDB HALL
    FCB -1, -1, 10, 8

    ; room 10
    FDB HALL
    FCB -1, 11, -1, 9

    ; room 11
    FDB HALL
    FCB 10, 12, -1, -1

    ; room 12
    FDB HALL
    FCB 11, 13, -1, -1

    ; room 13
    FDB RD13
    FCB 12, -1, 17, -1

    ; room 14
    FDB RD14
    FCB -1, 15, -1, -1

    ; room 15
    FDB CELLAR
    FCB 14, -1, -1, 30

    ; room 16
    FDB STAIRS
    FCB -1, -1, 8, 25

    ; room 17
    FDB HALL
    FCB -1, -1, 18, 13

    ; room 18
    FDB HALL
    FCB 19, 22, -1, 17

    ; room 19
    FDB HALL
    FCB 20, 18, -1, -1

    ; room 20
    FDB HALL
    FCB 21, 19, -1, -1

    ; room 21
    FDB RD21
    FCB -1, 20, -1, -1

    ; room 22
    FDB HALL
    FCB 18, 23, -1, -1

    ; room 23
    FDB HALL
    FCB 22, 24, -1, -1

    ; room 24
    FDB RD21
    FCB 23, -1, -1, -1

    ; room 25
    FDB LANDING
    FCB 26, -1, 16, -1

    ; room 26
    FDB STAIRS
    FCB 27, 25, -1, -1

    ; room 27
    FDB STAIRS
    FCB 28, 26, -1, -1

    ; room 28
    FDB STAIRS
    FCB 29, 27, -1, -1

    ; room 29
    FDB RD29
    FCB -1, 28, -1, -1

    ; room 30
    FDB CELLAR
    FCB -1, -1, 15, 31

    ; room 31
    FDB CELLAR
    FCB 32, 51, 30, 35

    ; room 32
    FDB CELLAR
    FCB 33, 31, -1, -1

    ; room 33
    FDB CELLAR
    FCB -1, 32, -1, 34

    ; room 34
    FDB CELLAR
    FCB -1, -1, 33, -1

    ; room 35
    FDB CELLAR
    FCB -1, -1, 31, 36

    ; room 36
    FDB CELLAR
    FCB -1, 47, 35, 37
    
    ; room 37
    FDB CELLAR
    FCB -1, -1, 36, 38

    ; room 38
    FDB CELLAR
    FCB 39, 44, 37, 42

    ; room 39
    FDB CELLAR
    FCB 40, 38, -1, -1

    ; room 40
    FDB CELLAR
    FCB -1, 39, 41, -1

    ; room 41
    FDB CELLAR
    FCB -1, -1, -1, 40

    ; room 42
    FDB CELLAR
    FCB -1, -1, 38, 43

    ; room 43
    FDB RD43
    FCB -1, -1, 42, -1

    ; room 44
    FDB CELLAR
    FCB 38, 45, -1, -1

    ; room 45
    FDB CELLAR
    FCB 44, 46, -1, -1

    ; room 46
    FDB RD46
    FCB 45, -1, -1, -1

    ; room 47
    FDB CELLAR
    FCB 36, 48, -1, -1

    ; room 48
    FDB CELLAR
    FCB 47, -1, 49, -1

    ; room 49
    FDB CELLAR
    FCB -1, -1, 50, 48

    ; room 50
    FDB CELLAR
    FCB 51, 52, 57, 49

    ; room 51
    FDB CELLAR
    FCB 31, 50, -1, -1

    ; room 52
    FDB CELLAR
    FCB 50, 53, -1, -1

    ; room 53
    FDB CELLAR
    FCB 52, -1, -1, 54

    ; room 54
    FDB CELLAR
    FCB -1, 55, 53, -1

    ; room 55
    FDB CELLAR
    FCB 54, 56, -1, -1

    ; room 56
    FDB RD56
    FCB 55, -1, -1, -1

    ; room 57
    FDB CELLAR
    FCB -1, -1, 58, 50

    ; room 58
    FDB CELLAR
    FCB -1, 59, -1, 57

    ; room 59
    FDB CELLAR
    FCB 58, 60, -1, -1

    ; room 60
    FDB CELLAR
    FCB 59, -1, 61, -1

    ; room 61
    FDB CELLAR
    FCB -1, 62, -1, 60

    ; room 62
    FDB CELLAR
    FCB 61, 63, -1, -1

    ; room 64
    FDB RD63
    FCB 62, -1, -1, -1

    ; room 65
    FDB RD65
    FCB -1, -1, 66, 64

    ; room 66
    FDB HALL
    FCB -1, -1, 67, 65

    ; room 67
    FDB HALL
    FCB 68,-1,-1,66

    ; room 68
    FDB HALL
    FCB 69,67,-1,-1

    ; room 69
    FDB HALL
    FCB 70,68,-1,-1

    ; room 70
    FDB RD70
    FCB -1,69,-1,-1

    ; room 71
    FDB HALL
    FCB -1,-1,29,-1

;---------------------------
; Rules table
; format: predicate, action
;---------------------------
RULES
    ; FDB NEVER, PASS                 ; do nothing test rule
    FDB ALWAYS, SET_ITEMS_DEFAULT   ; set base inventory limit
    FDB HAVE_SACK, SET_ITEMS_SACK   ; sack gives more items
    FDB HAVE_PACK, SET_ITEMS_PACK   ; backpack gives even more
    FDB NULL                        ; end of table

;---------------------------
; Vars and structures
;---------------------------
    ITEM_LIMIT FCB 0    ; limit of items carried, modified by rules
    ROOM FCB 0          ; current room number
    MOVE_COUNT FDB 0    ; total number of moves
    DARK FCB 0          ; true if dark

    ; player stats
    HEALTH FCB 100      ; current HP
    ; ATTACK FCB 0        ; attack damage
    ; DEFENSE FCB 0       ; defence rating

    SCORE FDB 0         ; score achieved

    END START
