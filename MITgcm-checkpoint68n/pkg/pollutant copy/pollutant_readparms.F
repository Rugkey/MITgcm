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
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit

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

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
