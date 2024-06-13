;[]---------------------------------------------------------[]
; Mystery Mansion. A work of interactive fiction inspired by
; the classic text adventure games
;
; Copyright (C) 2024 by Mark Seminatore. All rights reserved.
;[]---------------------------------------------------------[]
    INCLUDE "stddefs.inc"
    INCLUDE "gamedefs.inc"

    SETDP $0        ; leave direct page at 0
    ORG $3F00       ; set our load origin
    
START:
    LDS #RAMEND     ; setup stack

    LDB #0
    TFR B, DP       ; make sure DP is set to 0

RESTART:
    JSR INIT        ; init game state

    JSR CLS         ; clear screen
    
    LDX #WELCOME_MSG1
    JSR PUTS
    JSR WAIT
    JSR CLS

    ; LDX #INSTRUCTIONS
    ; JSR PUTS
    ; JSR WAIT
    ; JSR CLS

    LDX #START_MSG  ; show start-up message
    JSR PUTS

    ; TODO - maybe remove this as confusing?
    JSR CHECK_RULES         ; check for rules
    BRA GAME_LOOP01 ; skip the initial room description?

GAME_LOOP:
    JSR CHECK_RULES         ; check for rules

    JSR LOOK_CMD            ; describe current room

GAME_LOOP01:
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

;-----------------------------
; check for room decorations
; print all that are round for
; the curent room
;-----------------------------
CHECK_DECORATIONS:
    PSHS A, B, X, Y

    LDY #DECORATIONS        ; get decorator table ptr
    LDB ROOM                ; get current room number
    LDA #SPACE

CHECK_DECORATIONS01:
    LDX ,Y                      ; get decorator descriptor
    CMPX #NULL                  ; end of table?
    BEQ CHECK_DECORATIONS_DONE  ; if yes quit

    CMPB DECORATOR_ROOM_OFFSET, Y   ; see if decorator matches room
    BNE CHECK_DECORATIONS02         ; if room doesn't match, skip it

    JSR PUTC                        ; print space
    JSR PUTS                        ; print description

CHECK_DECORATIONS02:
    LEAY DECORATOR_SIZE, Y          ; get next table item
    BRA CHECK_DECORATIONS01

CHECK_DECORATIONS_DONE:
    PULS A, B, X, Y, PC

;----------------------------
; check for doors
;
; Input: none
; Return: none
;----------------------------
CHECK_DOORS:
    PSHS A, B, X, Y, U

    JSR GET_ROOM_PTR    ; get room ptr in X

    LEAY 2, X           ; get NSEW rooms ptr
    CLRB                ; clear offset

CHECK_DOORS01:
    CMPB #6
    BGT CHECK_DOORS_DONE

    LDX B, Y            ; get next room dir
    CMPX #-1            ; invalid?
    BEQ CHECK_DOORS03   ; if so, next room dir

    CMPX #255           ; no door?
    BLS CHECK_DOORS03   ; if so, next room dir

    TFR X, U
    LDX #ONTHE_MSG
    JSR PUTS

    LDX #WALL_MSG           ; print which wall
    LDX B, X
    JSR PUTS

    LDX #ITEM_MSG1          ; print 'there is a '
    JSR PUTS

    LDU ,U                  ; get door insta ptr
    LDX ,U                  ; get door desc ptr
    JSR PUTS

    LDA 2, U                ; get door props
    BITA #DOOR_OPEN         ; check door state
    BNE CHECK_DOORS02       ; if closed

    LDX #WHICH_IS_CLOSED
    JSR PUTS

CHECK_DOORS02:
    LDA #'.'
    JSR PUTC

CHECK_DOORS03:
    ADDB #2             ; inc offset
    BRA CHECK_DOORS01   ; keep looking

;     LDY #DOORS      ; get door table ptr
;     LDA ROOM        ; get current room num

; CHECK_DOORS01:
;     LDU ,Y                  ; get door obj ptr
;     CMPU #NULL              ; is it NULL?
;     BEQ CHECK_DOORS_DONE    ; if so done

;     CMPA DOOR_ROOM_OFFSET, Y ; is door in room?
;     BNE CHECK_DOORS02       ; if not go to next door


;     LDA DOOR_WALL_OFFSET, Y ; get wall prop
;     ASLA                
;     LDX #WALL_MSG
;     LDX A, X
;     JSR PUTS

;     LDX #ITEM_MSG1          ; print 'there is a '
;     JSR PUTS

;     LDX ,U                  ; print door description
;     JSR PUTS

;     LDA #'.'
;     JSR PUTC
    
; CHECK_DOORS02:
;     LEAY DOOR_SIZE, Y       ; get next door ptr
;     BRA CHECK_DOORS01

CHECK_DOORS_DONE:
    PULS A, B, X, Y, U, PC

;----------------------------
; Execute room rules
;
; Input: none
; Return: none
;----------------------------
CHECK_RULES:
    PSHS X, Y

    LDY #RULES              ; get rules table ptr

CHECK_RULES01:
    LDX ,Y                  ; get rule pred ptr
    CMPX #NULL              ; is it NULL?
    BEQ CHECK_RULES_DONE    ; if so done

    JSR [,Y]                ; call predicate, if THIS
    BNE CHECK_RULES02       ; if false do next rule

    JSR [RULE_ACTIOM_OFFSET,Y]  ; then do the ACTION

CHECK_RULES02:
    LEAY RULE_SIZE,Y        ; get next rule ptr
    BRA CHECK_RULES01

CHECK_RULES_DONE:
    PULS X, Y, PC

;----------------------------
; check for room items
;
; Input: none
; Return: none
;----------------------------
CHECK_ITEMS:
    PSHS A, X, Y, U
    LDY #ITEMS          ; get items table ptr

CHECK_ITEMS01:
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

CHECK_ITEMS02:
    LEAY ITEM_SIZE, Y   ; point to next item
    BRA CHECK_ITEMS01   ; do next item

CHECK_ITEMS_DONE:
    PULS A, X, Y, U, PC

;-------------------------------
; Get door ptr for room
;
; Input: none
; Return: door ptr in X or NULL
;-------------------------------
GET_ROOM_DOOR_PTR:
    PSHS B, Y

    JSR GET_ROOM_PTR            ; get room ptr in X
    
    LEAY DOOR_ROOM_OFFSET, X    ; get NSEW rooms ptr 
    CLRB                        ; clear offset

GET_ROOM01:
    CMPB #6
    BGT GET_ROOM_DONE
    
    LDX B, Y            ; get room for dir
    CMPX #-1            ; invalid?
    BEQ GET_ROOM02      ; if so get next room dir

    CMPX #255           ; is open passage?
    BLS GET_ROOM02      ; if so get next room dir

    ; X has door ptr
    PULS B, Y, PC

GET_ROOM02:
    ADDB #2             ; get next room dir
    BRA GET_ROOM01

GET_ROOM_DONE:
    LDX #0              ; nullptr
    PULS B, Y, PC

;----------------------------
; Open room door
;
; Input: none
; Return: none
;----------------------------
OPEN_CMD:
    PSHS A, X

    JSR GET_ROOM_DOOR_PTR       ; get room door ptr in X
    CMPX #NULL                  ; is null?
    BEQ OPEN_NO_DOOR            ; if so then done

    LDX ,X                      ; X now has door inst ptr

    LDA DINST_PROP_OFFSET, X    ; first check if door is locked
    BITA #DOOR_LOCKED
    BEQ OPEN_CMD01

    LDX #DOOR_LOCKED_MSG
    JSR PUTS
    BRA OPEN_CMD_DONE

OPEN_CMD01:
    LDA #DOOR_OPEN              ; get door open bit
    ORA DINST_PROP_OFFSET, X    ; turn on door open bit
    STA DINST_PROP_OFFSET, X    ; update door

    LDX #DOOR_OPEN_MSG          ; say we opened it
    JSR PUTS
    BRA OPEN_CMD_DONE

OPEN_NO_DOOR:
    LDX #NO_DOOR_MSG            ; say no door
    JSR PUTS

OPEN_CMD_DONE:
    PULS A, X, PC

;----------------------------
; Close room door
;----------------------------
CLOSE_CMD:
    PSHS A, X

    JSR GET_ROOM_DOOR_PTR    ; get room door ptr in X
    CMPX #NULL
    BEQ OPEN_NO_DOOR

    LDX ,X                      ; X now has door inst ptr
    LDA #~DOOR_OPEN             ; create door open mask
    ANDA DINST_PROP_OFFSET, X   ; turn off door open bit
    STA DINST_PROP_OFFSET, X    ; update door

    LDX #DOOR_CLOSED_MSG        ; say we closed it
    JSR PUTS
  
    PULS A, X, PC

;----------------------------
; Unlock room door
;----------------------------
UNLOCK_CMD:
    PSHS A, X

    JSR GET_ROOM_DOOR_PTR    ; get room door ptr in X
    CMPX #NULL
    BEQ OPEN_NO_DOOR

    LDX ,X                      ; X now has door inst ptr
    LDA DINST_PROP_OFFSET, X    ; get door props
    BITA #DOOR_LOCKABLE         ; is door lockable?
    BEQ UNLOCK_NOT_LOCKED       ; not lockable

    BITA #DOOR_LOCKED           ; is door locked?
    BEQ UNLOCK_NOT_LOCKED       ; not locked

    ; do we have the key?
    PSHS X    
    LDX DINST_ITEM_OFFSET, X    ; get ptr to item
    LDX ,X                      ; get item id
    JSR HAVE_ITEM               ; do we have it?
    PULS X
    BNE UNLOCK_NO_KEY           ; if not say so

    ANDA #~DOOR_LOCKED          ; clear locked bit
    STA DINST_PROP_OFFSET, X    ; update door props

    LDX #DOOR_UNLOCKED_MSG      ; say we unlocked it
    JSR PUTS
    BRA UNLOCK_DONE

UNLOCK_NO_KEY:
    LDX #DOOR_NO_KEY_MSG
    JSR PUTS
    BRA UNLOCK_DONE

UNLOCK_NOT_LOCKED:

    LDX #DOOR_NOT_LOCKED_MSG
    JSR PUTS

UNLOCK_DONE:
    PULS A, X, PC

;----------------------------
; Display pack items
;
; Input: none
; Return: none
;----------------------------
INVENTORY_CMD:
    PSHS A, B, X, Y

    LDY #ITEMS          ; get items table ptr
    LDX #PACK_MSG       ; print pack message
    JSR PUTS
    CLRB                ; zero item counter

INV01:
    LDX ,Y              ; get item description ptr
    CMPX #NULL          ; done?
    BEQ INV04           ; if yes...

    LDA ITEM_LOC_OFFSET, Y  ; get item loc
    CMPA #CARRYING          ; in the pack?
    BNE INV03               ; if not...

    CMPB #0                 ; is this the first item?
    BEQ INV02               ; if so...

    PSHS X                  ; save item description ptr
    LDX #PACK_GLUE_MSG      ; get message ptr
    JSR PUTS                ; print it
    PULS X                  ; restore item description ptr

INV02:
    LDA #'A'
    JSR PUTC
    LDA #SPACE
    JSR PUTC
    JSR PUTS                ; print item description
    INCB                    ; inc item count

INV03:
    LEAY ITEM_SIZE, Y       ; point to next item
    BRA INV01

INV04:
    CMPB #0                 ; pack empty?
    BNE INV05               ; if not...

    LDX #NOITEMS            ; pack is empty!
    JSR PUTS
    BRA INVENTORY_DONE

INV05:
    LDX #END_MSG
    JSR PUTS

INVENTORY_DONE:
    PULS A, B, X, Y, PC

;----------------------------
; increment the move counter
;
; Input: none
; Return: none
;----------------------------
INC_MOVES:
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
SKIP_SPACES:
    PSHS A

    LDA #SPACE

SKIP_SPACES01:
    CMPA ,X
    BNE SKIP_SPACES_DONE

    LEAX 1, X
    BRA SKIP_SPACES01

SKIP_SPACES_DONE:
    PULS A, PC

;----------------------------
; Counts items being carried
;
; Input: none
; Return: item count in A
;----------------------------
COUNT_ITEMS:
    PSHS B, X, Y            ; save B, X and Y
    LDY #ITEMS              ; get items table ptr
    CLRA                    ; zero item count

COUNT_ITEMS01:
    LDX ,Y                  ; get item description ptr
    CMPX #NULL              ; is it null?
    BEQ COUNT_ITEMS_DONE    ; if so we are done

    LDB ITEM_LOC_OFFSET,Y   ; get item loc
    CMPB #CARRYING           ; being carried?
    BNE COUNT_ITEMS02       ; if not, continue

    INCA                    ; otherwise inc counter

COUNT_ITEMS02:
    LEAY ITEM_SIZE, Y       ; get next item
    BRA COUNT_ITEMS01       ; keep going

COUNT_ITEMS_DONE:
    PULS B, X, Y, PC

;---------------------------------
; Search for item
;
; Input: item first two char in X
; Return: item ptr in Y or NULL
;---------------------------------
GET_ITEM_PTR:
    PSHS D, X

    LDY #ITEMS      ; get items table ptr

GET_ITEM01:
    LDD ,Y          ; get item description ptr
    CMPD #NULL      ; end of table?
    BEQ GET_ITEM_FAILED

    CMPX [,Y]           ; item matches?
    BEQ GET_ITEM_DONE   ; if so return item ptr in Y

    LEAY ITEM_SIZE, Y   ; get next item ptr
    BRA GET_ITEM01      ; check next item

GET_ITEM_FAILED:
    LDY #NULL       ; return nullptr

GET_ITEM_DONE:
    PULS D, X, PC

;----------------------------
; Get an object
;----------------------------
GET_CMD:
    PSHS A, X, Y       ; save D and X

    JSR COUNT_ITEMS ; how many items do we have?
    CMPA ITEM_LIMIT ; compare it to our limit
    BEQ GET02      ; if so print msg and quit

    LDX #INBUF      ; get input buffer

    LDA #SPACE      ; space delimiter
    JSR STRCHR      ; look for space

    JSR SKIP_SPACES

    CMPX #NULL      ; no more words?
    BEQ GET01

    LDX ,X              ; get first two chars of word
    JSR GET_ITEM_PTR    ; find item
    CMPY #NULL          ; item found?
    BEQ GET03           ; if not, print not found

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA ROOM               ; in current room?
    BNE GET03               ; if not...

    LDA ITEM_PROP_OFFSET,Y  ; get item prop
    BITA #TAKEABLE           ; is item takeable?
    BEQ GET04               ; if not...

    LDA #CARRYING
    STA ITEM_LOC_OFFSET,Y   ; put item in pack
    LDX #PICKUP             ; print pickup msg
    JSR PUTS
    BRA GET_DONE            ; finished!

GET01:
    LDX #GETWHAT            ; print can't find item
    JSR PUTS
    BRA GET_DONE

GET02:
    LDX #PACK_FULL
    JSR PUTS
    BRA GET_DONE

GET03:
    LDX #THEREISNO
    JSR PUTS
    BRA GET_DONE

GET04:
    LDX #CANT_TAKE_MSG
    JSR PUTS

GET_DONE:
    PULS A, X, Y, PC

;----------------------------
; Drop an object
;----------------------------
DROP_CMD:
    PSHS A, X, Y       ; save D and X

    LDX #INBUF      ; get input buffer

    LDA #SPACE      ; space delimiter
    JSR STRCHR      ; look for space

    JSR SKIP_SPACES

    CMPX #NULL          ; no more words?
    BEQ DROP01

    LDX ,X              ; get first two chars of word
    JSR GET_ITEM_PTR    ; find item
    CMPY #NULL          ; item found?
    BEQ DROP02          ; if not, print not found

    LDA ITEM_LOC_OFFSET,Y   ; get item loc
    CMPA #CARRYING          ; carrying it?
    BNE DROP02              ; if not...

    LDA ITEM_PROP_OFFSET,Y  ; get item prop
    BITA #DROPPABLE         ; is item dropable?
    BEQ DROP03              ; if not...

    LDA ROOM                ; get current room num
    STA ITEM_LOC_OFFSET,Y   ; put item in pack
    LDX #DROPITEM           ; print item drop message
    JSR PUTS
    BRA DROP_DONE

DROP01:
    LDX #DROPWHAT
    JSR PUTS
    BRA DROP_DONE

DROP02:
    LDX #DONT_HAVE_MSG
    JSR PUTS
    BRA DROP_DONE

DROP03:
    LDX #CANT_DROP_MSG
    JSR PUTS

DROP_DONE:
    PULS A, X, Y, PC

;----------------------------
; Try to read an item
;----------------------------
READ_CMD:
    PSHS A, X, Y

    LDX #INBUF      ; get input buffer

    LDA #SPACE      ; space delimiter
    JSR STRCHR      ; look for spaces

    JSR SKIP_SPACES

    CMPX #NULL      ; no more words?
    BEQ READ03

    LDX ,X          ; get first two chars of word
    JSR HAVE_ITEM   ; make sure we have the item
    BNE READ02      ; if not quit

    JSR GET_ITEM_PTR    ; get item ptr in Y
    CMPY #NULL          ; if item not found (shouldn't happen)
    BEQ READ03          ; print what? message

    LDX #IT_SAYS
    JSR PUTS

    LDX ITEM_READ_OFFSET, Y     ; get read text ptr
    CMPX #NULL                  ; is it null?
    BNE READ01

    LDX #DEFAULT_READ_MSG

READ01:
    JSR PUTS
    BRA READ_DONE

READ02:
    LDX #DONT_HAVE_MSG
    JSR PUTS
    BRA READ_DONE

READ03:
    LDX #READ_WHAT_MSG
    JSR PUTS

READ_DONE:
    PULS A, X, Y, PC

;----------------------------
; Do nothing and return!
;
; Input: none
; Return: none
;----------------------------
PASS:
    RTS

;----------------------------
; always true predicate
;----------------------------
ALWAYS:
    SETZ        ; Z = 1 = true
    RTS

;----------------------------
; never true predicate
;----------------------------
NEVER:
    CLRZ        ; z = 0 = false
    RTS

;---------------------------------
; true if carrying item
;
; Input: item in X
; Return: z = 1 = true if carrying
;---------------------------------
HAVE_ITEM:
    PSHS A, Y
    LDY #ITEMS      ; get item table ptr
    PSHS X          ; save copy of X

HAVE_ITEM01:
    LDX ,Y              ; get item description ptr
    CMPX #NULL          ; is it null?
    BEQ HAVE_ITEM_FALSE ; if so we are done

    LDX [,Y]            ; get first two chars
    CMPX ,S             ; is item the small sack?
    BNE HAVE_ITEM02     ; if not continue

    LDA ITEM_LOC_OFFSET, Y  ; get item loc
    CMPA #CARRYING          ; are we carrying it?
    BEQ HAVE_ITEM_TRUE      ; if so return true

HAVE_ITEM02:
    LEAY ITEM_SIZE, Y   ; get next item
    BRA HAVE_ITEM01     ; continue

HAVE_ITEM_TRUE:
    SETZ                ; z = 1 = true
    BRA HAVE_ITEM_DONE

HAVE_ITEM_FALSE:
    CLRZ                ; z = 0 = false

HAVE_ITEM_DONE:
    PULS X              ; restore copy of X
    PULS A, Y, PC

;----------------------------
; true if has small sack
;----------------------------
HAVE_SACK:
    PSHS X

    LDX #SACK_ID        ; sack ID
    JSR HAVE_ITEM       ; do we have it?

    PULS X, PC

;----------------------------
; true if has backpack
;----------------------------
HAVE_PACK:
    PSHS X

    LDX #PACK_ID        ; pack ID
    JSR HAVE_ITEM       ; do we have it>?

    PULS X, PC

;----------------------------
; set default item limit
;----------------------------
SET_ITEMS_DEFAULT:
    PSHS A
    LDA #DEFAULT_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

;----------------------------
; set sack item limit
;----------------------------
SET_ITEMS_SACK:
    PSHS A
    LDA #SACK_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

;----------------------------
; set pack item limit
;----------------------------
SET_ITEMS_PACK:
    PSHS A
    LDA #PACK_ITEM_LIMIT
    STA ITEM_LIMIT
    PULS A, PC

;-----------------------------
; Attempt to execute a command
;
; Input: ptr to cmd buf in X
; Return: none
;-----------------------------
DO_CMD:
    PSHS X, Y

    LDX ,X         ; get cmd chars
    LDY #CMDS       ; Y points to cmd table

CMD_LOOP:
    CMPX ,Y         ; see if we found a match
    BEQ EXECCMD     ; yes, do command

    LEAY CMD_ENTRY_SIZE, Y       ; point to next command in table
    TST ,Y          ; see if we are at end of cmds
    BNE CMD_LOOP    ; if not, continue

    LDX #UNKCMD     ; show err message
    JSR PUTS

    BRA CMD_DONE    ; done with commands

EXECCMD:
    JSR [CMD_FN_OFFSET, Y]      ; point to cmd function and call it!

CMD_DONE:
    PULS X, Y, PC

;-------------------------
; Get ptr to current room
;
; Input: none
; Return: room ptr in X
;-------------------------
GET_ROOM_PTR:
    PSHS A, B, Y

    LDA ROOM        ; get current room number
    LDB #ROOM_SIZE  ; room record size in bytes
    MUL             ; compute index offset for room
    LDY #ROOMS      ; get start of room table
    LEAX D, Y       ; get record for current room
    PULS A, B, Y, PC

;---------------------------------
; Check for room transition action
;
; Input: new room in A
; Return: none
;---------------------------------
CHECK_TRANSITION:
    PSHS A, B, X, Y

    LDY #TRANSITIONS        ; get ptr to transitions table
    LDB ROOM                ; get current room

CHECK_TRANSITION01:
    LDX ,Y                      ; get action ptr
    CMPX #NULL                  ; is it nullptr?
    BEQ CHECK_TRANSITION_DONE   ; if so we are done

    CMPB TRANSITION_FROM, Y     ; see if we find a FROM that matches
    BEQ CHECK_TRANSITION03      ; if so check the TO

CHECK_TRANSITION02:

    LEAY TRANSITION_SIZE, Y     ; get next table entry
    BRA CHECK_TRANSITION01      ; do it again

    ; then look for to that matches
CHECK_TRANSITION03:
    CMPA TRANSITION_TO, Y       ; does TO match?
    BNE CHECK_TRANSITION02      ; if not go to next item

    JSR [,Y]                    ; execution action

CHECK_TRANSITION_DONE:
    PULS A, B, X, Y, PC

;---------------------------------------------
; Try to move in given dir
;
; Input: move dir in B, move message ptr in X
; Return: none
;----------------------------------------------
MOVE:
    PSHS A, X, Y

    PSHS X                  ; save X
    JSR GET_ROOM_PTR        ; get current room ptr
    TFR X, Y                ; move room ptr to Y
    PULS X                  ; restore X

    LEAY ROOM_MOVE_OFFSET,Y ; inc ptr to move tbl
    ASLB
    LDD B, Y                ; get next room

    CMPD #-1                ; is invalid?
    BEQ MOVE_ERR            ; if so show err message

    CMPD #255
    BLS MOVE_OPEN           ; no door, go ahead and move

    ; D has door ptr
    TFR D, Y                ; move door ptr to Y
    LDB 2, Y                ; get connecting room
    LDY ,Y                  ; get door instance ptr
    LDA 2, Y                ; get door props
    BITA #DOOR_OPEN         ; is door open?
    BNE MOVE_OPEN           ; if so move

    LDX #DOOR_CLOSED_MSG    ; if not print message
    JSR PUTS
    BRA MOVE_DONE           ; and return

MOVE_OPEN:
    JSR PUTS                ; print move message
    TFR B, A
    JSR CHECK_TRANSITION    ; check for any movement transition actions

    STA ROOM                ; otherwise update room
    BRA MOVE_DONE           ; and return

MOVE_ERR:
    LDX #NOMOVE             ; print move err msg
    JSR PUTS

MOVE_DONE:
    PULS A, X, Y, PC

;-------------------------
; try move to north
;-------------------------
NORTH:
    PSHS B, X
    LDB #0
    LDX #NORTH_MOVE
    JSR MOVE
    PULS B, X, PC

;-------------------------
; try move to south
;-------------------------
SOUTH:
    PSHS B, X
    LDB #1
    LDX #SOUTH_MOVE
    JSR MOVE
    PULS B, X, PC

;-------------------------
; try move to east
;-------------------------
EAST:
    PSHS B, X
    LDB #2
    LDX #EAST_MOVE
    JSR MOVE
    PULS B, X, PC

;-------------------------
; try move to west
;-------------------------
WEST:
    PSHS B, X
    LDB #3
    LDX #WEST_MOVE
    JSR MOVE
    PULS B, X, PC

;-------------------------
; Look command
;
; Input: none
; Return: none
;-------------------------
LOOK_CMD:
    PSHS X
    JSR GET_ROOM_PTR    ; get current room ptr
    LDX ,X              ; get room description
    JSR PUTS            ; print it out

    JSR CHECK_DECORATIONS   ; print any room decorations
    JSR CHECK_ITEMS         ; print any items
    JSR CHECK_DOORS         ; print any doors

    PULS X, PC

;-------------------------
; go back to start room
;-------------------------
DBG_HOME:
    PSHS A
    CLRA            ; room 0
    STA ROOM        ; set room
    PULS A, PC

;-------------------------
; print current room ptr
;-------------------------
DBG_RP:
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
MOVES:
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
DBG_ROOM:
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
HEALTH_CMD:
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
SCORE_CMD:
    PSHS A, X
    LDX #SCORE_START
    JSR PUTS

    LDA SCORE
    JSR PRINT_DEC_BYTE

    LDX #END_MSG
    JSR PUTS
    PULS A, X, PC

;------------------------------------
; player dies
;------------------------------------
; DIE_CMD
;     LDX #DEATH_MSG
;     JSR PUTS
;     JSR INIT
;     JSR WAIT
;     RTS
    
;------------------------------------
; show item count/capacity
;------------------------------------
DBG_ITEMS:
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

;---------------------------------
; goto a room
;---------------------------------
DBG_GOTO:
    RTS

;---------------------------------
; Enter dumbwaiter action
;---------------------------------
DW_ENTER_ACTION:
    PSHS X
    LDX #DW1_MSG
    JSR PUTS
    PULS X, PC

;---------------------------------
; Exit dumbwaiter action
;---------------------------------
DW_EXIT_ACTION:
    PSHS X
    LDX #DW2_MSG
    JSR PUTS
    PULS X, PC

;---------------------------------
; Elevator enter action
;---------------------------------
EL_ENTER_ACTION:
    PSHS X
    LDX #EL1_MSG
    JSR PUTS
    PULS X, PC

;---------------------------------
; Elevator exit action
;---------------------------------
EL_EXIT_ACTION:
    PSHS X
    LDX #EL2_MSG
    JSR PUTS
    PULS X, PC

;---------------------------------
;
;---------------------------------
BALCONY_ACTION:
    PSHS X

    LDX #ROPE_ID        ; rope ID
    JSR HAVE_ITEM       ; have it?
    BNE BALCONY01

    LDX #WIN_MSG
    JSR PUTS
    BRA BALCONY_DONE

BALCONY01:
    LDX #DIE_MSG
    JSR PUTS

BALCONY_DONE:
    PULS X, PC

;---------------------------------
; Fall in hole action
;---------------------------------
FALL_ACTION:
    PSHS A, X
    LDX #FALL_MSG
    JSR PUTS
    LDA HEALTH      ; get current health
    SUBA #FALL_DMG
    STA HEALTH
    PULS A, X, PC

;---------------------------
; Initialize game state
;---------------------------
INIT:
    PSHS D

    LDA #ROOM_START
    STA ROOM

    LDA #STARTING_HEALTH
    STA HEALTH
    
    CLRA
    CLRB

    STA DARK
    STD MOVE_COUNT
    STA SCORE

    PULS D, PC

;------------------------------------
; Return ptr to first carried item
;
; Input: match mask in B
; Return: ptr to item in X or NULL
;------------------------------------
FIRST_CARRIED_ITEM:
    PSHS A, B, Y
    LDY #ITEMS          ; get items table ptr

FIRST_CARRIED01:
    LDX ,Y                  ; get item desc ptr
    CMPX #NULL              ; end of table?
    BEQ FIRST_CARRIED_DONE  ; return NULL

    BITB ITEM_PROP_OFFSET, Y    ; check that prop(s) match
    BEQ FIRST_CARRIED02         ; if not, continue to next item

    LDA ITEM_LOC_OFFSET, Y  ; get room loc of item
    CMPA #CARRYING          ; carrying it?
    TFR Y, X                ; put ptr to item in X
    BEQ FIRST_CARRIED_DONE  ; yes, return 

FIRST_CARRIED02:
    LEAY ITEM_SIZE, Y       ; get next item ptr
    BRA FIRST_CARRIED01     ; check next item

FIRST_CARRIED_DONE:
    PULS A, B, Y, PC

;------------------------------------
; Check that we don't have more items
; than the current limit and drop an
; item as necessary
;------------------------------------
PACK_CHECK:
    PSHS A, B, X

PACK_CHECK01:
    JSR COUNT_ITEMS     ; count items carried
    CMPA ITEM_LIMIT     ; more than we can carry?
    BLE PACK_CHECK_DONE ; no, done

    LDB #DROPPABLE          ; find first droppable item
    JSR FIRST_CARRIED_ITEM  ; get ptr to item in X
    CMPX #NULL              ; is null?
    BEQ PACK_CHECK_DONE     ; if so done

    LDA ROOM                ; get current room
    STA ITEM_LOC_OFFSET, X  ; drop item in room
    BRA PACK_CHECK01

PACK_CHECK_DONE:
    PULS A, B, X, PC

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
    PROMPT: FCZ ">"

    ; CURSOR FCC "!/-\"

    UNKCMD: FCZ "I DON'T UNDERSTAND! TRY AGAIN?\r\r"

    WELCOME_MSG1: FCZ "\r\r\r\r  WELCOME TO mystery mansion!\r\r     INTERACTIVE FICTION BY\r  MARK AND MATTHEW SEMINATORE\r\r      COPYRIGHT (C) 2024\r      ALL RIGHTS RESERVED."

    NOMOVE: FCZ "YOU CAN'T GO THAT WAY!\r\r"
    DOOR_CLOSED_MSG: FCZ "THE DOOR IS CLOSED.\r\r"
    DOOR_OPEN_MSG: FCZ "THE DOOR IS OPEN.\r\r"
    NO_DOOR_MSG: FCZ "THERE IS NO DOOR HERE!\r\r"
    DOOR_NOT_LOCKED_MSG: FCZ "THE DOOR IS NOT LOCKED!\r\r"
    DOOR_UNLOCKED_MSG: FCZ "THE DOOR IS UNLOCKED.\r\r"
    DOOR_LOCKED_MSG: FCZ "THE DOOR IS LOCKED.\r\r"
    DOOR_NO_KEY_MSG: FCZ "YOU NEED A KEY TO UNLOCK THIS DOOR!\r\r"

    ; DIED: FCZ "YOU HAVE died! TRY AGAIN.\r\r"
    WIN_MSG: FCZ "USING THE ROPE YOU CLIMB DOWN FROM THE BALCONY. CONGRATULATIONS! YOU HAVE FOUND YOUR WAY OUT OF mystery mansion!\r\r"
    DIE_MSG: FCZ "YOU FALL TO YOUR DEATH AND MAKE QUITE A MESS!\r\r"

    NORTH_MOVE: FCZ "YOU MOVE TO THE NORTH.\r\r"
    SOUTH_MOVE: FCZ "YOU MOVE TO THE SOUTH.\r\r"
    EAST_MOVE: FCZ "YOU MOVE TO THE EAST.\r\r"
    WEST_MOVE: FCZ "YOU MOVE TO THE WEST.\r\r"

    ROOM_MSG: FCZ "ROOM "
    MOVE_MSG: FCZ "MOVES "

    START_MSG: FCZ "YOU WAKE UP. YOUR HEAD HURTS. YOU CAN'T REMEMBER...ANYTHING. FIND YOUR WAY OUT.\r\rtype LOOK to examine room\r"

    NOITEMS: FCZ "NOTHING!\r\r"

    FALL_MSG: FCZ "YOU FALL INTO THE HOLE! IT IS A LONG WAY DOWN.\r\r"
    DW1_MSG: FCZ "AS YOU ENTER THE DUMBWAITER IT STARTS TO MOVE UPWARDS RAPIDLY! EVENTUALLY IT STOPS. YOU MUST BE SEVERAL FLOORS UP.\r\r"
    DW2_MSG: FCZ "AS YOU EXIT THE DUMBWAITER THE SUPPORT ROPE BREAKS AND IT FALLS OUT OF SIGHT. YOU HEAR IT CRASH SOMEWHERE FAR BELOW.\r\r"

    EL1_MSG: FCZ "AS YOU ENTER THE ELEVATOR THE DOOR CLOSES BEHIND YOU. YOU DESCEND WHAT FEELS LIKE SEVERAL FLOORS.\r\r"
    EL2_MSG: FCZ "AS YOU EXIT THE ELEVATOR THE DOOR CLOSES WITH A LOUD CLICK BEHIND YOU. YOU CAN NO LONGER SEE THE OPENING.\r\r"

    PACK_MSG: FCZ "YOU ARE CARRYING: "
    END_MSG: FCZ ".\r\r"
    PACK_GLUE_MSG: FCZ ", "
    PACK_FULL: FCZ "YOU CAN'T CARRY ANY MORE!\r\r"

    DONT_HAVE_MSG: FCZ "YOU ARE'NT CARRYING IT!\r\r"

    READ_WHAT_MSG: FCZ "READ WHAT?\r\r"
    DEFAULT_READ_MSG: FCZ "NOTHING OF NOTE.\r\r"
    IT_SAYS: FCZ "IT SAYS..."

    ONTHE_MSG: FCZ " ON THE "
    NORTH_MSG: FCZ "NORTH WALL"
    SOUTH_MSG: FCZ "SOUTH WALL"
    EAST_MSG: FCZ "EAST WALL"
    WEST_MSG: FCZ "WEST WALL"

    WALL_MSG: FDB NORTH_MSG, SOUTH_MSG, EAST_MSG, WEST_MSG

    WHICH_IS_CLOSED: FCZ " WHICH IS CLOSED"

    ITEM_MSG1: FCZ " THERE IS A "
    ITEM_MSG2: FCZ " HERE."
    THEREISNO: FCZ "THERE IS NO SUCH ITEM HERE.\r\r"
    GETWHAT: FCZ "GET WHAT?\r\r"
    HELP_MSG: FCZ "TRY VERBS LIKE: LOOK, NORTH, PACK, GET, DROP\r"
    PICKUP: FCZ "YOU PICK UP THE ITEM.\r\r"
    CANT_TAKE_MSG: FCZ "YOU CAN'T TAKE THAT!\r\r"
    CANT_DROP_MSG: FCZ "YOU TRY BUT YOU CAN'T SEEM TO PART WITH IT!\r\r"

    CANT_EAT_MSG: FCZ "YOU CAN'T EAT THAT!\r\r"
    CANT_DRINK_MSG: FCZ "YOU CAN'T DRINK THAT!\r\r"
    DRINK_MSG: FCZ "YOU DRINK THE "
    EAT_MSG: FCZ "YOU EAT THE "

    DROPWHAT: FCZ "DROP WHAT?\r\r"
    DROPITEM: FCZ "YOU DROP THE ITEM.\r\r"

    HEALTH_START: FCZ "YOU HAVE "
    HEALTH_TAIL: FCZ " HP LEFT.\r\r"

    SCORE_START: FCZ "YOUR SCORE IS "

    BROWN_BOOK_READ: FCZ "\"MY NAME IS OZYMANDIAS, KING OF KINGS; LOOK ON MY WORKS, YE MIGHTY, AND DESPAIR!\"\r\r"
    ACME_READ: FCZ "MFGD. BY ACME, INC.\r\r"
    USE_BY_READ: FCZ "BEST BY SEPT. 1980\r\r"
    DO_NOT_DRINK_READ: FCZ "toxic, DO NOT DRINK!\r\r"
    SKULL_READ: FCZ "YORICK: A FELLOW OF INFINITE JEST.\r\r"
    WINE_READ: FCZ "CHATEAU STE. MICHELLE CHARDONNAY 1980\r\r"
    RING_READ: FCZ "ASH NAZG DURBATULUK, ASH NAZG GIMBATUL...\r\r"
    MELVILE_READ: FCZ "TO THE LAST, I WILL GRAPPLE WITH THEE...FROM HELL's HEART, I STAB AT THEE! FOR HATE'S SAKE, I SPIT MY LAST BREATH AT THEE!\r\r"
    DANTE_READ: FCZ "ABANDON ALL HOPE, YE WHO ENTER.\r\r"

    DEATH_MSG: FCZ "SADLY YOU PERISH. TRY AGAIN?  hit any key\r\r"

    ; NOMATCH FCZ "No match\r"
    ; MATCH FCZ "Match!\r"
    ; ALWAYS_MSG FCZ "ALWAYS!\r"
    ; NEVER_MSG FCZ "NEVER!\r"
    ; PASS_MSG FCZ "PASS!\r"

    ;---------------------------
    ; Room descriptions
    ;---------------------------
    HALL: FCZ "YOU ARE IN A HALLWAY."
    STAIRS: FCZ "YOU ARE ON A STAIRWAY."
    CELLAR: FCZ "YOU ARE IN A CELLAR."
    LANDING: FCZ "YOU ARE ON A LANDING."

    RD0: FCZ "YOU ARE IN A SMALL DIMLY LIT ROOM. MAYBE A CLOSET? IT SMELLS LIKE BLEACH."
    RD1: FCZ "THERE IS AN OPEN DOOR TO THE WEST."
    RD5: FCZ "THERE IS A HOLE IN THE FLOOR JUST SOUTH OF HERE."
    RD6: FCZ "YOU ARE IN A DINGY RESTROOM."
    RD8: FCZ "YOU ARE IN A COMMON ROOM. THERE ARE CHAIRS AND A SMALL TABLE. CALL BELLS LINE THE EAST WALL. TO THE EAST IS A HALLWAY. TO THE WEST STAIRS LEAD UPWARD."
    RD13: FCZ "YOU ARE IN A SMALL PARLOR. THE SERVANTS LIKELY GATHERED HERE WHEN OFF-DUTY."
    RD14: FCZ "YOU ARE AT THE BOTTOM OF A PIT. THERE IS AN OPENING TO THE SOUTH."
    RD21: FCZ "YOU ARE IN A SMALL BEDROOM. THERE ARE BEDS ALONG THE EAST AND WEST WALLS. A SMALL NIGHT STAND IS PAIRED WITH EACH BED."
    RD29: FCZ "YOU ARE AT THE TOP OF THE STAIRWAY. PASSAGES LEAD EAST, WEST AND STAIRS LEAD SOUTH."
    RD31: FCZ "YOU ARE AT AN INTERSECTION. PASSAGES LEAD NORTH, SOUTH, EAST AND WEST."
    RD34: FCZ "RUBBLE BLOCKS THE WAY NORTH."
    RD43: FCZ "YOU ARE IN A KITCHEN. THERE ARE STOVES ALONG THE SOUTH WALL. THERE IS A DUMBWAITER IN THE WEST CORNER."
    RD46: FCZ "YOU ARE IN A SMALL WORKROOM. A WOODEN BENCH IS ON THE SOUTH WALL."
    RD56: FCZ "YOU ARE IN A SMALL STOREROOM. IT SMELLS LIKE ROTTEN CHEESE."
    RD63: FCZ "YOU ARE IN A SMALL STOREROOM. LARGE WOODEN RACKS LINE THE WALLS. IT SMELLS LIKE SOUR WINE."
    RD65: FCZ "YOU ARE IN A LIBRARY. DUSTY BOOKS LINE SHELVES ON THE NORTH WALL. THE OTHER WALLS ARE DECORATED WITH THE HEADS OF EXOTIC ANIMALS."
    RD70: FCZ "YOU ARE IN A SITTING ROOM. THERE IS A FIREPLACE ON THE NORTH WALL. LEATHER CHAIRS SIT FACING THE FIREPLACE."
    RD74: FCZ "YOU ARE IN A SOLARIUM. DIFFUSE LIGHT ENTERS FROM MANY TALL WINDOWS. AN OPEN DOOR TO THE NORTH LEADS TO A BALCONY."
    RD75: FCZ "YOU ARE ON A BALCONY. YOU ARE A LONG WAY UP! FOG OBSCURES THE SURROUNDING AREA. THE AIR IS COLD AND SMELLS DAMP."
    RD76: FCZ "YOU ARE IN A DUMBWAITER."
    RD77: FCZ "YOU ARE IN A BUTLERS PANTRY. WAIST HIGH COUNTERS LINE THE NORTH AND SOUTH WALLS."
    RD79: FCZ "YOU ARE IN A LARGE ORNATE DINING ROOM. A LARGE TABLE IS SURROUNDED BY CHAIRS."
    RD80: FCZ "YOU ARE IN A HUGE BALLROOM. CHAIRS LINE THE SIDES OF THE EAST AND WEST WALLS. WHAT GRAND GATHERINGS THIS ROOM MUST HAVE SEEN."
    RD81: FCZ "YOU ARE IN A STORAGE ROOM. EMPTY SHELVES ALONG THE WALLS LIKELY ONCE HELD PRICELESS DINNERWARE."
    RD83: FCZ "YOU ARE AT THE BOTTOM OF A GRAND STAIRCASE LEADING UP TO THE EAST."
    RD84: FCZ "YOU ARE AT THE TOP OF A GRAND STAIRCASE LEADING DOWN TO THE WEST."
    RD86: FCZ "YOU ARE IN A LUXURIOUS BEDROOM. A LARGE BED IS CENTERED ON THE NORTH WALL."
    RD88: FCZ "YOU ARE IN A CHILD'S BEDROOM. A SMALL BED IS NESTLED AGAINST THE WEST WALL."
    RD94: FCZ "YOU ARE IN THE MASTER BEDROOM. A LARGE FIREPLACE IS CENTERED ON THE NORTHWALL. A LARGE FOUR-POST BED IS ON THE EAST WALL. SMALL TABLES ON EITHER SIDE. TO THE WEST BEHIND A TATTERED CURTAIN IS AN OPENING."
    RD95: FCZ "YOU ARE IN THE SERVANTS PASSAGEWAY."
    RD96: FCZ "YOU ARE IN THE SERVANTS PASSAGEWAY. TO THE NORTH IS AN OPEN ELEVATOR."
    RD97: FCZ "YOU ARE IN AN ELEVATOR."

    EXIT_ROOM: FCZ "YOU ARE ON THE GROUND OUTSIDE THE MANSION."

    ;---------------------------
    ; Decorator descriptions
    ;---------------------------

    ; doors
    DOOR_PLAIN: FCZ "DOOR"
    DOOR_GREEN: FCZ "GREEN DOOR"
    DOOR_DOUBLE: FCZ "ORNATE DOOR"
    DOOR_SILVER: FCZ "SILVER DOOR"
    DOOR_WHITE: FCZ "WHITE DOOR"
    DOOR_BLUE: FCZ "BLUE DOOR"
    DOOR_RED: FCZ "RED DOOR"

    ; visual interest
    SCONCE: FCZ "LIGHT FLICKERS IN A WALL SCONCE."
    SLIMY_STONE: FCZ "THE WALLS ARE SLIMY AND MADE OF ROUGH STONE."
    TILED: FCZ "THE FLOOR AND WALLS ARE TILED."
    DUSTY: FCZ "DUST MOTES SWIRL IN THE AIR."

    ; smells
    MUSTY: FCZ "THE AIR SMELLS MUSTY."

    ; sounds
    DRIPPING: FCZ "YOU HEAR WATER DRIPPING NEARBY."
    INSECTS: FCZ "A CRICKET CHIRPS SOFTLY."
    CLOCK_TICK: FCZ "YOU CAN HEAR A MECHANICAL CLOCK TICKING, TIK TOK."
    MICE: FCZ "YOU HEAR THE SOFT SQUEAK OF A MOUSE."
    BARK: FCZ "A DOG BARKS IN THE DISTANCE."

    ; feelings
    DAMP: FCZ "THE AIR FEELS COOL AND DAMP."
    WATCHING: FCZ "YOU FEEL LIKE SOMEONE IS WATCHING."

    ; passages
    NOSO: FCZ "PASSAGES LEAD NORTH AND SOUTH."
    EAWE: FCZ "PASSAGES LEAD EAST AND WEST."
    NOWE: FCZ "PASSAGES LEAD NORTH AND WEST."
    SOWE: FCZ "PASSAGES LEAD WEST AND SOUTH."
    NOEA: FCZ "PASSAGES LEAD NORTH AND EAST."
    SOEA: FCZ "PASSAGES LEAD SOUTH AND EAST."

    NOSOWE: FCZ "PASSAGES LEAD NORTH, SOUTH AND WEST."
    EAWESO: FCZ "PASSAGES LEAD EAST, WEST AND SOUTH."
    NOSOEA: FCZ "PASSAGES LEAD NORTH, SOUTH AND EAST."

    NORD: FCZ "A PASSAGE LEADS NORTH."
    EST: FCZ "A PASSAGE LEADS EAST."
    SUD: FCZ "A PASSAGE LEADS SOUTH."
    OEST: FCZ "A PASSAGE LEADS WEST."

    ST_EAWE: FCZ "STAIRS LEAD EAST AND WEST."
    ST_NOSO: FCZ "STAIRS LEAD NORTH AND SOUTH."
    ST_NOEA: FCZ "STAIRS LEAD NORTH AND EAST."

    ;---------------------------
    ; Object descriptions
    ;---------------------------
    RED_KEY: FCZ "RED KEY"
    BLUE_KEY: FCZ "AZURE KEY"
    GREEN_KEY: FCZ "GREEN KEY"
    GOLD_KEY: FCZ "GOLD KEY"
    PLAT_KEY: FCZ "PLATINUM KEY"
    SILVER_KEY: FCZ "SILVER KEY"
    BROWN_BOOK: FCZ "LEATHER BOOK"
    SMALL_SACK: FCZ "SACK"
    BACKPACK: FCZ "BACKPACK"
    MOP: FCZ "MOP"
    BLEACH: FCZ "BLEACH BOTTLE"
    CHEESE: FCZ "SWISS CHEESE"
    WINE: FCZ "WINE BOTTLE"
    HAMMER: FCZ "HAMMER"
    FLASHLIGHT: FCZ "FLASHLIGHT"
    BUCKET: FCZ "BUCKET"
    RING: FCZ "RING"
    ROPE: FCZ "ROPE"
    SKULL: FCZ "SKULL"
    LEAD_BAR: FCZ "LEAD BAR"
    STICK: FCZ "STICK"
    BROOM: FCZ "BROOM"
    DANTE_SIGN: FCZ "SIGN"
    MELVILLE_SIGN: FCZ "PAINTING"

;---------------------------
; Item table
; Format: description, room, read, props
;---------------------------
ITEMS:
    FDB RED_KEY     FCB 34  FDB NULL FCB NORMAL_ITEM
    FDB BLUE_KEY    FCB 13  FDB NULL FCB NORMAL_ITEM
    FDB GREEN_KEY   FCB 8   FDB NULL FCB NORMAL_ITEM
    ; FDB GOLD_KEY    FCB 14  FDB NULL FCB NORMAL_ITEM
    ; FDB PLAT_KEY FCB 0   FDB NULL FCB NORMAL_ITEM
    FDB SILVER_KEY  FCB 86  FDB NULL FCB NORMAL_ITEM
    FDB RING        FCB 70  FDB RING_READ FCB TAKEABLE
    FDB BROWN_BOOK  FCB 24  FDB BROWN_BOOK_READ FCB NORMAL_ITEM
    FDB SMALL_SACK  FCB 65  FDB NULL FCB NORMAL_ITEM
    FDB BACKPACK    FCB 88  FDB NULL FCB NORMAL_ITEM
    FDB MOP         FCB 0   FDB ACME_READ FCB NORMAL_ITEM
    FDB BLEACH      FCB 0   FDB DO_NOT_DRINK_READ FCB NORMAL_ITEM | DRINKABLE
    FDB CHEESE      FCB 56  FDB USE_BY_READ FCB NORMAL_ITEM | EATABLE
    FDB WINE        FCB 63  FDB WINE_READ FCB NORMAL_ITEM | DRINKABLE
    FDB HAMMER      FCB 46  FDB ACME_READ FCB NORMAL_ITEM
    ; FDB FLASHLIGHT FCB 0   FDB NULL FCB NORMAL_ITEM
    FDB BUCKET      FCB 0   FDB ACME_READ FCB NORMAL_ITEM
    FDB ROPE        FCB 46  FDB NULL FCB NORMAL_ITEM
    FDB SKULL       FCB 65  FDB SKULL_READ FCB NORMAL_ITEM
    FDB DANTE_SIGN  FCB 41  FDB DANTE_READ FCB 0
    FDB MELVILLE_SIGN FCB 33 FDB MELVILE_READ FCB 0  
    ; FDB LEAD_BAR FCB 0   FDB NULL FCB NORMAL_ITEM
    ; FDB STICK FCB 6   FDB NULL FCB NORMAL_ITEM
    FDB BROOM       FCB 6 FDB NULL FCB NORMAL_ITEM 

    FDB NULL    ; end of table

LOOK_STR: FCZ "LOOK"
NO_STR: FCZ "NORTH"
SO_STR: FCZ "SOUTH"
EA_STR: FCZ "EAST"
WE_STR: FCZ "WEST"

;---------------------------
; format: str ptr, token
;---------------------------
CMD_TABLE:
    FDB LOOK_STR FCB 1
    FDB NO_STR FCB 2
    FDB SO_STR FCB 3
    FDB EA_STR FCB 4
    FDB WE_STR FCB 3
    FDB NULL        ; end of table

; format: token, action
JMP_TABLE:
    FDB PASS
    FDB NORTH
    FDB SOUTH
    FDB EAST
    FDB WEST
    FDB NULL        ; end of table

;---------------------------
; Command jump table
; Format: char, function
;---------------------------
CMDS:
    FCC "LO" FDB PASS           ; look around
    FCC "NO" FDB NORTH          ; move dirs
    FCC "SO" FDB SOUTH          
    FCC "EA" FDB EAST
    FCC "WE" FDB WEST
    FCC "QU" FDB RESET          ; quit game
    FCC "IN" FDB INVENTORY_CMD  ; display inventory
    FCC "PA" FDB INVENTORY_CMD  ; display inventory
    FCC "OP" FDB OPEN_CMD       ; open door
    FCC "DR" FDB DROP_CMD       ; drop an object
    FCC "GE" FDB GET_CMD        ; get an objectø
    FCC "TA" FDB GET_CMD        ; take an object
    FCC "MO" FDB MOVES          ; display move count
    FCC "??" FDB PASS           ; help command
    FCC "CL" FDB CLOSE_CMD      ; close door
    FCC "HE" FDB HEALTH_CMD     ; display health
    FCC "SC" FDB SCORE_CMD      ; display score
    FCC "US" FDB PASS           ; use an object
    FCC "PU" FDB PASS           ; place an object
    FCC "RE" FDB READ_CMD       ; read a message
    FCC "EX" FDB READ_CMD
    FCC "UN" FDB UNLOCK_CMD     ; unlock room door
    ; FCC "DI" FDB DIE_CMD        ; player dies

    ; debug commands
    ; FCC "GO" FDB DBG_GOTO
    FCC "RO" FDB DBG_ROOM
    FCC "HO" FDB DBG_HOME
    FCC "RP" FDB DBG_RP
    FCC "IT" FDB DBG_ITEMS
    FDB NULL    ; end of table

;---------------------------
; Decorations table
; Format: descriptor, room
;---------------------------
DECORATIONS:
    FDB DRIPPING FCB 0
    FDB NOSO FCB 1
    FDB NOSO FCB 2 FDB SCONCE FCB 2
    FDB NOSO FCB 3 FDB SCONCE FCB 3
    FDB NOSO FCB 4
    FDB NOSO FCB 5 FDB MUSTY FCB 5 FDB RD5 FCB 5
    FDB TILED FCB 6
    FDB NOSO FCB 7 FDB SCONCE FCB 7
    FDB DUSTY FCB 8
    FDB EAWE FCB 9
    FDB SOWE FCB 10 FDB SCONCE FCB 10
    FDB NOSO FCB 11
    FDB NOSO FCB 12 FDB SCONCE FCB 12
    FDB NOEA FCB 13
    FDB SLIMY_STONE FCB 14
    FDB SLIMY_STONE FCB 15 FDB NOWE FCB 15
    FDB ST_EAWE FCB 16
    FDB EAWE FCB 17
    FDB NOSOWE FCB 18
    FDB NOSO FCB 19 FDB SCONCE FCB 19
    FDB SUD FCB 20
    FDB DUSTY FCB 21
    FDB NOSO FCB 22 FDB SCONCE FCB 22
    FDB NORD FCB 23 FDB MUSTY FCB 23
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
    FDB EST FCB 43
    FDB NOSO FCB 44
    FDB NOSO FCB 45
    FDB NOSO FCB 47
    FDB NOEA FCB 48
    FDB EAWE FCB 49
    FDB RD31 FCB 50
    FDB NOSO FCB 51
    FDB NOSO FCB 52
    FDB NOWE FCB 53
    FDB SOEA FCB 54
    FDB NOSO FCB 55 FDB MICE FCB 55
    FDB NORD FCB 56
    FDB EAWE FCB 57
    FDB SOWE FCB 58
    FDB NOSO FCB 59
    FDB NOEA FCB 60
    FDB SOWE FCB 61
    FDB NOSO FCB 62 FDB INSECTS FCB 62
    FDB NORD FCB 63
    FDB EAWE FCB 64
    FDB EAWE FCB 65
    FDB EAWE FCB 66
    FDB NOWE FCB 67
    FDB NOSO FCB 68
    FDB NOSO FCB 69
    FDB SUD FCB 70
    FDB EAWE FCB 71
    FDB NOEA FCB 72
    FDB NOSO FCB 73
    FDB NOSO FCB 74
    FDB SUD FCB 75 FDB BARK FCB 75
    FDB EST FCB 76
    FDB EST FCB 77
    FDB EAWE FCB 78
    FDB NOWE FCB 79
    FDB EST FCB 80
    FDB MICE FCB 81
    FDB NOSO FCB 82
    FDB NORD FCB 83
    FDB SUD FCB 84
    FDB NOSO FCB 85
    ; FDB OEST FCB 86
    FDB NORD FCB 87
    ; FDB OEST FCB 88
    FDB SUD FCB 89
    FDB NORD FCB 90
    FDB NOSO FCB 91
    ; FDB OEST FCB 92
    FDB SUD FCB 93
    ; FDB SUD FCB 94
    FDB NOEA FCB 95
    FDB NOSO FCB 96
    FDB SUD FCB 97

    FDB NULL    ; end of table

;----------------------------------
; Door instances
; States: desc, props
;----------------------------------
DINST1: FDB DOOR_PLAIN  FCB 0 FDB 0
DINST2: FDB DOOR_GREEN  FCB DOOR_LOCKABLE | DOOR_LOCKED FDB GREEN_KEY
DINST3: FDB DOOR_RED    FCB DOOR_LOCKABLE | DOOR_LOCKED FDB RED_KEY
DINST4: FDB DOOR_BLUE   FCB DOOR_LOCKABLE | DOOR_LOCKED FDB BLUE_KEY
DINST5: FDB DOOR_SILVER FCB DOOR_LOCKABLE | DOOR_LOCKED FDB SILVER_KEY
DINST6: FDB DOOR_PLAIN  FCB 0 FDB 0
DINST7: FDB DOOR_PLAIN  FCB 0 FDB 0
DINST8: FDB DOOR_PLAIN  FCB 0 FDB 0
DINST9: FDB DOOR_PLAIN  FCB 0 FDB 0
DINST10: FDB DOOR_DOUBLE FCB 0 FDB 0

;-----------------------------------
; Room Doors
; Props: ptr to door inst, room
;-----------------------------------
DOOR1:  FDB DINST1 FCB 1
DOOR2:  FDB DINST1 FCB 0
DOOR3:  FDB DINST2 FCB 6
DOOR4:  FDB DINST2 FCB 4
DOOR5:  FDB DINST3 FCB 21
DOOR6:  FDB DINST3 FCB 20
DOOR7:  FDB DINST4 FCB 24
DOOR8:  FDB DINST4 FCB 23
DOOR9:  FDB DINST5 FCB 74
DOOR10: FDB DINST5 FCB 73
DOOR11: FDB DINST6 FCB 81
DOOR12: FDB DINST6 FCB 80
DOOR13: FDB DINST7 FCB 86
DOOR14: FDB DINST7 FCB 85
DOOR15: FDB DINST8 FCB 88
DOOR16: FDB DINST8 FCB 87
DOOR17: FDB DINST9 FCB 92
DOOR18: FDB DINST9 FCB 91
DOOR19: FDB DINST10 FCB 94
DOOR20: FDB DINST10 FCB 93

;---------------------------
; Room table
; Format: roomdesc,N,S,E,W
;---------------------------
ROOMS:
    ; room 0
    FDB RD0
    FDB -1, -1, DOOR1, -1

    ; room 1
    FDB HALL
    FDB 2, 3, -1, DOOR2

    ; room 2
    FDB HALL
    FDB 4, 1, -1, -1

    ; room 3
    FDB HALL
    FDB 1, 5, -1, -1

    ; room 4
    FDB HALL
    FDB 7, 2, DOOR3, -1

    ; room 5
    FDB HALL
    FDB 3, 14, -1, -1

    ; room 6
    FDB RD6
    FDB -1, -1, -1, DOOR4

    ; room 7
    FDB HALL
    FDB 8, 4, -1, -1

    ; room 8
    FDB RD8
    FDB -1, 7, 9, 16

    ; room 9
    FDB HALL
    FDB -1, -1, 10, 8

    ; room 10
    FDB HALL
    FDB -1, 11, -1, 9

    ; room 11
    FDB HALL
    FDB 10, 12, -1, -1

    ; room 12
    FDB HALL
    FDB 11, 13, -1, -1

    ; room 13
    FDB RD13
    FDB 12, -1, 17, -1

    ; room 14
    FDB RD14
    FDB -1, 15, -1, -1

    ; room 15
    FDB CELLAR
    FDB 14, -1, -1, 30

    ; room 16
    FDB STAIRS
    FDB -1, -1, 8, 25

    ; room 17
    FDB HALL
    FDB -1, -1, 18, 13

    ; room 18
    FDB HALL
    FDB 19, 22, -1, 17

    ; room 19
    FDB HALL
    FDB 20, 18, -1, -1

    ; room 20
    FDB HALL
    FDB DOOR5, 19, -1, -1

    ; room 21
    FDB RD21
    FDB -1, DOOR6, -1, -1

    ; room 22
    FDB HALL
    FDB 18, 23, -1, -1

    ; room 23
    FDB HALL
    FDB 22, DOOR7, -1, -1

    ; room 24
    FDB RD21
    FDB DOOR8, -1, -1, -1

    ; room 25
    FDB LANDING
    FDB 26, -1, 16, -1

    ; room 26
    FDB STAIRS
    FDB 27, 25, -1, -1

    ; room 27
    FDB STAIRS
    FDB 28, 26, -1, -1

    ; room 28
    FDB STAIRS
    FDB 29, 27, -1, -1

    ; room 29
    FDB RD29
    FDB -1, 28, 64, 71

    ; room 30
    FDB CELLAR
    FDB -1, -1, 15, 31

    ; room 31
    FDB CELLAR
    FDB 32, 51, 30, 35

    ; room 32
    FDB CELLAR
    FDB 33, 31, -1, -1

    ; room 33
    FDB CELLAR
    FDB -1, 32, -1, 34

    ; room 34
    FDB CELLAR
    FDB -1, -1, 33, -1

    ; room 35
    FDB CELLAR
    FDB -1, -1, 31, 36

    ; room 36
    FDB CELLAR
    FDB -1, 47, 35, 37
    
    ; room 37
    FDB CELLAR
    FDB -1, -1, 36, 38

    ; room 38
    FDB CELLAR
    FDB 39, 44, 37, 42

    ; room 39
    FDB CELLAR
    FDB 40, 38, -1, -1

    ; room 40
    FDB CELLAR
    FDB -1, 39, 41, -1

    ; room 41
    FDB CELLAR
    FDB -1, -1, -1, 40

    ; room 42
    FDB CELLAR
    FDB -1, -1, 38, 43

    ; room 43
    FDB RD43
    FDB -1, -1, 42, 76

    ; room 44
    FDB CELLAR
    FDB 38, 45, -1, -1

    ; room 45
    FDB CELLAR
    FDB 44, 46, -1, -1

    ; room 46
    FDB RD46
    FDB 45, -1, -1, -1

    ; room 47
    FDB CELLAR
    FDB 36, 48, -1, -1

    ; room 48
    FDB CELLAR
    FDB 47, -1, 49, -1

    ; room 49
    FDB CELLAR
    FDB -1, -1, 50, 48

    ; room 50
    FDB CELLAR
    FDB 51, 52, 57, 49

    ; room 51
    FDB CELLAR
    FDB 31, 50, -1, -1

    ; room 52
    FDB CELLAR
    FDB 50, 53, -1, -1

    ; room 53
    FDB CELLAR
    FDB 52, -1, -1, 54

    ; room 54
    FDB CELLAR
    FDB -1, 55, 53, -1

    ; room 55
    FDB CELLAR
    FDB 54, 56, -1, -1

    ; room 56
    FDB RD56
    FDB 55, -1, -1, -1

    ; room 57
    FDB CELLAR
    FDB -1, -1, 58, 50

    ; room 58
    FDB CELLAR
    FDB -1, 59, -1, 57

    ; room 59
    FDB CELLAR
    FDB 58, 60, -1, -1

    ; room 60
    FDB CELLAR
    FDB 59, -1, 61, -1

    ; room 61
    FDB CELLAR
    FDB -1, 62, -1, 60

    ; room 62
    FDB CELLAR
    FDB 61, 63, -1, -1

    ; room 63
    FDB RD63
    FDB 62, -1, -1, -1

    ; room 64
    FDB HALL
    FDB -1, -1, 65, 29

    ; room 65
    FDB RD65
    FDB -1, -1, 66, 64

    ; room 66
    FDB HALL
    FDB -1, -1, 67, 65

    ; room 67
    FDB HALL
    FDB 68,-1,-1,66

    ; room 68
    FDB HALL
    FDB 69,67,-1,-1

    ; room 69
    FDB HALL
    FDB 70,68,-1,-1

    ; room 70
    FDB RD70
    FDB -1,69,-1,-1

    ; room 71
    FDB HALL
    FDB -1,-1,29,72

    ; room 72
    FDB HALL
    FDB 73,-1, 71,-1

    ; room 73
    FDB HALL
    FDB DOOR9, 72, -1, -1

    ; room 74
    FDB RD74
    FDB 75, DOOR10, -1,-1

    ; room 75
    FDB RD75
    FDB 98, 74, -1,-1

    ; room 76
    FDB RD76
    FDB -1, -1, 77, -1

    ; room 77
    FDB RD77
    FDB -1, -1, 78, -1

    ; room 78
    FDB HALL
    FDB -1, -1, 79, 77

    ; room 79
    FDB RD79
    FDB 80, -1, -1, 78

    ; room 80
    FDB RD80
    FDB DOOR11, 79, 82, -1

    ; room 81
    FDB RD81
    FDB -1, DOOR12, -1, -1

    ; room 82
    FDB HALL
    FDB 89, 83, -1, -1

    ; room 83
    FDB RD83
    FDB 82, -1, 84, -1

    ; room 84
    FDB RD84
    FDB -1, 85, -1, 83

    ; room 85
    FDB HALL
    FDB 84, 87, DOOR13, -1

    ; room 86
    FDB RD86
    FDB -1, -1, -1, DOOR14

    ; room 87
    FDB HALL
    FDB 85, -1, DOOR15, -1

    ; room 88
    FDB RD88
    FDB -1, -1, -1, DOOR16

    ; room 89
    FDB RD83
    FDB -1, 82, 90, -1

    ; room 90
    FDB RD84
    FDB 91, -1, -1, 89

    ; room 91
    FDB HALL
    FDB 93, 90, DOOR17, -1

    ; room 92
    FDB RD86
    FDB -1, -1, -1, DOOR18

    ; room 93
    FDB HALL
    FDB DOOR19, 91, -1, -1

    ; room 94
    FDB RD94
    FDB -1, DOOR20, -1, 95

    ; room 95
    FDB RD95
    FDB 96, -1, 94, -1

    ; room 96
    FDB RD96
    FDB 97, 95, -1, -1

    ; room 97
    FDB RD97
    FDB -1, 8, -1, -1

    ; room 98
    FDB EXIT_ROOM
    FDB -1, -1, -1, -1

;---------------------------------
; transition table
; Format: action, from, to
;---------------------------------
TRANSITIONS:
    FDB DW_ENTER_ACTION FCB 43, 76
    FDB FALL_ACTION     FCB 5, 14
    FDB DW_EXIT_ACTION  FCB 76, 77
    FDB EL_ENTER_ACTION FCB 96, 97
    FDB EL_EXIT_ACTION  FCB 97, 8
    FDB BALCONY_ACTION  FCB 75, 98
    FDB NULL    ; end of table

;---------------------------
; Rules table
; format: predicate, action
;---------------------------
RULES:
    ; FDB NEVER, PASS                   ; do nothing test rule
    FDB ALWAYS,     SET_ITEMS_DEFAULT   ; set base inventory limit
    FDB HAVE_SACK,  SET_ITEMS_SACK      ; sack gives more items
    FDB HAVE_PACK,  SET_ITEMS_PACK      ; backpack gives even more
    FDB ALWAYS,     PACK_CHECK          ; ensure we respect carry limits
    ; FDB HAVE_ROPE,  UNLOCK_EXIT
    FDB NULL                            ; end of table

;---------------------------
; Vars and structures
;---------------------------
    ITEM_LIMIT: FCB 0    ; limit of items carried, modified by rules
    ROOM: FCB 0          ; current room number
    MOVE_COUNT: FDB 0    ; total number of moves
    DARK: FCB 0          ; true if dark

    CMD_BUF: RMB 10      ; tokenized command buffer
    
    ; player stats
    HEALTH: FCB STARTING_HEALTH      ; current HP
    ; ATTACK FCB 0                  ; attack damage
    ; DEFENSE FCB 0                 ; defence rating

    SCORE: FDB 0                     ; score achieved

    END START
