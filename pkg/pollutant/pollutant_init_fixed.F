#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_INIT_FIXED
C     !INTERFACE:
      SUBROUTINE POLLUTANT_INIT_FIXED( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_INIT_FIXED
C     | o Initialize fixed variables for POLLUTANT package
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myThid    :: My Thread Id. number
      INTEGER myThid
CEOP

#ifdef ALLOW_POLLUTANT

C     !LOCAL VARIABLES:
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER i, j, bi, bj

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)

      WRITE(msgBuf,'(A)') 'POLLUTANT_INIT_FIXED: initializing POLLUTANT'
      CALL PRINT_MESSAGE(msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

C     Initialize pollutant fields to zero (all threads)
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
          pollutant_flux(i,j,bi,bj) = 0. _d 0
          pollutant_flux0(i,j,bi,bj) = 0. _d 0
          pollutant_flux1(i,j,bi,bj) = 0. _d 0
         ENDDO
        ENDDO
        pollutant_ldRec(bi,bj) = 0
       ENDDO
      ENDDO

#ifdef ALLOW_TIMEAVE
C     Initialize time-averaging arrays
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        CALL TIMEAVE_RESET(sourceAve,   Nr,  bi, bj, myThid)
        CALL TIMEAVE_RESET(sinkAve,     Nr,  bi, bj, myThid)
        POLLUTANT_timeAve(bi,bj) = 0. _d 0
       ENDDO
      ENDDO
#endif /* ALLOW_TIMEAVE */

#ifdef ALLOW_DIAGNOSTICS
C     Diagnostics initialization is handled by GCHEM_DIAGNOSTICS_INIT
#endif /* ALLOW_DIAGNOSTICS */


#endif /* ALLOW_POLLUTANT */

      RETURN
      END
