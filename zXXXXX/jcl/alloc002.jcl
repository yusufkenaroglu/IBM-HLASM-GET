//GETALLOC JOB (ACCT),'ALLOCATE GET PDS',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*-----------------------------------------------------------
//* ALLOCATE PROJECT DATASETS
//*   - &SYSUID..GET.JCL     (PDS for JCL, ASM/RUN members)
//*   - &SYSUID..GET.SOURCE  (PDS for assembler source)
//*-----------------------------------------------------------
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
