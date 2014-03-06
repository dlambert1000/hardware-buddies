*-----------------------------------------------------------
* Title      : Decode Opcodes
* Written by : Jeff Graham
* Date       : 2/14/14
* Description: 
*-----------------------------------------------------------


    ORG    $1000
START:                  ; first instruction of program

* Put program code here

        
        *hardcoded data and end ptrs for Test1.S68
        MOVEA.W     #$4000,A3       *set data ptr
        MOVEA.W     #$4052,A4       *set end data ptr
        
        
        *start decode
        BRA         decodeOp

    
    
halt    SIMHALT             ; halt simulator
    
* Subroutines here
*-----------------------------------------------------------
* Subroutine     : decodeOp
* Written by     : Jeff Graham
* Last Modified  : 2/14/14
* Description    : sorts opcodes according to groups based on their first 4-bits
* Purpose        : The first step in decoding an opcode
* Inputs         : None (depends on the opcode pointer being A3)
* Outputs        : None (branches to next SR in line)
*-----------------------------------------------------------
decodeOp
        *get first four bit value
        MOVE.B      #3,D6   *specify most significant four bits wanted
        MOVEA.W     A3,A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
        MOVE.L      A3,A6       *copy current decode pointer to A6
        MOVE.B      #1,D6       *check 3rd 4bit value
        BSR         fourBitValue
        
        *compare 4-bit data to determine opcode
        *if odd -> ROd, else -> LSd or ASd
        ANDI.B      #1,D7
        CMPI.B      #1,D7
        BEQ         opROd       *if odd
        
        *check bit #3
        MOVE.L      A3,A6       *copy current decode pointer to A6
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
opADDI
        *Print opcode
        LEA     strADDI,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again
opANDI
        *Print opcode
        LEA     strANDI,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again

opEORI
        *Print opcode
        LEA     strEORI,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again

opBCHGStat
        *Print opcode
        LEA     strBCHG,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opBCHGDyn
        *Print opcode
        LEA     strBCHG,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opCMPI
        *Print opcode
        LEA     strCMPI,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again

*group 1 opcodes
opMOVEB
        *Print opcode
        LEA     strMOVEB,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 2 opcodes
opMOVEL
        *Print opcode
        LEA     strMOVEL,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 3 opcodes
opMOVEW
        *Print opcode
        LEA     strMOVEW,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
*group 4 opcodes
opMOVEMMtoR
        *Print opcode
        LEA     strMOVEM,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opMOVEMRtoM
        *Print opcode
        LEA     strMOVEM,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opLEA
        *Print opcode
        LEA     strLEA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again
        
opCLR
        *Print opcode
        LEA     strCLR,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opJSR
        *Print opcode
        LEA     strJSR,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        *Placeholder ptr advance
        BSR     advancePtr  *advance opcode ptr to next word
        BSR     advancePtr
        BRA     decodeOp    *start again
        
opRTS
        *Print opcode
        LEA     strRTS,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opMULSL
        *Print opcode
        LEA     strMULSL,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 5 opcodes
opSUBQ
        *Print opcode
        LEA     strSUBQ,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 6 opcodes
opBCC
        *Print opcode
        LEA     strBCC,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opBGT
        *Print opcode
        LEA     strBGT,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opBLE
        *Print opcode
        LEA     strBLE,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opBVS
        *Print opcode
        LEA     strBVS,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 7 opcodes
opMOVEQ
        *Print opcode
        LEA     strMOVEQ,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 8 opcodes
opDIVU
        *Print opcode
        LEA     strDIVU,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 9 opcodes
opSUB
        *Print opcode
        LEA     strSUB,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opSUBA
        *Print opcode
        LEA     strSUBA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 11 opcodes
opEOR
        *Print opcode
        LEA     strEOR,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opCMP
        *Print opcode
        LEA     strCMP,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opCMPA
        *Print opcode
        LEA     strCMPA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 12 opcodes
opMULSW
        *Print opcode
        LEA     strMULSW,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opAND
        *Print opcode
        LEA     strAND,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 13 opcodes
opADD
        *Print opcode
        LEA     strADD,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opADDA
        *Print opcode
        LEA     strADDA,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again

*group 14 opcodes
opASd
        *Print opcode
        LEA     strASd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opLSd
        *Print opcode
        LEA     strLSd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again
        
opROd
        *Print opcode
        LEA     strROd,A1
        MOVE.W  #13,D0
        TRAP    #15
        
        BSR     advancePtr  *advance opcode ptr to next word
        BRA     decodeOp    *start again


*utility subroutines
*-----------------------------------------------------------
* Subroutine     : fourBitValue
* Written by     : Jeff Graham
* Last Modified  : 2/12/14
* Description    : Returns four bit value segment of word at specified memory location.
* Purpose        : Primary use is to sort opcodes into initial groups.
* Inputs         : A6 must contain memory location of word to be tested.
*                   D6 must contain the value indicating which four bit segment to test.
*                      Valid values for D6 are 0 (LSBs) to 3 (MSBs).
* Outputs        : D7 will contain the 4-bit value as a byte.
*-----------------------------------------------------------
fourBitValue
        MOVE.W  (A6),D7     copy word data
        MULS.W  #4,D6       get num bits to shift by
        ASR     D6,D7       shift bits
        AND.W   #$000F,D7   clear all other bits in word
        RTS
*-----------------------------------------------------------
* Subroutine     : advancePtr
* Written by     : Jeff Graham
* Last Modified  : 2/16/14
* Description    : Advances data pointer (A3) by one word, then checks for end of specified range
* Purpose        : Move to the next word of data to be decoded
* Inputs         : None
* Outputs        : None
*-----------------------------------------------------------
advancePtr
        ADDA.L  #$2,A3      advance A3 by one word
        BSR     checkEndOfData
        RTS
*-----------------------------------------------------------
* Subroutine     : checkEndOfData
* Written by     : Jeff Graham
* Last Modified  : 2/16/14
* Description    : Checks for end of specified data range, branches to halt if found
* Purpose        : To stop the disassembler at the end of the specified range.
* Inputs         : None
* Outputs        : None
*-----------------------------------------------------------
checkEndOfData
        *check for end of user defined memory range
        CMP.L   A4,A3
        BEQ     halt        *TODO: this branch could cause stack issues.
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
        *TODO: Print error message and hex data here
        BSR     advancePtr
        BRA     decodeOp
        
* Put variables and constants here

*opcode strings
strADDI         DC.B    'ADDI',0
strANDI         DC.B    'ANDI',0
strEORI         DC.B    'EORI',0
strBCHG         DC.B    'BCHG',0
strCMPI         DC.B    'CMPI',0
strMOVEB        DC.B    'MOVE.B',0
strMOVEL        DC.B    'MOVE.L',0
strMOVEW        DC.B    'MOVE.W',0
strMOVEM        DC.B    'MOVEM',0
strLEA          DC.B    'LEA',0
strCLR          DC.B    'CLR',0
strJSR          DC.B    'JSR',0
strRTS          DC.B    'RTS',0
strMULSL        DC.B    'MULS.L',0
strSUBQ         DC.B    'SUBQ',0
strBCC          DC.B    'BCC',0
strBGT          DC.B    'BGT',0
strBLE          DC.B    'BLE',0
strBVS          DC.B    'BVS',0
strMOVEQ        DC.B    'MOVEQ',0
strDIVU         DC.B    'DIVU',0
strSUB          DC.B    'SUB',0
strSUBA         DC.B    'SUBA',0
strEOR          DC.B    'EOR',0
strCMP          DC.B    'CMP',0
strCMPA         DC.B    'CMPA',0
strMULSW        DC.B    'MULS.W',0
strAND          DC.B    'AND',0
strADD          DC.B    'ADD',0
strADDA         DC.B    'ADDA',0
strASd          DC.B    'ASd',0
strLSd          DC.B    'LSd',0
strROd          DC.B    'ROd',0

    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
