*-----------------------------------------------------------
* Title      : easy68K Decompiler; Hardware Buddies
* Written by : Jeff Graham, David Lambert, Paul Pierot
* Date       : 2/20/2014
* Description: A program to decompile machine code into assembly language
*-----------------------------------------------------------
CR      EQU     $0D
LF      EQU     $0A
DECOM_S EQU     $1000       ;Defining the starting address of the Decompiler
DECOM_E EQU     $2000       ;Defining the ending address of the Decompiler

START   ORG     $1000

*---Starts the Loop---
BEGIN   LEA     HEADER,A1   ;Displays the Header
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        
*---Input---
LOOP    MOVE.B  #4,D0       ;Reads in Input
        TRAP    #15         ;+
        CMP.B   #1,D1       ;Compares Input to 1
        BEQ     RANGE       ;Branch to Decompiler code if Input = 1
        
        CMP.B   #0,D1       ;Compares Input to 0
        BEQ     EXIT        ;Branch to Exit if Input = 0
        
        CMP.B   #1,D1       ;Compares Input to 1
        BGT     INVALID     ;Branch to Invalid if Input > 1
        
*-----------------------------------------------------------
* Subroutine 	: RANGE
* Written by 	: Paul Pierot
* Last Modified : 3/6/2014
* Description	: Gets the range of memory addresses to run
*                   on, and checks to make sure they are not
*                   inside the decompiler program
* Purpose       : To avoid invalid input of memory addresses
* Inputs		: N/A
* Outputs		: A3 will contain the starting memory
*                   address as a word
*                 A4 will contain the ending memory
*                   address as a word
*-----------------------------------------------------------
RANGE   LEA     RANGE_S,A1  ;Requests the starting address
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        JSR     GETHEX      ;Gets the user's input and converts it into a hexadecimal address
        CMP.W   #DECOM_E,D3 ;If the Address is less than the ending address of the decompiler, throw an error
        BLE     INVALID     ;+
        MOVEA.W D3,A3       ;Moves the starting address into A3
        
        LEA     RANGE_E,A1  ;Requests the ending address
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        JSR     GETHEX      ;Gets the user's input and converts it into a hexadecimal address
        CMP.W   #DECOM_E,D3 ;If the Address is less than the ending address of the decompiler, throw an error
        BLE     INVALID     ;+
        MOVEA.W D3,A4       ;Moves the ending address into A4
        
        MOVE.L  #0,D3       ;Cleans out D3 & D4
        MOVE.L  #0,D4       ;+
        MOVE.W  A3,D3       ;Move the starting address into D3
        MOVE.W  A4,D4       ;Move the ending address into D4
        CMP.W   D4,D3       ;If the ending address is less than the starting address, throw an error
        BGT     INVALID     ;+
        
        BRA     CLEAR       ;Start decompiling
        
*-----------------------------------------------------------
* Subroutine 	: GETHEX
* Written by 	: Paul Pierot
* Last Modified : 2/28/2014
* Description	: Reads in the users input as a hexadecimal.
*                   Can only read in 4 hexadecimals
* Purpose       : To convert the users input into hexadecimal
* Inputs		: N/A
* Outputs		: D3 will contain the hexadecimal input
*-----------------------------------------------------------
GETHEX  LEA     INPUT,A1    ;Loads the INPUT variable into A1
        CLR     D2          ;D2 holds the number of hexadecimals read
READHEX MOVE    #5,D0       ;Start a loop to read single characters
        TRAP    #15         ;+
        CMP.B   #13,D1      ;If the user presses Enter, exit the loop
        BEQ     HEXFIN      ;Jump to convertion into Hexadecimal
        BRA     HEX_BIN     ;Convert the character into binary
        BRA     READHEX     ;Starts the next loop

HEX_BIN CMP.B   #71,D1      ;If the character is G or higher, throw an error
        BGE     INVAL_C     ;+
        CMP.B   #47,D1      ;If the character is / or lower, throw an error
        BLE     INVAL_C     ;+
        CMP.B   #57,D1      ;Determines if the character is 0~9 or A~F
        BLE     ISNUMB      ;+
        SUB.B   #55,D1      ;Character is A~F, and A is decimal 65, so subtract 55 to get the decimal value
        CMP.B   #64,D1      ;If the character is not a letter, throw an error
        BGE     INVAL_C     ;+
        BRA     STORE       ;Jumps to storing the character
ISNUMB  SUB.B   #48,D1      ;Character is 0~9, and 0 is decimal 48, so subtract 48 to get the decimal value
STORE   MOVE.B  D1,(A1)+    ;Stores the converted value into INPUT
        ADD     #1,D2       ;Increments to count the number of characters
        BRA     READHEX     ;Jump back to the READHEX loop
        
HEXFIN  CLR     D3          ;D3 holds the final value
        MOVE.L  #16,D4      ;D4 is used to multiply by a power of 16
        MOVE.B  -(A1),D3    ;Get the least significant byte
GETNEXT SUB.B   #1,D2       ;Decrement the counter in D2 as we read in the next value
        TST.B   D2          ;If there's no more values to read, finish the subroutine
        BEQ     HEXDONE     ;+
        MOVE.B  -(A1),D5    ;Gets the next hexadecimal
        MULU    D4,D5       ;Multiplies the hexadecimal by a power of 16 to get the position
        ADD.L   D5,D3       ;Adds the hexadecimal to the total
        MULU    #16,D4      ;Increase the power
        BRA     GETNEXT     ;Loop back to GETNEXT
        
HEXDONE MOVE.L  #0,D4       ;Clean out D4 & D5
        MOVE.L  #0,D5       ;+
        RTS                 ;Return to the routine that called GETHEX

*-----------------------------------------------------------
* Subroutine 	: INVALID
* Written by 	: Paul Pierot
* Last Modified : 2/19/2014
* Description	: Displays a generic warning to the user
* Purpose       : To alert the user of invalid input
* Inputs		: N/A
* Outputs		: N/A
*-----------------------------------------------------------       
INVALID LEA     INV_I,A1    ;Displays a warning message
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BRA     CLEAR       ;Branch to CLEAR

*-----------------------------------------------------------
* Subroutine 	: INVAL_C
* Written by 	: Paul Pierot
* Last Modified : 2/28/2014
* Description	: Displays a warning to the user
* Purpose       : To alert the user of an invalid character
* Inputs		: N/A
* Outputs		: N/A
*-----------------------------------------------------------         
INVAL_C LEA     INV_C,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     CLEAR
        
*-----------------------------------------------------------
* Subroutine 	: CLEAR
* Written by 	: Paul Pierot
* Last Modified : 2/12/2014
* Description	: Clears the screen and jumps back to the 
*                   beginning of the program
* Purpose       : To easily allow the program to restart
* Inputs		: N/A
* Outputs		: N/A
*-----------------------------------------------------------   
CLEAR   LEA     CONT,A1     ;Display a continue message
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        MOVE.B  #4,D0       ;Reads in an input, not used
        TRAP    #15         ;+
        
        MOVE.B  #11,D0      ;Clears the screen
        MOVE.W  #$FF00,D1   ;+
        TRAP    #15         ;+
        BRA     BEGIN       ;Branches back to the Header

*---Halt the Simulation---        
EXIT    MOVE.B  #9,D0
        TRAP    #15

HEADER  DC.B    '+----------------------------------------------------------+',CR,LF
        DC.B    '| +------------------------------------------------------+ |',CR,LF
        DC.B    '| |                        __    ___  _  __              | |',CR,LF
        DC.B    '| |   ___  __ _ ___ _   _ / /_  ( _ )| |/ /              | |',CR,LF
        DC.B    '| |  / _ \/ _` / __| | | |  " \ / _ \| " /               | |',CR,LF
        DC.B    '| | |  __/ (_| \__ \ |_| | (_) | (_) | . \               | |',CR,LF
        DC.B    '| |  \___|\__,_|___/\__, |\___/ \___/|_|\_\              | |',CR,LF
        DC.B    '| |  ____           |___/                 _ _            | |',CR,LF
        DC.B    '| | |  _ \  ___  ___ ___  _ __ ___  _ __ (_) | ___ _ __  | |',CR,LF
        DC.B    '| | | | | |/ _ \/ __/ _ \| "_ ` _ \| "_ \| | |/ _ \ "__| | |',CR,LF
        DC.B    '| | | |_| |  __/ (_| (_) | | | | | | |_) | | |  __/ |    | |',CR,LF
        DC.B    '| | |____/ \___|\___\___/|_| |_| |_| .__/|_|_|\___|_|    | |',CR,LF
        DC.B    '| |                                |_|                   | |',CR,LF
        DC.B    '| +------------------------------------------------------+ |',CR,LF
        DC.B    '|   Hardware Buddies                                       |',CR,LF
        DC.B    '|              Jeff Graham, David Lambert, Paul Pierot     |',CR,LF
        DC.B    '+----------------------------------------------------------+',CR,LF,CR,LF
        DC.B    'Begin Decompiler? ("1" to continue, "0" to quit): ',CR,LF,0
RANGE_S DC.B    'Enter the starting memory address: ',CR,LF,0
RANGE_E DC.B    'Enter the ending memory address: ',CR,LF,0
INV_I   DC.B    'ERROR: Input must be valid.',CR,LF,0
INV_C   DC.B    CR,LF,'ERROR: Invalid character. Values 0~9 or A~F only.',CR,LF
        DC.B    'Make sure you are using capital letters. This program does not allow deleting.',CR,LF,0
CONT    DC.B    'Press any key to Continue',0   

INPUT   DS.B    16          ;Used for the conversion in GETHEX

        END     START










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
