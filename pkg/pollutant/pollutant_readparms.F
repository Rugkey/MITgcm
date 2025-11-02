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
     &          usePollutantDecay,
     &          usePollutantSettling,
     &          usePollutantBioUptake,
     &          pollutant_fluxIsCellTotal,
     &          useTempDependentDecay,
     &          useDepthDependentDecay,
     &          pollutant_decay_halflife_d,
     &          pollutant_settle_halflife_d,
     &          pollutant_biouptake_halflife_d,
     &          pollutant_forcingPeriod,
     &          pollutant_forcingCycle,

     &          decayTempRef,
     &          decayQ10,
     &          decayDepthScale,
     &          pollutant_emission_file

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)
       errCount = 0

C--   Set default values
       usePollutantDecay       = .FALSE.
       usePollutantSettling    = .FALSE.
       usePollutantBioUptake   = .FALSE.
       pollutant_fluxIsCellTotal = .FALSE.
       useTempDependentDecay   = .FALSE.
       useDepthDependentDecay  = .FALSE.

       pollutant_decay_halflife_d     = 0. _d 0
       pollutant_settle_halflife_d    = 0. _d 0
       pollutant_biouptake_halflife_d = 0. _d 0

       pollutant_forcingPeriod = externForcingPeriod
       pollutant_forcingCycle  = externForcingCycle
       decayTempRef            = 20. _d 0
       decayQ10                = 2.0 _d 0
       decayDepthScale         = 50. _d 0

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

C--   Convert half-lives (days) to rate constants (1/s)
C     k = ln(2) / T_half
      LOG_2 = 0.69314718056 _d 0
      SECONDS_PER_DAY = 86400. _d 0

      IF ( pollutant_decay_halflife_d .GT. 0. _d 0 ) THEN
        pollutant_decay_rate = LOG_2 /
     &     ( pollutant_decay_halflife_d * SECONDS_PER_DAY )
      ELSE
        pollutant_decay_rate = 0. _d 0
      ENDIF

      IF ( pollutant_settle_halflife_d .GT. 0. _d 0 ) THEN
        pollutant_settle_rate = LOG_2 /
     &     ( pollutant_settle_halflife_d * SECONDS_PER_DAY )
      ELSE
        pollutant_settle_rate = 0. _d 0
      ENDIF

      IF ( pollutant_biouptake_halflife_d .GT. 0. _d 0 ) THEN
        pollutant_biouptake_rate = LOG_2 /
     &     ( pollutant_biouptake_halflife_d * SECONDS_PER_DAY )
      ELSE
        pollutant_biouptake_rate = 0. _d 0
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Parameter validation
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( pollutant_decay_halflife_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_decay_halflife_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_settle_halflife_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_settle_halflife_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_biouptake_halflife_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_biouptake_halflife_d must be >= 0'
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

      CALL WRITE_0D_L( usePollutantDecay, INDEX_NONE,
     &  'usePollutantDecay =',
     &  '  /* .TRUE. to enable pollutant decay */')
      IF (usePollutantDecay) THEN
        CALL WRITE_0D_RL( pollutant_decay_halflife_d, INDEX_NONE,
     &    'pollutant_decay_halflife_d =',
     &    ' /* Half-life for decay [days] */')
      ENDIF

      CALL WRITE_0D_L( usePollutantSettling, INDEX_NONE,
     &  'usePollutantSettling =',
     &  '  /* .TRUE. to enable phase change */')
      IF (usePollutantSettling) THEN
        CALL WRITE_0D_RL( pollutant_settle_halflife_d, INDEX_NONE,
     &    'pollutant_settle_halflife_d =',
     &    ' /* Half-life for phase change [days] */')
      ENDIF

      CALL WRITE_0D_L( usePollutantBioUptake, INDEX_NONE,
     &  'usePollutantBioUptake =',
     &  '  /* .TRUE. to enable pollutant bio-uptake */')
      IF (usePollutantBioUptake) THEN
        CALL WRITE_0D_RL( pollutant_biouptake_halflife_d, INDEX_NONE,
     &    'pollutant_biouptake_halflife_d =',
     &    ' /* Half-life for bio-uptake [days] */')
      ENDIF

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
