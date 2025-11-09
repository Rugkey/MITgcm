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
      INTEGER myThid

C     !LOCAL VARIABLES:
      INTEGER       diagNum
      CHARACTER*8   diagName
      CHARACTER*16  diagCode
      CHARACTER*16  diagUnits
      CHARACTER*(80) diagTitle
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

#ifdef ALLOW_DIAGNOSTICS
#ifdef ALLOW_POLLUTANT

      WRITE(msgBuf,'(A)') 'POLLUTANT_DIAGNOSTICS_INIT:'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      diagName  = 'POLLUT_S'
      diagTitle = 'Pollutant Source Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLLUT_K'
      diagTitle = 'Pollutant Sink Term (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLLUT_T'
      diagTitle = 'Pollutant Total Tendency (mol/m3/s)'
      diagUnits = 'mol/m3/sec      '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLLUT_F'
      diagTitle = 'Pollutant Surface Flux (mol/m2/s)'
      diagUnits = 'mol/m2/sec      '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLLUT_M'
      diagTitle = 'Pollutant Mass per Grid Cell (mol)'
      diagUnits = 'mol             '
      diagCode  = 'SMRP    MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLSURF '
      diagTitle = 'Surface Pollutant Concentration (mol/m3)'
      diagUnits = 'mol/m3          '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLGMASS'
      diagTitle = 'Global Pollutant Inventory (mol)'
      diagUnits = 'mol             '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLGSRC '
      diagTitle = 'Global Pollutant Source (mol/s)'
      diagUnits = 'mol/s           '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLGSNK '
      diagTitle = 'Global Pollutant Sink (mol/s)'
      diagUnits = 'mol/s           '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLCSRC '
      diagTitle = 'Cumulative Pollutant Source (mol)'
      diagUnits = 'mol             '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

      diagName  = 'POLCSNK '
      diagTitle = 'Cumulative Pollutant Sink (mol)'
      diagUnits = 'mol             '
      diagCode  = 'SM      MR      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I       diagName, diagCode, diagUnits, diagTitle, 0, myThid )

#endif /* ALLOW_POLLUTANT */
#endif /* ALLOW_DIAGNOSTICS */

      RETURN
      END
