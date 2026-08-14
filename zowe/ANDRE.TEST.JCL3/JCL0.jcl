//********************************************************************
//*                                                                  *
//* PROPRIETARY STATEMENT:                                           *
//*    Licensed Materials - Property of IBM                          *
//*    5655-ZOS Copyright IBM Corp. 2025                             *
//*                                                                  *
//*    STATUS=HBB77E0                                                *
//*                                                                  *
//* DESCRIPTION:                                                     *
//*                                                                  *
//*    This job copies the Python script stored in                   *
//*    JOVE.JCL.SHARE(PSCRIPT1) to the UNIX file:                    *
//*                                                                  *
//*       /tmp/zosmfjcl.py                                           *
//*                                                                  *
//*    The script is then executed using BPXBATCH and Python.        *
//*                                                                  *
//*    The Python script invokes the z/OSMF REST Files API using     *
//*    the command-line arguments supplied to it.                    *
//*                                                                  *
//*    After execution completes, the temporary UNIX script file     *
//*    is removed from the /tmp directory.                           *
//*                                                                  *
//* ARGUMENTS:                                                       *
//*                                                                  *
//*    Argument 1                                                    *
//*       USERID used to authenticate to z/OSMF.                     *
//*                                                                  *
//*    Argument 2                                                    *
//*       Password associated with the USERID.                       *
//*                                                                  *
//*    Argument 3                                                    *
//*       z/OS UNIX path to process.                                 *
//*                                                                  *
//* FORMAT:                                                          *
//*                                                                  *
//*    python /tmp/zosmfjcl.py USERID PASSWORD PATH                  *
//*                                                                  *
//* EXAMPLES:                                                        *
//*                                                                  *
//*    python /tmp/zosmfjcl.py JOVE mypassword /tmp                  *
//*                                                                  *
//*    python /tmp/zosmfjcl.py JOVE mypassword /u/jove               *
//*                                                                  *
//* PROCESSING FLOW:                                                 *
//*                                                                  *
//*    1. Copy PSCRIPT1 to /tmp/zosmfjcl.py.                         *
//*    2. Execute the script using Python.                           *
//*    3. Pass USERID, PASSWORD, and PATH arguments.                 *
//*    4. Invoke the z/OSMF REST Files API.                          *
//*    5. Write results to STDOUT.                                   *
//*    6. Delete the temporary script from /tmp.                     *
//*                                                                  *
//********************************************************************
//*
//ZMFREST1   JOB (1,1),
//             '     ',
//             NOTIFY=&SYSUID,
//             MSGCLASS=A,REGION=0M
//*
//* SYMBOLIC PARAMETERS - override at submit time:
//*   USERID   - z/OSMF userid
//*   PASSWORD - z/OSMF password
//*   PATH     - USS path to process
//*
//         SET USERID=CHANGEME
//         SET PASSWORD=CHANGEME
//         SET PATH=/tmp
//*
//STEP1    EXEC PGM=BPXBATCH
//SYSPRINT DD SYSOUT=*
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//STDPARM DD *
SH
SCRIPTFILE=/tmp/zosmfjcl.py;
trap "rm -f $SCRIPTFILE" EXIT;
cp /u/andre/zosmfjcl.py $SCRIPTFILE;
python $SCRIPTFILE &USERID &PASSWORD &PATH zos31.pok.stglabs.ibm.com
/*
//*
