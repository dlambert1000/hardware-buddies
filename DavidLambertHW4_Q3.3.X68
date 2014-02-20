*-----------------------------------------------------------
* Title      :ADD neg hex numbers (Q3.3)
* Written by :David Lambert
* Class:     :CSS 422
* Date       :08 Feb, 2014
* Description:HW 4, Q3.3
*-----------------------------------------------------------

* This is a program to add two negative hexadecimal numbers *
* and display the results in decimal.                       *

CR      EQU     $0D         
LF      EQU     $0A

START   ORG     $1000

*---------ADD hexadecimal numbers and store-----------------
        LEA     MESSAGE,A1      Load addition message into A1
        MOVE.B  #14,D0          Load trap task into D0 (14)
        TRAP    #15             Execute trap task in D0 (display message)
        
        MOVE.B  #$9B,D1         Load $9B (-101) into D1
        MOVE.B  #$B9,D2         Load $B9 (-71) into D2
        ADD.B   D1,D2           Add D1 contents to D2 ($9B to $B9), store in D2
        MOVE.B  D2,$7000        Copy the result in D2 to address $7000
        
*---------Display the result in decimal--------------------
        MOVE.B  $7000,D1        Copy result from $7000 to D1
        MOVE.B  #3,D0           Load trap task 3
        TRAP    #15             Execute task (display signed number in D1.L in decimal) 
        LEA     NOTIFY,A1       Load error notification message
        MOVE.B  #14,D0
        TRAP    #15
        
        *This 8-bit addition produces an overflow error*
        
*---------Message Output-----------------------------------
MESSAGE     DC.B        '$9B (-101) + $B9 (-71) = decimal value ',0   Equation to be performed
NOTIFY      DC.B        '',CR,LF
            DC.B        '',CR,LF
            DC.B        'Note-decimal value is incorrect.',CR,LF    Overflow note
            DC.B        'This 8-bit addition produces an overflow,',CR,LF
            DC.B        'resulting in an incorrect positive number',CR,LF
            DC.B        'instead of a negative number (-172)',0
            
      
        
        END     START
        

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
