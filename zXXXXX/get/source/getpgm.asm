GETPGM   TITLE 'WTO GET pgm'
GETPGM   CSECT
*--------------------------------------------------------------------*
*        register equates                                            *
*--------------------------------------------------------------------*
               YREGS                   register equates
BASEREG  EQU   12                      base register
SAVEREG  EQU   13                      save area register
RETREG   EQU   14                      caller's return address
ENTRYREG EQU   15                      entry address
RETCODE  EQU   15                      return code
         EJECT
*--------------------------------------------------------------------*
*        standard entry setup, save area chaining, establish         *
*        base register and addressibility                            *
*--------------------------------------------------------------------*
         USING GETPGM,ENTRYREG         establish addressibility
         B     SETUP                   branch around eyecatcher
         DC    CL6'GETPGM'             program name
SETUP    STM   RETREG,BASEREG,12(SAVEREG)  save caller's registers
         BALR  BASEREG,R0              establish base register
         DROP  ENTRYREG                drop initial base register
         USING *,BASEREG               establish addressibilty
         LA    ENTRYREG,SAVEAREA       point to this program save area
         ST    SAVEREG,4(,ENTRYREG)    save address of caller
         ST    ENTRYREG,8(,SAVEREG)    save address of this program
         LR    SAVEREG,ENTRYREG        point to this program savearea
         EJECT
*--------------------------------------------------------------------*
*        program body                                                *
*--------------------------------------------------------------------*
         L     6,=C'Begin'
         LA    6,=C'Begin'
LOOPINIT DS    0H                      halfword boundary alignment
         OPEN  (SYSIN,(INPUT))                                           
         OPEN  (SYSOUT,(OUTPUT)) 
         GET   SYSIN,INREC             Read the rec (line from SYSIN)        
         PUT   SYSOUT,INREC            Write it to SYSOUT
         PACK  PACKED,INREC(2)         Get the 2-digit decimal input
         CP    PACKED,=P'0'            Guard the input - positive  
         BNH   TOOLOW                  
         CP    PACKED,=P'50'           No need to loop > 50 times...
         BH    TOOHIGH

LOOP     DS    0H                      halfword boundary alignment
         MVC   ZONED(L'EDITMSK),EDITMSK
         ED    ZONED,PACKED            Edit packed into zoned decimal
         OI    ZONED+7,X'F0'           Ensure EBCDIC compatibility
         MVC   LINE(L'ZONED),ZONED     move LOOPCNT into LINE  
         MVC   LINE(L'MSG),MSG         move message into LINE
         PUT   SYSOUT,LINE             Write line to SYSOUT
         SP    PACKED,=P'1'            Decrement LOOPCNT
         CP    PACKED,=P'0'            Loop if LOOPCNT != 0
         BH    LOOP
         J STOP1                       

FINISH   DS   0H                       Invoked at End of Data of SYSIN
         CLOSE SYSIN                                                     
         CLOSE SYSOUT  
STOP1    LH    7,HALFCON
STOP2    A     7,FULLCON
STOP3    ST    7,HEXCON
         WTO   '* GETPGM MLC, is ENDING, CC=0...'
         J EXIT
ABEND4   EQU   *
         WTO   '* GETPGM MLC, is ABENDING, CC=4...'
         LFI   RETCODE,4              set MAXCC to 4
         J EXIT
TOOHIGH  EQU   *
         WTO   '* GETPGM LOOP COUNT TOO LARGE...'
         LFI   RETCODE,2              set MAXCC to 2
         J EXIT
TOOLOW   EQU   *
         WTO   '* GETPGM LOOP COUNT TOO SMALL...'
         LFI   RETCODE,1              set MAXCC to 1
*--------------------------------------------------------------------*
*   standard exit - restore caller's registers and return to caller  *
*--------------------------------------------------------------------*
EXIT     DS    0H                      halfword boundary alignment
         L     SAVEREG,4(,SAVEREG)     restore caller's save area addr
         L     RETREG,12(,SAVEREG)     restore return address register
         LM    R0,BASEREG,20(SAVEREG)  restore all regs. except RETCODE
         BR    RETREG                  return to caller
         EJECT
*--------------------------------------------------------------------*
*        storage and constant definitions.                           *
*        print output definition.                                    *
*--------------------------------------------------------------------*  
SAVEAREA DC    18F'-1'                 register save area
FULLCON  DC    F'-1'
HEXCON   DC    XL4'9ABC'
HALFCON  DC    H'32'
         DS    0H                      ENSURE HALF-WORD ALIGNMENT
*                                                                       
SYSIN    DCB   DSORG=PS,MACRF=(GM),DDNAME=SYSIN,EODAD=FINISH,          *
               RECFM=FB,LRECL=80,BLKSIZE=0                              
SYSOUT   DCB   DSORG=PS,MACRF=(PM),DDNAME=SYSOUT,                      *
               RECFM=FBA,LRECL=133,BLKSIZE=0                            
*                                                                       
INREC    DC    CL133' '
PACKED   DS    PL4                * loop count as packed decimal
ZONED    DS    CL8                * zoned for printable digits
EDITMSK  DC    X'4020202020202020' * suppress leading zeros
LINE     DC    CL133' '
MSG      DC    C'LOOP: '
         LTORG
         END   GETPGM
