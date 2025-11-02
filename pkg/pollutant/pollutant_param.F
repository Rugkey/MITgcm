#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_PARAM
C     !INTERFACE:
      SUBROUTINE POLLUTANT_PARAM( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_PARAM
C     | o This routine used to set default parameters for the
C     | o pollutant package. This is now handled in
C     | o POLLUTANT_READPARMS.
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"

C     == Routine arguments ==
C     myThid -  Number of this instance of POLLUTANT_PARAM
      INTEGER myThid
CEOP

#ifdef ALLOW_POLLUTANT

C     This subroutine is kept for structural consistency but the parameter
C     initialization has been moved to POLLUTANT_READPARMS to support
C     half-life inputs.

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
