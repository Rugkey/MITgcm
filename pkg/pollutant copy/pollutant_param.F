#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_PARAM
C     !INTERFACE:
      SUBROUTINE POLLUTANT_PARAM( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_PARAM
C     | o Set parameters needed for POLLUTANT runs
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

C     == Local variables ==

      _BEGIN_MASTER( myThid )

C     Set default pollutant parameters
C     These can be overridden by data.pollutant file
      pollutant_decay_rate = 1.0 _d -7
      pollutant_settle_rate = 5.0 _d -8
      pollutant_biouptake_rate = 2.0 _d -8

      _END_MASTER( myThid )

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
