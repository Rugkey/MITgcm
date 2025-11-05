C $Header: /u/gcmpack/MITgcm/pkg/MICROP/MICROP_readparms.F,v 1.2 2008/04/09 16:07:41 jmc Exp $
C $Name: checkpoint64g $

#include "GCHEM_OPTIONS.h"
#include "MICROP_OPTIONS.h"

CBOP
C !ROUTINE: MICROP_READPARMS
C !INTERFACE: ==========================================================
      SUBROUTINE MICROP_READPARMS( myThid )

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | S/R MICROP_READPARMS
C     | o Initialise and read MICROP package parameters
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "MICROP_SIZE.h"
#include "MICROP.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myThid    :: My Thread Id. number
      INTEGER myThid
CEOP

#ifdef ALLOW_MICROP

C     === Local variables ===
C     msgBuf    :: Informational/error message buffer
C     iUnit     :: Work variable for IO unit number
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      NAMELIST /MICROP_FORCING/
     &          MICROP_forcingPeriod, MICROP_forcingCycle,
     &          MICROP_chemPeriod, MICROP_chemCycle,
     &          MICROP_riverFile

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)

       MICROP_riverFile= ' '

c air-sea exchange: default periodic forcing to same as for physics
       MICROP_forcingPeriod = externForcingPeriod
       MICROP_forcingCycle  = externForcingCycle
	   
c MICROP chemistry: default periodic forcing to same as for physics
       MICROP_chemPeriod = externForcingPeriod
       MICROP_chemCycle  = externForcingCycle

      WRITE(msgBuf,'(A)') ' MICROP_READPARMS: opening data.microp'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE( 'data.microp', 'MICROP_READPARMS',
     O                          iUnit, myThid )

C--   Read parameters from open data file:

C-    forcing filenames and parameters
      READ(UNIT=iUnit,NML=MICROP_FORCING)

      WRITE(msgBuf,'(A)')
     &   ' MICROP_READPARMS: finished reading data.microp'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

C--   Close the open data file
      CLOSE(iUnit)

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#endif /* ALLOW_MICROP */

      RETURN
      END
