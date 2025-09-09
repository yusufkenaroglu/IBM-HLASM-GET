# IBM HLASM GET - I/O Operations with IBM High Level Assembler

[![License](https://img.shields.io/github/license/yusufkenaroglu/IBM-HLASM-GET)](LICENSE)
[![Language](https://img.shields.io/badge/language-IBM%20HLASM%20%7C%20JCL-blue)](https://www.ibm.com/products/high-level-assembler-and-toolkit-feature)

## Overview

This repository contains IBM High Level Assembler (HLASM) programs demonstrating file I/O operations using OPEN, CLOSE, and GET macros. The main program `GETPGM` showcases sequential file processing with loop control, data validation, and proper error handling in a mainframe environment.

## Repository Structure

```
zXXXXX/
├── get/
│   ├── source/
│   │   └── getpgm.asm          # Main HLASM program
│   └── jcl/
│       ├── asm.jcl             # Assemble job
│       └── run.jcl             # Execute job
└── jcl/
    └── alloc002.jcl            # Dataset allocation
```

## Program Features

The `GETPGM` program demonstrates:

- **Sequential dataset I/O** with SYSIN/SYSOUT 
- **Input validation** with decimal logic
- **Packed decimal arithmetic** for program flow control
- **Formatted output** with edit masks
- **Error handling** with setting return codes
- **SS (Storage/Storage) instructions** to reduce register clobbering

## Key Code Snippets

### I/O Operations
```asm
OPEN  (SYSIN,(INPUT))                                           
OPEN  (SYSOUT,(OUTPUT)) 

* Read input record
GET   SYSIN,INREC             Read the rec (line from SYSIN)        
PUT   SYSOUT,INREC            Write it to SYSOUT

* Close files at end of processing
CLOSE SYSIN                                                     
CLOSE SYSOUT  
```

### Input Processing and Validation
```asm
* Convert input to packed decimal and validate
PACK  PACKED,INREC(2)         Get the 2-digit decimal input
CP    PACKED,=P'0'            Guard the input - positive  
BNH   TOOLOW                  
CP    PACKED,=P'50'           No need to loop > 50 times...
BH    TOOHIGH
```

### Looping with Formatted Output
```asm
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
```

### DCB Definitions
```asm
SYSIN    DCB   DSORG=PS,MACRF=(GM),DDNAME=SYSIN,EODAD=FINISH,          *
               RECFM=FB,LRECL=80,BLKSIZE=0                              
SYSOUT   DCB   DSORG=PS,MACRF=(PM),DDNAME=SYSOUT,                      *
               RECFM=FBA,LRECL=133,BLKSIZE=0                            
```

## Setup and Execution

### 1. Project Dataset Allocation

First, allocate the required datasets using the provided JCL:

```jcl
//GETALLOC JOB (ACCT),'ALLOCATE GET PDS',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),NOTIFY=&SYSUID
//ALLOC    EXEC PGM=IEFBR14
//JCL      DD  DSN=&SYSUID..GET.JCL,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(5,5,5)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//SOURCE   DD  DSN=&SYSUID..GET.SOURCE,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=SYSDA,
//             SPACE=(TRK,(10,5,5)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
```

### 2. Assembling the Source Code

Assemble the program using the ASMACL procedure:

```jcl
//GETPGASM JOB 1,NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//ASM      EXEC ASMACL,MBR=GETPGM
//C.SYSIN  DD  DSN=&SYSUID..GET.SOURCE(GETPGM),DISP=SHR
//SYSLMOD  DD  DSN=&SYSUID..LOAD,DISP=SHR
```

### 3. Executing the Binary

Run the program with input data (16):

```jcl
//GETEXEC JOB (CCCCCCCC),'YKENAR',
//             MSGLEVEL=(1,1),
//             MSGCLASS=O,
//             CLASS=A,
//             NOTIFY=&SYSUID
//STEP1  EXEC PGM=GETPGM
//STEPLIB DD  DSN=&SYSUID..LOAD,DISP=SHR
//SYSIN  DD  *
16
/*
//SYSOUT  DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
```

## Return Codes

| Code | Condition | Description |
|------|-----------|-------------|
| 0 | Normal | Successful execution |
| 1 | TOOLOW | Input value ≤ 0 |
| 2 | TOOHIGH | Input value > 50 |
| 4 | ABEND4 | General error condition |

## Data Definitions

```asm
SAVEAREA DC    18F'-1'                 register save area
INREC    DC    CL133' '               input record buffer
PACKED   DS    PL4                    loop count as packed decimal
ZONED    DS    CL8                    zoned for printable digits
EDITMSK  DC    X'4020202020202020'    suppress leading zeros
LINE     DC    CL133' '               output line buffer
MSG      DC    C'LOOP: '              loop message prefix
```

## Prerequisites

- IBM z/OS environment
- HLASM compiler
- Access to system macro libraries (SYS1.MACLIB)
- Authority to create datasets and submit jobs

## Usage Notes

- Input must be a 2-digit decimal number (01-99) -> Anything above 50 will be ignored by the program
- Program expects FB/80 input format
- Output is formatted with RECFM=FBA, LRECL=133
- All JCL uses symbolic parameters (&SYSUID) for dataset names
