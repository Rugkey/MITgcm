#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_DIAGNOSTICS_INIT
C     !INTERFACE:
      SUBROUTINE POLLUTANT_DIAGNOSTICS_INIT( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_DIAGNOSTICS_INIT
C     | o Initialize diagnostics for POLLUTANT package
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"

C     !INPUT/OUTPUT PARAMETERS:
C     myThid     :: my Thread Id number
      INTEGER myThid

C     !LOCAL VARIABLES:
      INTEGER       diagNum
      CHARACTER*8   diagName
      CHARACTER*16  diagCode
      CHARACTER*16  diagUnits
      CHARACTER*(80) diagTitle
CEOP

#ifdef ALLOW_DIAGNOSTICS
#ifdef ALLOW_POLLUTANT

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Define diagnostics Names :

      diagName  = 'EDC_SRC '
      diagTitle = 'Pollutant Source Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'EDC_SINK'
      diagTitle = 'Pollutant Sink Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'EDC_DECAY'
      diagTitle = 'Pollutant Decay Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'EDC_SETTLE'
      diagTitle = 'Pollutant Settling Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'EDC_BIOUP'
      diagTitle = 'Pollutant Bio-uptake Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'EDC_TOTAL'
      diagTitle = 'Pollutant Total Tendency (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#endif /* ALLOW_POLLUTANT */
#endif /* ALLOW_DIAGNOSTICS */

      RETURN
      END
