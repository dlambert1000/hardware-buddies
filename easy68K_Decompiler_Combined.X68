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
        MOVE.B  #0,D3       ;The loop counter starts at 0, goes to 30
        
*---Input---
LOOP    MOVE.B  #5,D0       ;Reads in Input
        TRAP    #15         ;+
        CMP.B   #89,D1      ;Branch to Decompiler code if Input = "Y" or "y"
        BEQ     RANGE       ;+
        CMP.B   #121,D1     ;+
        BEQ     RANGE       ;+
        
        CMP.B   #78,D1      ;Branch to Exit if Input = "N" or "n"
        BEQ     EXIT        ;+
        CMP.B   #110,D1     ;+
        BEQ     EXIT        ;+
        
        BRA     INVALID     ;Input is invalid
        
*-----------------------------------------------------------
* Subroutine 	: RANGE
* Written by 	: Paul Pierot
* Last Modified : 3/11/2014
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
        BSR     GETHEX      ;Gets the user's input and converts it into a hexadecimal address
        CMP.W   #DECOM_E,D5 ;If the Address is less than the ending address of the decompiler, throw an error
        BLE     INVALID     ;+
        MOVEA.W D5,A3       ;Moves the starting address into A3
        
        LEA     RANGE_E,A1  ;Requests the ending address
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BSR     GETHEX      ;Gets the user's input and converts it into a hexadecimal address
        CMP.W   #DECOM_E,D5 ;If the Address is less than the ending address of the decompiler, throw an error
        BLE     INVALID     ;+
        MOVEA.W D5,A4       ;Moves the ending address into A4
        
        MOVE.L  #0,D5       ;Cleans out D5 & D4
        MOVE.L  #0,D4       ;+
        MOVE.W  A3,D5       ;Move the starting address into D5
        MOVE.W  A4,D4       ;Move the ending address into D4
        CMP.W   D4,D5       ;If the ending address is less than the starting address, throw an error
        BGT     INVALID     ;+
        
        LEA     VALID,A1    ;Let the user know their input was valid
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BSR     CLEAR       ;Clear the screen
        BRA     decodeOp    ;Start decompiling
        
*-----------------------------------------------------------
* Subroutine 	: GETHEX
* Written by 	: Paul Pierot
* Last Modified : 3/8/2014
* Description	: Reads in the users input as a hexadecimal.
*                   Can only read in 4 hexadecimals
* Purpose       : To convert the users input into hexadecimal
* Inputs		: N/A
* Outputs		: D5 will contain the hexadecimal input
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
        
HEXFIN  CLR     D5          ;D5 holds the final value
        MOVE.L  #16,D4      ;D4 is used to multiply by a power of 16
        MOVE.B  -(A1),D5    ;Get the least significant byte
GETNEXT SUB.B   #1,D2       ;Decrement the counter in D2 as we read in the next value
        TST.B   D2          ;If there's no more values to read, finish the subroutine
        BEQ     HEXDONE     ;+
        MOVE.B  -(A1),D6    ;Gets the next hexadecimal
        MULU    D4,D6       ;Multiplies the hexadecimal by a power of 16 to get the position
        ADD.L   D6,D5       ;Adds the hexadecimal to the total
        MULU    #16,D4      ;Increase the power
        BRA     GETNEXT     ;Loop back to GETNEXT
        
HEXDONE MOVE.L  #0,D4       ;Clean out D4 & D6
        MOVE.L  #0,D6       ;+
        RTS                 ;Return to the routine that called GETHEX
        
*-----------------------------------------------------------
* Subroutine 	: INVALID
* Written by 	: Paul Pierot
* Last Modified : 3/11/2014
* Description	: Displays a generic warning to the user
* Purpose       : To alert the user of invalid input
* Inputs		: N/A
* Outputs		: N/A
*-----------------------------------------------------------       
INVALID LEA     INV_I,A1    ;Displays a warning message
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BSR     CLEAR       ;Clear the screen
        BSR     EMPTY       ;Clean out the registers
        BRA     BEGIN       ;Branches back to the Header

*-----------------------------------------------------------
* Subroutine 	: INVAL_C
* Written by 	: Paul Pierot
* Last Modified : 3/11/2014
* Description	: Displays a warning to the user
* Purpose       : To alert the user of an invalid character
* Inputs		: N/A
* Outputs		: N/A
*-----------------------------------------------------------         
INVAL_C LEA     INV_C,A1    ;Displays a warning message
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BSR     CLEAR       ;Clear the screen
        BSR     EMPTY       ;Clean out the registers
        BRA     BEGIN       ;Branches back to the Header
        
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
        RTS


*-----------------------------------------------------------
* Subroutine     : decodeOp
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : sorts opcodes according to groups based on their first 4-bits
* Purpose        : The first step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
decodeOp
        *Initialize variables
        LEA         opBuffer,A2     *set op buffer ptr
        CLR.L       D2              *clear old opcode
        MOVE.W      (A3),D2         *store opcode in D2 for processing
        ADDA.L      #2,A3           *advance ptr

        *get first four bit value
        MOVE.B      #3,D6   *specify most significant four bits wanted
        BSR         fourBitValue    *store first four bits in D7
        
        *compare value, and branch to group SR
        CMPI.B      #0,D7
        BEQ         grpZero
        CMPI.B      #1,D7
        BEQ         grpOne
        CMPI.B      #2,D7
        BEQ         grpTwo
        CMPI.B      #3,D7
        BEQ         grpThree
        CMPI.B      #4,D7
        BEQ         grpFour
        CMPI.B      #5,D7
        BEQ         grpFive
        CMPI.B      #6,D7
        BEQ         grpSix
        CMPI.B      #7,D7
        BEQ         grpSeven
        CMPI.B      #8,D7
        BEQ         grpEight
        CMPI.B      #9,D7
        BEQ         grpNine
        CMPI.B      #10,D7
        BEQ         grpTen
        CMPI.B      #11,D7
        BEQ         grpEleven
        CMPI.B      #12,D7
        BEQ         grpTwelve
        CMPI.B      #13,D7
        BEQ         grpThirteen
        CMPI.B      #14,D7
        BEQ         grpFourteen
        CMPI.B      #15,D7
        BEQ         grpFifteen
        *every op is covered, no need for unknownOp branch
        

*First level group sorting
*-----------------------------------------------------------
* Subroutine     : grpZero
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group zero opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpZero
        MOVE.B      #2,D6       *select which 4-bit set to evaluate
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        CMPI.B      #2,D7
        BEQ         opANDI
        CMPI.B      #6,D7
        BEQ         opADDI
        CMPI.B      #8,D7
        BEQ         opBCHGStat
        CMPI.B      #10,D7
        BEQ         opEORI
        CMPI.B      #12,D7
        BEQ         opCMPI
        
        *check if odd value
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opBCHGDyn
        
        *check for unknown code
        BRA         unknownOp
        
*-----------------------------------------------------------
* Subroutine     : grpOne
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group one opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpOne
        BRA         opMOVEB

*-----------------------------------------------------------
* Subroutine     : grpTwo
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group two opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpTwo
        BRA         opMOVEL

*-----------------------------------------------------------
* Subroutine     : grpThree
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group three opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpThree
        BRA         opMOVEW

*-----------------------------------------------------------
* Subroutine     : grpFour
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group four opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpFour
        MOVE.B      #2,D6       *select which 4-bit set to evaluate
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        CMPI.B      #2,D7
        BEQ         opCLR
        CMPI.B      #8,D7
        BEQ         opMOVEMRtoM
        CMPI.B      #12,D7
        BEQ         chkMOVEMMtoRMULSL
        CMPI.B      #14,D7
        BEQ         chkJSRRTS
        
        *check if odd
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opLEA
        
        *fall through to unknown
        BRA         unknownOp

*-----------------------------------------------------------
* Subroutine     : chkMOVEMMtoRMULSL
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : Determines if the opcode is MOVEM in memory-to-Register mode
*                   or MULS.L
* Purpose        : checks ambiguous opcodes next bits to determine which code
*                   it is.
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
chkMOVEMMtoRMULSL
        MOVE.B      #1,D6       *select which 4-bit set to evaluate
        BSR         fourBitValue
        
        *if >= 8 -> MOVEMMtoR, else -> MULS.L
        CMPI.B      #8,D7       
        BGE         opMOVEMMtoR *8 <= D7 -> opMOVEMMtoR
        BRA         opMULSL

*-----------------------------------------------------------
* Subroutine     : chkJSRRTS
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : Determines if the opcode is JSR or RTS
* Purpose        : checks ambiguous opcodes next bits to determine which code
*                   it is.
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
chkJSRRTS
        MOVE.B      #1,D6       *select which 4-bit set to evaluate
        BSR         fourBitValue
        
        *if >= 8 -> JSR, else -> RTS
        CMPI.B      #8,D7       
        BGE         opJSR       *8 <= D7 -> opJSR
        BRA         opRTS       *8 >  D7 -> opRTS

        

*-----------------------------------------------------------
* Subroutine     : grpFive
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group five opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpFive
        BRA         opSUBQ

*-----------------------------------------------------------
* Subroutine     : grpSix
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group six opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpSix
        MOVE.B      #2,D6       *select which 4-bit set to evaluate
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        CMPI.B      #4,D7
        BEQ         opBCC
        CMPI.B      #9,D7
        BEQ         opBVS
        CMPI.B      #14,D7
        BEQ         opBGT
        CMPI.B      #15,D7
        BEQ         opBLE
        
        *fall through to unknown
        BRA         unknownOp

*-----------------------------------------------------------
* Subroutine     : grpSeven
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group seven opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpSeven
        BRA         opMOVEQ

*-----------------------------------------------------------
* Subroutine     : grpEight
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group eight opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpEight
        BRA         opDIVU

*-----------------------------------------------------------
* Subroutine     : grpNine
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group nine opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpNine
        MOVE.B      #1,D6       *Note: for this, we must check the third 4bit set
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if >= 12 -> SUBA, else -> SUB
        CMPI.B      #12,D7
        BGE         opSUBA
        BRA         opSUB

*-----------------------------------------------------------
* Subroutine     : grpTen
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group ten opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpTen
        BRA         unknownOp

*-----------------------------------------------------------
* Subroutine     : grpEleven
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group eleven opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpEleven
        MOVE.B      #2,D6       *check 2nd 4bit value
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if odd -> EOR, else -> either CMP or CMPA
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opEOR       *if odd
        BRA         chkCMPCMPA  *if even
        
*-----------------------------------------------------------
* Subroutine     : chkCMPCMPA
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : Determines if the opcode is CMP or CMPA
* Purpose        : checks ambiguous opcodes next bits to determine which code
*                   it is.
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
chkCMPCMPA
        MOVE.B      #1,D6       *Note: for this, we must check the third 4bit set
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if >= 12 -> CMPA, else -> CMPA
        CMPI.B      #12,D7
        BGE         opCMPA
        BRA         opCMP

*-----------------------------------------------------------
* Subroutine     : grpTwelve
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group twelve opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpTwelve
        MOVE.B      #2,D6       *check 2nd 4bit value
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if odd -> MULS.W, else -> AND
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opMULSW     *if odd
        BRA         opAND       *if even



*-----------------------------------------------------------
* Subroutine     : grpThirteen
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group thirteen opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpThirteen
        MOVE.B      #1,D6       *Note: for this, we must check the third 4bit set
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if >= 12 -> ADDA, else -> ADD
        CMPI.B      #12,D7
        BGE         opADDA
        BRA         opADD


*-----------------------------------------------------------
* Subroutine     : grpFourteen
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group fourteen opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpFourteen
        *check bit #4
        MOVE.B      #1,D6       *check 3rd 4bit value
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if odd -> ROd, else -> LSd or ASd
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opROd       *if odd
        
        *check bit #3
        MOVE.B      #0,D6       *check least significant 4bits
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if >= 8 -> LSd, else -> ASd
        CMPI.B      #8,D7
        BGE         opLSd
        BRA         opASd


*-----------------------------------------------------------
* Subroutine     : grpFifteen
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts group fifteen opcodes according to their second 4-bits
* Purpose        : The second step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
grpFifteen
        BRA         unknownOp

*
*opcode section, the following currently only print the opcodes and start
*   decoding the next word.
*

*grp zero opcodes
*-----------------------------------------------------------
* Subroutine     : opADDI
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ADDI opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opADDI
        *buffer opcode
        LEA     strADDI,A6
        BSR     toOutputBuffer

        *check size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opADDIB
        CMPI.B  #1,D4
        BEQ     opADDIW
        CMPI.B  #2,D4
        BEQ     opADDIL
        BRA     unknownOp       *size 3 is invalid
        

opADDIB
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        
        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii byte
        ADDA.L  #1,A3       *advance pointer one byte
        MOVE.B  (A3),D1     *move byte to be 
        MOVE.L  #2,D4       *number of hex digits to convert
        BSR     hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer

        ADDA.L  #1,A3       *advance pointer one more byte
        
        BRA     opADDIEnd
        
opADDIW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
                
        *get ascii word
        MOVE.W      (A3),D1
        MOVE.L      #4,D4       *# of hex digits to convert
        BSR         hexToAscii  *move word to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #2,A3       *advance pointer one word

        BRA     opADDIEnd

opADDIL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii longword
        MOVE.L  (A3),D1
        MOVE.L  #8,D4       *# of hex digits to convert
        BSR     hexToAscii  *move long to output buffer
        
        *move ascii to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        ADDA.L  #4,A3       *advance pointer one longword

        BRA     opADDIEnd

opADDIEnd
        *buffer ,
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *get destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode  
        
        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opANDI
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ANDI opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opANDI
        *buffer opcode
        LEA     strANDI,A6
        BSR     toOutputBuffer

        *check size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opANDIB
        CMPI.B  #1,D4
        BEQ     opANDIW
        CMPI.B  #2,D4
        BEQ     opANDIL
        BRA     unknownOp       *size 3 is invalid
        

opANDIB
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        
        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii byte
        ADDA.L  #1,A3       *advance pointer one byte
        MOVE.B  (A3),D1     *move byte to be 
        MOVE.L  #2,D4       *number of hex digits to convert
        BSR     hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer

        ADDA.L  #1,A3       *advance pointer one more byte
        
        BRA     opANDIEnd
        
opANDIW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
                
        *get ascii word
        MOVE.W      (A3),D1
        MOVE.L      #4,D4       *# of hex digits to convert
        BSR         hexToAscii  *move word to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #2,A3       *advance pointer one word

        BRA     opANDIEnd

opANDIL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii longword
        MOVE.L  (A3),D1
        MOVE.L  #8,D4       *# of hex digits to convert
        BSR     hexToAscii  *move long to output buffer
        
        *move ascii to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        ADDA.L  #4,A3       *advance pointer one longword

        BRA     opANDIEnd

opANDIEnd
        *buffer ,
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *get destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode  
        
        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opEORI
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the EORI opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opEORI
        *Print opcode
        LEA     strEORI,A6
        BSR     toOutputBuffer

        *check size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opEORIB
        CMPI.B  #1,D4
        BEQ     opEORIW
        CMPI.B  #2,D4
        BEQ     opEORIL
        BRA     unknownOp       *size 3 is invalid
        

opEORIB
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        
        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii byte
        ADDA.L  #1,A3       *advance pointer one byte
        MOVE.B  (A3),D1     *move byte to be 
        MOVE.L  #2,D4       *number of hex digits to convert
        BSR     hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer

        ADDA.L  #1,A3       *advance pointer one more byte
        
        BRA     opEORIEnd
        
opEORIW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
                
        *get ascii word
        MOVE.W      (A3),D1
        MOVE.L      #4,D4       *# of hex digits to convert
        BSR         hexToAscii  *move word to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #2,A3       *advance pointer one word

        BRA     opEORIEnd

opEORIL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii longword
        MOVE.L  (A3),D1
        MOVE.L  #8,D4       *# of hex digits to convert
        BSR     hexToAscii  *move long to output buffer
        
        *move ascii to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        ADDA.L  #4,A3       *advance pointer one longword

        BRA     opEORIEnd

opEORIEnd
        *buffer ,
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *get destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode  
        
        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opBCHGStat
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BCHG opcode with a static source operand
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBCHGStat
        *buffer opcode
        LEA     strBCHG,A6
        BSR     toOutputBuffer

        *buffer #
        MOVE.B  #35,(A2)+
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *buffer source data
        *get ascii byte
        ADDA.L  #1,A3       *advance pointer one byte
        MOVE.B  (A3),D1     *move byte to be 
        MOVE.L  #2,D4       *number of hex digits to convert
        BSR     hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer

        ADDA.L  #1,A3       *advance pointer one more byte
        
        *buffer ,
        MOVE.B  #44,(A2)+
        
        *decode destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode

        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opBCHGDyn
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BCHG opcode with a Dynamic source operand
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBCHGDyn
        *buffer opcode
        LEA     strBCHG,A6
        BSR     toOutputBuffer

        *buffer source data
        *buffer D
        MOVE.B  #68,(A2)+
        
        *buffer register #
        MOVE.B  #9,D6
        BSR     threeBitValue
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+
                
        *buffer ,
        MOVE.B  #44,(A2)+
        
        *decode destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode

        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp

        
*-----------------------------------------------------------
* Subroutine     : opCMPI
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the CMPI opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opCMPI
        *Print opcode
        LEA     strCMPI,A6
        BSR     toOutputBuffer

        *check size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opCMPIB
        CMPI.B  #1,D4
        BEQ     opCMPIW
        CMPI.B  #2,D4
        BEQ     opCMPIL
        BRA     unknownOp       *size 3 is invalid
        

opCMPIB
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        
        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii byte
        ADDA.L  #1,A3       *advance pointer one byte
        MOVE.B  (A3),D1     *move byte to be 
        MOVE.L  #2,D4       *number of hex digits to convert
        BSR     hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer

        ADDA.L  #1,A3       *advance pointer one more byte
        
        BRA     opCMPIEnd
        
opCMPIW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
                
        *get ascii word
        MOVE.W      (A3),D1
        MOVE.L      #4,D4       *# of hex digits to convert
        BSR         hexToAscii  *move word to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #2,A3       *advance pointer one word

        BRA     opCMPIEnd

opCMPIL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer

        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        
        *get ascii longword
        MOVE.L  (A3),D1
        MOVE.L  #8,D4       *# of hex digits to convert
        BSR     hexToAscii  *move long to output buffer
        
        *move ascii to output buffer
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        ADDA.L  #4,A3       *advance pointer one longword

        BRA     opCMPIEnd

opCMPIEnd
        *buffer ,
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *get destination EA
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        *move register and mode
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode  
        
        BSR     eaDecode
        BSR     printBuffer
        
        BRA     nextOp


*group 1 opcodes
*-----------------------------------------------------------
* Subroutine     : opMOVEB
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVE opcode with a size of Byte
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEB
        *buffer opcode
        LEA     strMOVEB,A6
        BSR     toOutputBuffer


        *store operation size
        MOVE.L  #0,D4
        
        *source effective addressing
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        BSR     eaDecode    *decode EA
        
        
        *add comma to buffer
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *destination effective addressing
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        MOVE.B  #6,D6       *store mode
        MOVE.B  #9,D5       *store register
        BSR     eaDecode    *decode EA
        
        BSR     printBuffer
                
        BRA     nextOp

*group 2 opcodes
*-----------------------------------------------------------
* Subroutine     : opMOVEL
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVE opcode with a size of longword
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEL
        *buffer opcode
        LEA     strMOVEL,A6
        BSR     toOutputBuffer


        *store operation size
        MOVE.L  #2,D4
        
        *source effective addressing
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        BSR     eaDecode    *decode EA
        
        
        *add comma to buffer
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *destination effective addressing
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2

        MOVE.B  #6,D6       *store mode
        MOVE.B  #9,D5       *store register
        BSR     eaDecode    *decode EA
        
        BSR     printBuffer
                
        BRA     nextOp


*group 3 opcodes
*-----------------------------------------------------------
* Subroutine     : opMOVEW
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVE opcode with a size of word
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEW
        *buffer opcode
        LEA     strMOVEW,A6
        BSR     toOutputBuffer


        *store operation size
        MOVE.L  #1,D4
        
        *source effective addressing
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        BSR     eaDecode    *decode EA
        
        
        *add comma to buffer
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *destination effective addressing
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2

        MOVE.B  #6,D6       *store mode
        MOVE.B  #9,D5       *store register
        BSR     eaDecode    *decode EA
        
        BSR     printBuffer
                
        BRA     nextOp

        
*group 4 opcodes
*-----------------------------------------------------------
* Subroutine     : opMOVEMMtoR
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVEM opcode for memory to register moves
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEMMtoR
        *Print opcode
        LEA     strMOVEM,A6
        BSR     toOutputBuffer
        
        *Get size
        BTST    #10,D2
        BNE     opMOVEMMtoRL
        BEQ     opMOVEMMtoRW
        
opMOVEMMtoRW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer
        BRA     opMOVEMMtoREnd
opMOVEMMtoRL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer
        BRA     opMOVEMMtoREnd

opMOVEMMtoREnd
        *ea decode
        *set invalid EA mask
        BSET    #31,D2
        BSET    #30,D2
        BSET    #27,D2
        BSET    #24,D2

        MOVE.B  #3,D6       *store mode
        MOVE.B  #0,D5       *store register
        BSR     eaDecode    *decode EA

        *register list
        *An list
        MOVE.B  #65,D6      *store A
        MOVE.B  #8,D5
        BSR     opMOVEMList
        ADDA.L  #1,A3       *increment one byte
        
        *Dn list
        MOVE.B  #68,D6      *store D
        MOVE.B  #8,D5
        BSR     opMOVEMList
        ADDA.L  #1,A3       *increment one byte
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opMOVEM
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVEM opcode for register to memory moves
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEMRtoM
        *Print opcode
        LEA     strMOVEM,A1
        MOVE.W  #13,D0
        TRAP    #15
                
        BRA     nextOp
        
opMOVEMList
        *D5 = register #
        *D6 = A or D
        CMPI.B  #0,D5           *check for end of loop
        BEQ     opMOVEMListRet
        SUBQ    #1,D5
        BTST.B  D5,(A3)         *check bit
        BEQ     opMOVEMList     *loop
        *bit is set -> buffer register
        MOVE.B  D6,(A2)+    *buffer register type
        MOVE.B  D5,(A2)+    *buffer register number
        MOVE.B  #35,(A2)+   *buffer ,
        
        BRA     opMOVEMList *Loop
        
        
opMOVEMListPD
        

opMOVEMListRet
        RTS
        
*-----------------------------------------------------------
* Subroutine     : opLEA
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the LEA opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opLEA
        *buffer opcode
        LEA     strLEA,A6
        BSR     toOutputBuffer
        
        *set invalid ea mask
        BSET    #31,D2
        BSET    #30,D2
        BSET    #28,D2
        BSET    #27,D2
        BSET    #24,D2

        *source EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        BSR     eaDecode    *get source EA
        
        *add comma to buffer
        MOVE.B  #44,(A2)+     *#44 is ascii val for comma
        
        *buffer A
        MOVE.B  #65,(A2)+

        *get destination register
        MOVE.B  #9,D6
        
        *buffer register #
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+
        
        *Add null to end of string
        MOVE.B  #0,(A2)
        
        BSR     printBuffer        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opCLR
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the CLR opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opCLR
        *buffer opcode
        LEA     strCLR,A6
        BSR     toOutputBuffer
        
        *get operation size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opCLRB
        CMPI.B  #1,D4
        BEQ     opCLRW
        CMPI.B  #2,D4
        BEQ     opCLRL
        BRA     unknownOp       *size 3 is invalid
        
opCLRB
        LEA     strByte,A6
        BSR     toOutputBuffer
        BRA     opCLREnd
opCLRW
        LEA     strWord,A6
        BSR     toOutputBuffer
        BRA     opCLREnd

opCLRL
        LEA     strLong,A6
        BSR     toOutputBuffer
        BRA     opCLREnd

opCLREnd
        *decode EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        *set invalid EA mask
        BSET    #30,D2
        BSET    #24,D2
        
        BSR     eaDecode    *get source EA
        
        BSR     printBuffer        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opJSR
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the JSR opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opJSR
        *buffer opcode
        LEA     strJSR,A6
        BSR     toOutputBuffer
        
        *set invalid mode mask
        BSET    #31,D2
        BSET    #30,D2
        BSET    #28,D2
        BSET    #27,D2
        BSET    #24,D2
        
        *store mode and register bits
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode

        BSR     eaDecode    *get source EA
        
        BSR     printBuffer        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opRTS
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the RTS opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opRTS
        *verify opcode
        CMPI.W  #$4075,D2
        BNE     unknownOp
        
        *Print opcode
        LEA     strRTS,A6
        BSR     toOutputBuffer
        
        BSR     printBuffer
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opMULSL
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MULS opcode with size of longword
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMULSL
        *buffer opcode
        LEA     strMULSL,A6
        BSR     toOutputBuffer
        
        *Store extra word instruction
        MOVEA   A3,A0
        *increment word
        ADDA.L  #2,A3
        
        *source EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        *invalid ea mask
        BSET    #30,D2
        
        BSR     eaDecode    *decode EA
        
        *buffer a ,
        MOVE.B  #44,(A2)+
        
        *destination register
        *buffer D
        MOVE.B  #68,(A2)+
        
        *get register number
        BFEXTU  (A0){#17:#3},D7

        *buffer register number
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+

        *check for second register
        BTST    #10,(A0)
        BNE     opMULSLDual     *branch to dual register
        BEQ     opMULSLSingle   *branch to single register
        
opMULSLDual
        *buffer -
        MOVE.B  #45,(A2)+
        
        *buffer D
        MOVE.B  #68,(A2)+

        *get second register
        BFEXTU  (A0){#29:#3},D7

        *buffer second register number
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+
        
        
opMULSLSingle
        *add null to end of buffer
        MOVE.B  #0,(A2)
        *print buffer
        BSR     printBuffer       
        BRA     nextOp

*group 5 opcodes
*-----------------------------------------------------------
* Subroutine     : opSUBQ
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the SUBQ opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opSUBQ
        *buffer opcode
        LEA     strSUBQ,A6
        BSR     toOutputBuffer

        *get operation size
        BFEXTU  D2{#24:#2},D4   *get size bits
        CMPI.B  #0,D4
        BEQ     opSUBQB
        CMPI.B  #1,D4
        BEQ     opSUBQW
        CMPI.B  #2,D4
        BEQ     opSUBQL
        BRA     unknownOp       *size 3 is invalid

opSUBQB
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        BRA     opSUBQEnd
        
opSUBQW
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer
        BRA     opSUBQEnd

opSUBQL
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer
        BRA     opSUBQEnd

opSUBQEnd
        *get immediate data
        MOVE.B  #9,D6       *data bit offset
        BSR     threeBitValue
        
        *check if immediate == 0
        CMPI.B  #0,D7
        BNE     opSUBQImmediate
        *if immediate == 0, add 8
        ADDI.B  #8,D7
        
opSUBQImmediate        
        *buffer immediate data
        MOVE.B  #35,(A2)+   *buffer #
        ADDI.B  #48,D7      *convert # to ascii
        MOVE.B  D7,(A2)+    *buffer immediate data
        MOVE.B  #44,(A2)+   *buffer ,
        
        *check destination addressing
        *set invalid ea mask
        BSET    #24,D2
        
        *store mode and register bits
        MOVE.B  #0,D5
        MOVE.B  #3,D6
        
        BSR     eaDecode
        
        BSR     printBuffer
        
        
        BRA     nextOp
        
*group 6 opcodes
*-----------------------------------------------------------
* Subroutine     : opBCC
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BCC opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBCC
        *buffer opcode
        LEA     strBCC,A6
        BSR     toOutputBuffer
        
        *buffer $
        MOVE.B  #36,(A2)+
        
        *check lower 8 bits
        CMPI.B  #$00,D2
        BEQ     opBCCWord
        CMPI.B  #$FF,D2
        BEQ     opBCCLong
        
        *else 8 bit displacement
        *convert to ascii
        MOVE.B  D2,D1
        MOVE.B  #2,D4
        BSR     hexToAscii
        *buffer ascii
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        BRA     opBCCEnd
        
opBCCWord
        *read next word
        *convert to ascii
        MOVE.W  (A3),D1
        MOVE.B  #4,D4
        BSR     hexToAscii
        *buffer ascii
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        *advance A3 ptr
        ADDA.L  #2,A3
        
        BRA     opBCCEnd
        
        
opBCCLong
        *read next longword
        *convert to ascii
        MOVE.L  (A3),D1
        MOVE.B  #8,D4
        BSR     hexToAscii
        *buffer ascii
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        *advance A3 ptr
        ADDA.L  #4,A3
        
        BRA     opBCCEnd
        
opBCCEnd
        BSR     printBuffer
        BRA     nextOp
                
*-----------------------------------------------------------
* Subroutine     : opBGT
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BGT opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBGT
        *Print opcode
        LEA     strBGT,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opBLE
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BLE opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBLE
        *Print opcode
        LEA     strBLE,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opBVS
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the BVS opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opBVS
        *Print opcode
        LEA     strBVS,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 7 opcodes
*-----------------------------------------------------------
* Subroutine     : opMOVEQ
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MOVEQ opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMOVEQ
        *buffer opcode
        LEA     strMOVEQ,A6
        BSR     toOutputBuffer
        
        *buffer $
        MOVE.B  #36,(A2)+
        
        *convert quick data to hex
        MOVE.B  D2,D1
        MOVE.B  #2,D4
        BSR     hexToAscii
        *buffer quick data
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        *buffer ,
        MOVE.B  #44,(A2)+
        
        *buffer D
        MOVE.B  #68,(A2)+
        
        *get data register number
        MOVE.B  #9,D6
        BSR     threeBitValue
        
        *buffer data register number
        LEA     OUTPUT,A6
        BSR     toOutputBuffer
        
        BSR     printBuffer
        BRA     nextOp

*group 8 opcodes
*-----------------------------------------------------------
* Subroutine     : opDIVU
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the DIVU opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opDIVU
        *Print opcode
        LEA     strDIVU,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 9 opcodes
*-----------------------------------------------------------
* Subroutine     : opSUB
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the SUB opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opSUB
        *buffer opcode
        LEA     strSUB,A6
        BSR     toOutputBuffer
        
        *get size
        BFEXTU  D2{#24:#2},D4
        CMPI.B  #1,D4
        BLT     opSUBByte
        BEQ     opSUBWord
        *else longword or invalid
        CMPI.B  #2,D4
        BEQ     opSUBLong
        BRA     unknownOp   *if bits = 11, then invalid
        
        
opSUBByte
        *buffer .B
        LEA     strByte,A6
        BSR     toOutputBuffer
        BRA     opSUBDir
opSUBWord
        *buffer .W
        LEA     strWord,A6
        BSR     toOutputBuffer
        BRA     opSUBDir
opSUBLong
        *buffer .L
        LEA     strLong,A6
        BSR     toOutputBuffer
        BRA     opSUBDir

opSUBDir
        *check direction
        BTST    #8,D2
        BEQ     opSubEa     *ea source
        
        *else data register source
        *buffer D
        MOVE.B  #68,(A2)+
        
        *get data register #
        MOVE.B  #9,D6
        BSR     threeBitValue
        *buffer register #
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+
        
        *buffer ,
        MOVE.B  #36,(A2)+
        
        *Get destination EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        *invalid ea mask
        BSET    #31,D2
        BSET    #30,D2
        BSET    #24,D2
        
        *decode EA
        BSR     eaDecode
        BRA     opSUBEnd
        
opSubEa
        *ea source
        *Get destination EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        *no invalid EAs
        
        *decode EA
        BSR     eaDecode
        
        *buffer ,
        MOVE.B  #44,(A2)+
        
        *buffer D
        MOVE.B  #68,(A2)+
        
        *get data register #
        MOVE.B  #9,D6
        BSR     threeBitValue
        *buffer register #
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+
        
        *terminate buffer with null
        MOVE.B  #0,(A2)+
        
opSUBEnd
        BSR     printBuffer
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opSUBA
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the SUBA opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opSUBA
        *Print opcode
        LEA     strSUBA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 11 opcodes
*-----------------------------------------------------------
* Subroutine     : opEOR
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the EOR opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opEOR
        *Print opcode
        LEA     strEOR,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opCMP
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the CMP opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opCMP
        *Print opcode
        LEA     strCMP,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opCMPA
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the CMPA opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opCMPA
        *Print opcode
        LEA     strCMPA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 12 opcodes
*-----------------------------------------------------------
* Subroutine     : opMULSW
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the MULS opcode with a size of word
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opMULSW
        *buffer opcode
        LEA     strMULSW,A6
        BSR     toOutputBuffer
        
        *source EA
        MOVE.B  #0,D5       *store register
        MOVE.B  #3,D6       *store mode
        
        *invalid ea mask
        BSET    #30,D2
        
        BSR     eaDecode    *decode EA
        
        *buffer a ,
        MOVE.B  #44,(A2)+
        
        *destination register
        *buffer D
        MOVE.B  #68,(A2)+
        
        *get register number
        MOVE.B  #9,D6
        BSR     threeBitValue

        *buffer register number
        ADDI.B  #48,D7
        MOVE.B  D7,(A2)+

        *add null to end of buffer
        MOVE.B  #0,(A2)

        BSR     printBuffer       
        BRA     nextOp

        
*-----------------------------------------------------------
* Subroutine     : opAND
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the AND opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opAND
        *Print opcode
        LEA     strAND,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 13 opcodes
*-----------------------------------------------------------
* Subroutine     : opADD
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ADD opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opADD
        *Print opcode
        LEA     strADD,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp

*-----------------------------------------------------------
* Subroutine     : opADDA
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ADDA opcode
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opADDA
        *Print opcode
        LEA     strADDA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*group 14 opcodes
*-----------------------------------------------------------
* Subroutine     : opASd
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ASR,ASL opcodes
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opASd
        *Print opcode
        LEA     strASd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opLSd
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the LSR,LSL opcodes
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opLSd
        *Print opcode
        LEA     strLSd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine     : opROd
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Decodes the ROR,ROL opcodes
* Purpose        : The final step in decoding opcode
*-----------------------------------------------------------
opROd
        *Print opcode
        LEA     strROd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BRA     nextOp
        

*utility subroutines
*-----------------------------------------------------------
* Subroutine     : fourBitValue
* Written by     : Jeff Graham
* Last Modified  : 2/12/14
* Description    : Returns four bit value segment of word at specified memory location.
* Purpose        : Primary use is to sort opcodes into initial groups.
* Inputs         : D2 must contain word to be tested.
*                  D6 must contain the value indicating which four bit segment to test.
*                      Valid values for D6 are 0 (LSBs) to 3 (MSBs).
* Outputs        : D7 will contain the 4-bit value as a byte.
*-----------------------------------------------------------
fourBitValue
        MOVE.W  D2,D7       copy word data
        MULS.W  #4,D6       get num bits to shift by
        ASR     D6,D7       shift bits
        AND.W   #$000F,D7   clear all other bits in word
        RTS
        
*-----------------------------------------------------------
* Subroutine     : nextOp
* Written by     : Jeff Graham, Paul Pierot
* Last Modified  : 3/11/14
* Description    : Clears the op buffer, then checks for end of specified range.
* Purpose        : Move to the next word of data to be decoded
* Inputs         : None
* Outputs        : None
*-----------------------------------------------------------
nextOp
        *clear output buffer for next opcode
        LEA     opBuffer,A6
        ADDI.B  #1,D3       ;Increment the loop counter
        CMP.B   #23,D3      ;If 23 lines have been printed, branch to NXTPAGE
        BGE     NXTPAGE     ;+
clrLoop CMPA.L  A6,A2
        BEQ     CheckEnd
        MOVE.B  #0,(A6)+    *clear buffer a byte at a time
        BRA     clrLoop
CheckEnd
        *check for end of data
        CMP.L   A4,A3
        BEQ     ENDLOOP     *Clear output and prompt user to loop
        
        BRA     decodeOp    *if not end decode next op
        
ENDLOOP BSR     CLEAR       ;Clear the screen
        LEA     ENDING,A1   ;Display a message saying that the end of memory has been reached
        MOVE.B  #14,D0      ;+
        TRAP    #15         ;+
        BSR     CLEAR       ;Clear the screen and restart the program
        BSR     EMPTY       ;Clean out the Registers
        BRA     BEGIN       ;+

*-----------------------------------------------------------
* Subroutine     : toOutputBuffer
* Written by     : Jeff Graham
* Last Modified  : 3/3/14
* Description    : Copies null terminated string to output buffer
* Purpose        : Primary use is to fill the output buffer
* Inputs         : A2 must contain the address of the next unused word in the 
*                   output buffer.
*                  A6 must contain the starting address of the null terminated
*                   string to be copied
*-----------------------------------------------------------
toOutputBuffer
        CMPI.B  #0,(A6)
        BEQ     endOfString     *if == 0, end
        MOVE.B  (A6)+,(A2)+     *copy value to buffer and increment
        BRA     toOutputBuffer  *loop
        
endOfString
        *end string and return
        MOVE.B  #$00,(A2)   *add null to end
        RTS
        
*-----------------------------------------------------------
* Subroutine     : printBuffer
* Written by     : Jeff Graham
* Last Modified  : 3/7/14
* Description    : Prints the output buffer
* Purpose        : Primary use is to print opcodes
* Inputs         : None
*-----------------------------------------------------------
printBuffer
        LEA     opBuffer,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        RTS

*-----------------------------------------------------------
* Subroutine     : eaDecode
* Written by     : Jeff Graham
* Last Modified  : 3/10/14
* Description    : Given an opcode and the starting bit position of mode and register
*                   three-bit pairs, this decodes the addressing mode and moves 
*                   appropriate string to output buffer
* Purpose        : Primary use is to decode effective addresses
* Inputs         : A2 must contain the address of the next unused word in the 
*                   output buffer. 
*                  A3 must contain memory location of the word following the opcode
*                   that is to be decoded.
*                  D2 must contain a copy of the opcode word to be decoded
*                  D4 must hold the size of the operation (for use in immediate data modes) 
*                  D5 must hold the bit position of the start of the register three bits
*                  D6 must hold the bit position of the start of the mode three bits 
*----------------------------------------------------------- 
eaDecode
        *check modes, D5 holds the start of the register, 
        BSR         threeBitValue       *load three bit value to D7
        *test result for mode
        CMPI.B      #0,D7
        BEQ         modeDataReg
        CMPI.B      #1,D7
        BEQ         modeAddressReg
        CMPI.B      #2,D7
        BEQ         modeIndirAddress
        CMPI.B      #3,D7
        BEQ         modePostInc
        CMPI.B      #4,D7
        BEQ         modePreDec
        CMPI.B      #7,D7
        BEQ         modeSeven

        BRA         eaDecodeUnknownOp
        
        *Modes
modeDataReg
        *check valid
        BTST        #31,D2
        BNE         eaDecodeUnknownOp   *if set, then Dn is invalid mode
        
        *move register and number to output buffer
        MOVE.B      #68,(A2)+       *move 'D' to output buffer, (68 is ascii for D)
        
        *get register number
        MOVE.W      D5,D6
        BSR         threeBitValue
        *buffer register number
        ADD.B       #48,D7      *convert number to ascii
        MOVE.B      D7,(A2)+
        *add null terminator to buffer
        MOVE.B      #0,(A2)     *note: no post inc, so that null will be overwritten by next character
        RTS
        
modeAddressReg
        *check valid
        BTST        #30,D2
        BNE         eaDecodeUnknownOp   *if set, then An is invalid mode
        
        *get register number
        MOVE.W      D5,D6
        BSR         threeBitValue
        
        *move register and number to output buffer
        MOVE.B      #65,(A2)+   *move 'A' to buffer, 65 is ascii for A
        
        *buffer register number
        ADD.B       #48,D7      *convert number to ascii
        MOVE.B      D7,(A2)+    *buffer register num
        *add null terminator
        MOVE.B      #0,(A2)
        RTS



modeIndirAddress
        *check valid
        BTST        #29,D2
        BNE         eaDecodeUnknownOp   *if set, then (An) is invalid mode
        
        *get register number
        MOVE.W      D5,D6
        BSR         threeBitValue
        
        *buffer register and number
        *buffer ( here
        MOVE.B      #40,(A2)+   *40 is ascii for (
        
        *buffer A here
        MOVE.B      #65,(A2)+   *65 is ascii for A
                
        *buffer register number
        ADD.B       #48,D7      *convert number to ascii
        MOVE.B      D7,(A2)+    *buffer register
                
        *buffer ) here
        MOVE.B      #41,(A2)+      *41 is ascii for )

        *add null terminator to buffer
        MOVE.B      #0,(A2)
        
        RTS

modePostInc
        *check valid
        BTST        #28,D2
        BNE         eaDecodeUnknownOp   *if set, then (An)+ is invalid mode
        
        *get register number
        MOVE.W      D5,D6
        BSR         threeBitValue
        
        *buffer register and number
        *buffer ( here
        MOVE.B      #40,(A2)+   *40 is ascii for (
                
        *buffer A here
        MOVE.B      #65,(A2)+      *65 is ascii for A
                
        *buffer register number
        ADD.B       #48,D7      *convert number to ascii
        MOVE.B      D7,(A2)+
                
        *buffer ) here
        MOVE.B      #41,(A2)+      *41 is ascii for )
                
        *buffer + here
        MOVE.B      #43,(A2)+      *43 is ascii for +

        *add null terminator to buffer
        MOVE.B      #0,(A2)
                
        RTS

modePreDec
        *check valid
        BTST        #27,D2
        BNE         eaDecodeUnknownOp   *if set, then -(An) is invalid mode
        
        *get register number
        MOVE.W      D5,D6
        BSR         threeBitValue
        
        *buffer register and number
        *buffer - here
        MOVE.B      #45,(A2)+      *45 is ascii for -
                
        *buffer ( here
        MOVE.B      #40,(A2)+      *40 is ascii for (
                
        *buffer A here
        MOVE.B      #65,(A2)+      *65 is ascii for A
                
        *buffer register number
        ADD.B       #48,D7      *convert number to ascii
        MOVE.B      D7,(A2)+
                
        *buffer ) here
        MOVE.B      #41,(A2)+      *41 is ascii for )
                
        *add null terminator to buffer
        MOVE.B      #0,(A2)

        RTS

modeSeven
        *check register
        MOVE.W      D5,D6
        BSR         threeBitValue
        CMPI.B      #0,D7       *if address register 0, then modeAbsWord
        BEQ         modeAbsWord
        CMPI.B      #1,D7
        BEQ         modeAbsLong
        CMPI.B      #4,D7
        BEQ         modeImmediate
        
        BRA         eaDecodeUnknownOp

modeAbsWord
        *check valid
        BTST        #26,D2
        BNE         eaDecodeUnknownOp   *if set, then (xxx).W is invalid mode
        
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        *convert word data at (A3) to ascii hex
        MOVE.L      #4,D4           *number of hex digits to be printed
        MOVE.W      (A3),D1         *word to be printed
        BSR         hexToAscii
        
        
        *move ascii hex to output buffer
        LEA         OUTPUT,A6       *data to be copied to buffer
        BSR         toOutputBuffer
        
        *increment A3 ptr by one word
        ADDA.L      #2,A3
        
        RTS

modeAbsLong
        *check valid
        BTST        #25,D2
        BNE         eaDecodeUnknownOp   *if set, then (xxx).L is invalid mode
        
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        *convert Longword data at (A3) to ascii hex digits
        MOVE.L      #8,D4           *number of hex digits to be printed
        MOVE.L      (A3),D1         *longword to be printed
        BSR         hexToAscii
        
        *move ascii hex to output buffer
        LEA         OUTPUT,A6       *data to be copied to buffer
        BSR         toOutputBuffer

        *increment A3 ptr by one longword
        ADDA.L      #4,A3
        
        RTS

modeImmediate
        *check valid
        BTST        #24,D2
        BNE         eaDecodeUnknownOp   *if set, then #<data> is invalid mode
        
        *move # to output Buffer
        MOVE.B      #35,(A2)+       *35 is ascii for #
        *move $ to output buffer
        MOVE.B      #36,(A2)+       *36 is ascii code for $
        *check size
        CMP.B       #1,D4
        BLT         byteOpImmediate
        BEQ         wordOpImmediate
        BGT         longOpImmediate
        

byteOpImmediate
        *read size data
        ADDA.L      #1,A3       *advance pointer one byte
        MOVE.B      (A3),D1
        MOVE.L      #2,D4       *number of hex digits to convert
        BSR         hexToAscii  *move byte to output buffer

        *move ascii hex digits to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer

        ADDA.L      #1,A3       *advance pointer one more byte
        
        RTS

wordOpImmediate
        *read size data
        MOVE.W      (A3),D1
        MOVE.L      #4,D4       *# of hex digits to convert
        BSR         hexToAscii  *move word to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #2,A3       *advance pointer one more byte
        
        RTS

longOpImmediate
        *read size data
        MOVE.L      (A3),D1
        MOVE.L      #8,D4       *# of hex digits to convert
        BSR         hexToAscii  *move long to output buffer
        
        *move ascii to output buffer
        LEA         OUTPUT,A6
        BSR         toOutputBuffer
        
        ADDA.L      #4,A3       *advance pointer one more byte
        
        RTS


eaDecodeUnknownOp   
        *increment SP
        ADDQ.L      #4,SP
        *go to unknownOp
        BRA         unknownOp   

*-----------------------------------------------------------
* Subroutine     : threeBitValue
* Written by     : Jeff Graham
* Last Modified  : 2/17/14
* Description    : Returns three bit value segment of word at specified memory location.
* Purpose        : Primary use is to decode effective addresses
* Inputs         : D2 must contain a copy of the word to be tested.
*                  D6 must contain the offset bit indicating the start of the 
*                      three bit segment to test.
* Outputs        : D7 will contain the 3-bit value as a word.
*-----------------------------------------------------------
threeBitValue
        MOVE.W  D2,D7       copy word data
        ASR     D6,D7       shift bits
        AND.W   #$0007,D7   clear all other bits in word
        RTS

*-----------------------------------------------------------
* Subroutine     : unknownOp
* Written by     : Jeff Graham
* Last Modified  : 2/15/14
* Description    : Prints unknown op error & hex word data, advances data pointer, 
*                   and calls decodeOp to start the next word.
* Purpose        : To handle an unknown or invalid opcode.
* Inputs         : None
* Outputs        : None
*-----------------------------------------------------------
unknownOp
        *Print error message and hex data here
        LEA     strUnknownOp,A1
        MOVE.B  #13,D0
        TRAP    #15
        *TODO: Print Hex data
        BRA     nextOp
        
*-----------------------------------------------------------
* Subroutine 	: hexToASCII
* Written by 	: Paul Pierot
* Last Modified : 3/6/2014
* Description	: Converts the hexadecimal in a register 
*                   into ASCII code
* Purpose       : To convert hexadecimal into ASCII for easy
*                   printing
* Inputs		: D1 will hold at least 1 bit of hexadecimal
*                 D4 will hold the number of hexadecimal 
*                   bits to read
* Outputs		: The variable OUTPUT will hold the ASCII 
*                   output
*-----------------------------------------------------------
hexToAscii
        LEA     TEXT,A1     ;Loads the TEXT variable into A1
        MOVE.B  D4,D6       ;D6 holds the original value of D4
LOOPHEX TST.B   D6          ;If there are no more bits to convert, branch to LOOP_DN
        BEQ     LOOP_DN     ;+
        MOVE.B  D1,D5       ;D5 holds a copy of D1
        ASR.L   #4,D1       ;Shift D1 over by one Hex bit
        AND.B   #$0F,D5     ;Mask all but the least significant Hex bit
        BRA     HEX_ASC     ;Convert the Hex bit into ASCII
        
HEX_ASC CMP.B   #$9,D5      ;Determines if the Hex is 0~9 or A~F
        BLE     HEX_NUM     ;+
        ADD.B   #55,D5      ;Hex is A~F, add decimal 55 to get the ASCII value
        BRA     STORE2      ;Jump to storing the ASCII
HEX_NUM ADD.B   #48,D5      ;Hex is 0~9, add decimal 48 to get the ASCII value
STORE2  MOVE.B  D5,(A1)+    ;Stores the converted value in to OUTPUT
        SUB.B   #1,D6       ;Decrements the number of Hexs to convert
        BRA     LOOPHEX     ;Jump back to the LOOPHEX loop
        
LOOP_DN LEA     OUTPUT,A5   ;Loads the OUTPUT variable into A5
ASCI_LP TST.B   D4          ;If there's no more characters to convert, finish the subroutine
        BEQ     ASCI_DN     ;+
        MOVE.B  -(A1),(A5)+ ;Moves one character from OUTPUT into TEXT
        SUB.B   #1,D4       ;Decrements the number of character to convert
        BRA     ASCI_LP     ;Begins the loop again

ASCI_DN MOVE.B  #0,(A5)+    ;Move a NULL character into the end of the string
        MOVEA.L #0,A5       ;Cleans out A5, D1, and D5
        MOVE.L  #0,D1       ;+
        CLR     D5          ;+
        RTS                 ;Return to the routine that called hexToASCII
        
*-----------------------------------------------------------
* Subroutine     : NXTPAGE
* Written by     : Paul Pierot
* Last Modified  : 3/11/14
* Description    : Clears the screen and starts a new "page"
* Purpose        : To allow the program to display page-by-page
* Inputs         : N/A
* Outputs        : N/A
*-----------------------------------------------------------
NXTPAGE MOVE.B  #0,D3       ;Zero out D3 for counting the loop
        BSR     CLEAR
        
        BRA     clrLoop     ;Return to check the next memory address
        
*-----------------------------------------------------------
* Subroutine     : EMPTY
* Written by     : Paul Pierot
* Last Modified  : 3/11/14
* Description    : Zeros out all Data and Address Registers
* Purpose        : To allow a clean restart of the program
* Inputs         : N/A
* Outputs        : N/A
*-----------------------------------------------------------
EMPTY   MOVE.L  #0,D0
        MOVE.L  #0,D1
        MOVE.L  #0,D2
        MOVE.L  #0,D3
        MOVE.L  #0,D4
        MOVE.L  #0,D5
        MOVE.L  #0,D6
        MOVE.L  #0,D7
        MOVEA.L #0,A0
        MOVEA.L #0,A1
        MOVEA.L #0,A2
        MOVEA.L #0,A3
        MOVEA.L #0,A4
        MOVEA.L #0,A5
        MOVEA.L #0,A6
        RTS                 ;Returns to the routine that called EMPTY

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
        DC.B    'Begin Decompiler? ("Y" to continue, "N" to quit): ',CR,LF,0
RANGE_S DC.B    CR,LF,'Enter the starting memory address: ',CR,LF,0
RANGE_E DC.B    'Enter the ending memory address: ',CR,LF,0
VALID   DC.B    CR,LF,'Memory range is valid. Beginning decompiler',CR,LF,0
INV_I   DC.B    CR,LF,'ERROR: Input must be valid.',CR,LF,0
INV_C   DC.B    CR,LF,'ERROR: Invalid character. Values 0~9 or A~F only.',CR,LF
        DC.B    'Make sure you are using capital letters. This program does not allow deleting.',CR,LF,0
CONT    DC.B    CR,LF,'Press any key to Continue',0   
ENDING  DC.B    'End Memory Address reached. Now returning to the main screen.',CR,LF,0

INPUT   DS.B    16          ;Used for the conversion in GETHEX
TEXT    DS.B    16          ;Used for the conversion in hexToASCII subroutine
OUTPUT  DS.B    16          ;The completed string for hexToASCII subroutine

strUnknownOp    DC.B    'Unknown Op: ',0
opBuffer        DS.B    64  *longest opcode is ~60 characters

*opcode strings
strADDI         DC.B    'ADDI',0
strANDI         DC.B    'ANDI',0
strEORI         DC.B    'EORI',0
strBCHG         DC.B    'BCHG ',0
strCMPI         DC.B    'CMPI',0
strMOVEB        DC.B    'MOVE.B ',0
strMOVEL        DC.B    'MOVE.L ',0
strMOVEW        DC.B    'MOVE.W ',0
strMOVEM        DC.B    'MOVEM',0
strLEA          DC.B    'LEA ',0
strCLR          DC.B    'CLR',0
strJSR          DC.B    'JSR ',0
strRTS          DC.B    'RTS',0
strMULSL        DC.B    'MULS.L ',0
strSUBQ         DC.B    'SUBQ',0
strBCC          DC.B    'BCC ',0
strBGT          DC.B    'BGT ',0
strBLE          DC.B    'BLE ',0
strBVS          DC.B    'BVS ',0
strMOVEQ        DC.B    'MOVEQ ',0
strDIVU         DC.B    'DIVU',0
strSUB          DC.B    'SUB',0
strSUBA         DC.B    'SUBA',0
strEOR          DC.B    'EOR',0
strCMP          DC.B    'CMP',0
strCMPA         DC.B    'CMPA',0
strMULSW        DC.B    'MULS.W ',0
strAND          DC.B    'AND',0
strADD          DC.B    'ADD',0
strADDA         DC.B    'ADDA',0
strASd          DC.B    'ASd',0
strLSd          DC.B    'LSd',0
strROd          DC.B    'ROd',0
strByte         DC.B    '.B ',0
strWord         DC.B    '.W ',0
strLong         DC.B    '.L ',0

        END     START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
