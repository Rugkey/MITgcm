#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_READPARMS
C     !INTERFACE:
      SUBROUTINE POLLUTANT_READPARMS( myThid )

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | S/R POLLUTANT_READPARMS
C     | o Initialise and read pollutant package parameters
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myThid    :: My Thread Id. number
      INTEGER myThid
CEOP

#ifdef ALLOW_POLLUTANT

C     === Local variables ===
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit
      INTEGER errCount
      _RL     LOG_2
      _RL     SECONDS_PER_DAY

C--   Namelist for pollutant package parameters
      NAMELIST /POLLUTANT_PARAMS/
     &          usePollutantDegradation,
     &          pollutant_fluxIsCellTotal,
     &          pollutant_forcingPeriod,
     &          pollutant_forcingCycle,
     &          pollutant_emission_file,
     &          pollutant_Tc,
     &          pollutant_k1_deg_20_d,
     &          pollutant_kt_deg,
     &          pollutant_fr_deg,
     &          pollutant_k0_deg_d

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)
       errCount = 0

C--   Set default values
       usePollutantDegradation = .FALSE.
       pollutant_fluxIsCellTotal = .FALSE.

       pollutant_forcingPeriod = externForcingPeriod
       pollutant_forcingCycle  = externForcingCycle

       pollutant_Tc            = 0. _d 0
       pollutant_k1_deg_20_d   = 0. _d 0
       pollutant_kt_deg        = 1.047 _d 0
       pollutant_fr_deg        = 1.0 _d 0
       pollutant_k0_deg_d      = 0. _d 0

       pollutant_emission_file = 'pollutant_emission.bin'

      WRITE(msgBuf,'(A)') ' POLLUTANT_READPARMS: opening data.pollutant'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE( 'data.pollutant', 'POLLUTANT_READPARMS',
     O                          iUnit, myThid )

C--   Read parameters from open data file:
      READ(UNIT=iUnit,NML=POLLUTANT_PARAMS)

      WRITE(msgBuf,'(A)')
     &   ' POLLUTANT_READPARMS: finished reading data.pollutant'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

C--   Close the open data file
#ifdef SINGLE_DISK_IO
      CLOSE(iUnit)
#else
      CLOSE(iUnit,STATUS='DELETE')
#endif /* SINGLE_DISK_IO */

C--   Convert degradation rate from d^-1 to s^-1
      SECONDS_PER_DAY = 86400. _d 0

      IF ( pollutant_k1_deg_20_d .GT. 0. _d 0 ) THEN
        pollutant_k1_deg_20 = pollutant_k1_deg_20_d / SECONDS_PER_DAY
      ELSE
        pollutant_k1_deg_20 = 0. _d 0
      ENDIF

      IF ( pollutant_k0_deg_d .GT. 0. _d 0 ) THEN
        pollutant_k0_deg = pollutant_k0_deg_d / SECONDS_PER_DAY
      ELSE
        pollutant_k0_deg = 0. _d 0
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Parameter validation
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( pollutant_k1_deg_20_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k1_deg_20_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_k0_deg_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k0_deg_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_fr_deg .LT. 0. _d 0 .OR.
     &     pollutant_fr_deg .GT. 1. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_fr_deg must be between 0 and 1'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

C--   Check for fatal errors
      IF ( errCount.GE.1 ) THEN
        WRITE(msgBuf,'(A,I3,A)')
     &       'POLLUTANT_READPARMS: detected', errCount,' fatal error(s)'
        CALL PRINT_ERROR( msgBuf, myThid )
        CALL ALL_PROC_DIE( 0 )
        STOP 'ABNORMAL END: S/R POLLUTANT_READPARMS'
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Print out parameter values
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      iUnit = standardMessageUnit
      WRITE(msgBuf,'(A)') ' '
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// POLLUTANT package parameters :'
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)

      CALL WRITE_0D_L( usePollutantDegradation, INDEX_NONE,
     &  'usePollutantDegradation =',
     &  '  /* .TRUE. to enable pollutant degradation */')
      IF (usePollutantDegradation) THEN
        CALL WRITE_0D_RL( pollutant_Tc, INDEX_NONE,
     &    'pollutant_Tc =',
     &    ' /* Critical temperature for degradation [degC] */')
        CALL WRITE_0D_RL( pollutant_k1_deg_20_d, INDEX_NONE,
     &    'pollutant_k1_deg_20_d =',
     &    ' /* 1st-order degradation rate at 20C [d^-1] */')
        CALL WRITE_0D_RL( pollutant_kt_deg, INDEX_NONE,
     &    'pollutant_kt_deg =',
     &    ' /* Temperature coefficient for degradation */')
        CALL WRITE_0D_RL( pollutant_fr_deg, INDEX_NONE,
     &    'pollutant_fr_deg =',
     &    ' /* Fraction subject to degradation */')
        CALL WRITE_0D_RL( pollutant_k0_deg_d, INDEX_NONE,
     &    'pollutant_k0_deg_d =',
     &    ' /* 0th-order degradation rate [g m-3 d-1] */')
      ENDIF

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
