#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_CHECK
C     !INTERFACE:
      SUBROUTINE POLLUTANT_CHECK( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_CHECK
C     | o Check pollutant package parameters
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"

C     !INPUT/OUTPUT PARAMETERS:
C     myThid     :: my Thread Id number
      INTEGER myThid

C     !LOCAL VARIABLES:
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER errCount
      INTEGER ioUnit
      LOGICAL fileExists
CEOP

#ifdef ALLOW_POLLUTANT

      _BEGIN_MASTER(myThid)

      ioUnit = standardMessageUnit
      WRITE(msgBuf,'(A)') 'POLLUTANT_CHECK:   #define ALLOW_POLLUTANT'
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )

C---  Print summary:
      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)') '// POLLUTANT pkg configuration summary'
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )

      CALL WRITE_0D_C(pollutant_emission_file, -1, INDEX_NONE,
     & 'pollutant_emission_file =', ' pollutant emission input file')
      CALL WRITE_0D_RL(pollutant_forcingPeriod, INDEX_NONE,
     &  'pollutant_forcingPeriod =', 
     &  ' forcing period (s) of input file')
      CALL WRITE_0D_RL(pollutant_forcingCycle, INDEX_NONE,
     &  'pollutant_forcingCycle =', 
     &  ' period of Cycle for input file (s)')
      CALL WRITE_0D_L(usePollutantDecay, INDEX_NONE,
     &  'usePollutantDecay =', ' enable pollutant decay')
      CALL WRITE_0D_L(usePollutantSettling, INDEX_NONE,
     &  'usePollutantSettling =', ' enable pollutant settling')
      CALL WRITE_0D_L(usePollutantBioUptake, INDEX_NONE,
     &  'usePollutantBioUptake =', ' enable pollutant bio-uptake')
      CALL WRITE_0D_RL(pollutant_decay_rate, INDEX_NONE,
     &  'pollutant_decay_rate =', ' pollutant decay rate (1/s)')
      CALL WRITE_0D_RL(pollutant_settle_rate, INDEX_NONE,
     &  'pollutant_settle_rate =', 
     &  ' pollutant settling rate (1/s)')
      CALL WRITE_0D_RL(pollutant_biouptake_rate, INDEX_NONE,
     &  'pollutant_biouptake_rate =', 
     &  ' pollutant bio-uptake rate (1/s)')

      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)') '// End of POLLUTANT pkg config summary'
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )

C---  Check POLLUTANT pkg settings:
      errCount = 0

C     Check rate parameters are non-negative
      IF ( pollutant_decay_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: pollutant_decay_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_settle_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: pollutant_settle_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_biouptake_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: pollutant_biouptake_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

C     Check time step stability
      IF ( pollutant_decay_rate * deltaT .GT. 1. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: decay_rate too large for stability'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_settle_rate * deltaT .GT. 1. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: settle_rate too large for stability'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_biouptake_rate * deltaT .GT. 1. _d 0 ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: biouptake_rate too large for stability'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

C     Check forcing cycle consistency
      IF ( pollutant_forcingCycle.LE.zeroRL .AND.
     &     pollutant_emission_file .NE. ' ' ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: forcingCycle=0 but code to load'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: non periodic forcing is missing'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

C     Check parameter combinations
      IF ( .NOT.usePollutantDecay .AND. .NOT.usePollutantSettling 
     &     .AND. .NOT.usePollutantBioUptake ) THEN
        WRITE(msgBuf,'(A)')
     &       'POLLUTANT_CHECK: All sink processes disabled'
        CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
      ENDIF

C     Check file existence
      IF ( pollutant_emission_file .NE. ' ' ) THEN
        INQUIRE(FILE=pollutant_emission_file, EXIST=fileExists)
        IF (.NOT.fileExists) THEN
          WRITE(msgBuf,'(A)')
     &         'POLLUTANT_CHECK: pollutant_emission_file not found: '
          CALL PRINT_ERROR( msgBuf, myThid )
          WRITE(msgBuf,'(A)') pollutant_emission_file
          CALL PRINT_ERROR( msgBuf, myThid )
          errCount = errCount + 1
        ENDIF
      ENDIF

      IF ( errCount.GE.1 ) THEN
        WRITE(msgBuf,'(A,I3,A)')
     &       'POLLUTANT_CHECK: detected', errCount,' fatal error(s)'
        CALL PRINT_ERROR( msgBuf, myThid )
        CALL ALL_PROC_DIE( 0 )
        STOP 'ABNORMAL END: S/R POLLUTANT_CHECK'
      ENDIF

      WRITE(msgBuf,'(A)') 'POLLUTANT_CHECK: done'
      CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )

      _END_MASTER(myThid)

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
