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
C     msgBuf    :: Informational/error message buffer
C     iUnit     :: Work variable for IO unit number
C     errCount  :: error counter
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit
      INTEGER errCount

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      NAMELIST /POLLUTANT_FORCING/
     &          pollutant_emission_file,
     &          pollutant_forcingPeriod, pollutant_forcingCycle

      NAMELIST /POLLUTANT_PARAMS_L/
     &          usePollutantDecay,
     &          usePollutantSettling,
     &          usePollutantBioUptake,
     &          usePollutantAdvection,
     &          usePollutantDiffusion

      NAMELIST /POLLUTANT_PARAMS_R/
     &          pollutant_decay_rate,
     &          pollutant_settle_rate,
     &          pollutant_biouptake_rate,
     &          pollutant_monFreq

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)
       errCount = 0

C     Set default values
       pollutant_emission_file = 'pollutant_emission.bin'
       pollutant_forcingPeriod = externForcingPeriod
       pollutant_forcingCycle = externForcingCycle
       usePollutantDecay = .FALSE.
       usePollutantSettling = .FALSE.
       usePollutantBioUptake = .FALSE.
       usePollutantAdvection = .TRUE.
       usePollutantDiffusion = .TRUE.
       pollutant_decay_rate = 0. _d 0
       pollutant_settle_rate = 0. _d 0
       pollutant_biouptake_rate = 0. _d 0
       pollutant_monFreq = 86400. _d 0

      WRITE(msgBuf,'(A)') ' POLLUTANT_READPARMS: opening data.pollutant'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE( 'data.pollutant', 'POLLUTANT_READPARMS',
     O                          iUnit, myThid )

C--   Read parameters from open data file:
      READ(UNIT=iUnit,NML=POLLUTANT_FORCING)
      READ(UNIT=iUnit,NML=POLLUTANT_PARAMS_L)
      READ(UNIT=iUnit,NML=POLLUTANT_PARAMS_R)

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

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Parameter validation
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C--   Validate forcing parameters
      IF ( pollutant_forcingCycle .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_forcingCycle must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF
      
      IF ( pollutant_forcingPeriod .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_forcingPeriod must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF
      
      IF ( pollutant_forcingCycle .GT. 0. _d 0 .AND.
     &     pollutant_forcingPeriod .GT. 0. _d 0 ) THEN
        IF ( MOD(pollutant_forcingCycle, pollutant_forcingPeriod) 
     &       .NE. 0. _d 0 ) THEN
          WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_forcingCycle must be 
     &       multiple of pollutant_forcingPeriod'
          CALL PRINT_ERROR( msgBuf, myThid )
          errCount = errCount + 1
        ENDIF
      ENDIF

C--   Validate rate parameters
      IF ( pollutant_decay_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_decay_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF
      
      IF ( pollutant_settle_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_settle_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF
      
      IF ( pollutant_biouptake_rate .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_biouptake_rate must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

C--   Validate monitor frequency
      IF ( pollutant_monFreq .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_monFreq must be >= 0'
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

C- namelist POLLUTANT_FORCING
      CALL WRITE_0D_C( pollutant_emission_file, -1, INDEX_NONE, 
     &  'pollutant_emission_file =',
     & '  /* File name of pollutant emission flux */')
      CALL WRITE_0D_RL( pollutant_forcingPeriod,
     &   INDEX_NONE,'pollutant_forcingPeriod =',
     &  ' /* Periodic forcing parameter for POLLUTANT (s) */')
      CALL WRITE_0D_RL( pollutant_forcingCycle,
     &   INDEX_NONE,'pollutant_forcingCycle =',
     &  ' /* Periodic forcing parameter for POLLUTANT (s) */')

C- namelist POLLUTANT_PARAMS_L
      CALL WRITE_0D_L( usePollutantDecay, INDEX_NONE,
     &  'usePollutantDecay =',
     &  '  /* Flag for pollutant decay process */')
      CALL WRITE_0D_L( usePollutantSettling, INDEX_NONE,
     &  'usePollutantSettling =',
     &  '  /* Flag for pollutant settling process */')
      CALL WRITE_0D_L( usePollutantBioUptake, INDEX_NONE,
     &  'usePollutantBioUptake =',
     &  '  /* Flag for pollutant bio-uptake process */')
      CALL WRITE_0D_L( usePollutantAdvection, INDEX_NONE,
     &  'usePollutantAdvection =',
     &  '  /* Flag for pollutant advection (PTRACERS) */')
      CALL WRITE_0D_L( usePollutantDiffusion, INDEX_NONE,
     &  'usePollutantDiffusion =',
     &  '  /* Flag for pollutant diffusion (PTRACERS) */')

C- namelist POLLUTANT_PARAMS_R
      CALL WRITE_0D_RL( pollutant_decay_rate, INDEX_NONE,
     &  'pollutant_decay_rate =',
     &  ' /* Pollutant decay rate constant (1/s) */')
      CALL WRITE_0D_RL( pollutant_settle_rate, INDEX_NONE,
     &  'pollutant_settle_rate =',
     &  ' /* Pollutant settling rate constant (1/s) */')
      CALL WRITE_0D_RL( pollutant_biouptake_rate, INDEX_NONE,
     &  'pollutant_biouptake_rate =',
     &  ' /* Pollutant bio-uptake rate constant (1/s) */')
      CALL WRITE_0D_RL( pollutant_monFreq, INDEX_NONE,
     &  'pollutant_monFreq =',
     &  ' /* Frequency for pollutant monitor (s) */')

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
