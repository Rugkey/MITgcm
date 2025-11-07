#include "GCHEM_OPTIONS.h"

CBOP
C !ROUTINE: GCHEM_CALC_TENDENCY

C !INTERFACE: ==========================================================
      SUBROUTINE GCHEM_CALC_TENDENCY(
     I     myTime, myIter, myThid )

C !DESCRIPTION:
C Computes tracer tendencies due to biogeochemistry.

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"
#include "GCHEM.h"
#include "GCHEM_SIZE.h"
#include "GCHEM_FIELDS.h"
#ifdef ALLOW_POLLUTANT
# include "POLLUTANT_SIZE.h"
#endif

C !INPUT PARAMETERS: ===================================================
C  myTime               :: current time
C  myIter               :: current timestep
C  myThid               :: thread number
      _RL myTime
      INTEGER myIter, myThid
CEOP

#ifdef GCHEM_ADD2TR_TENDENCY
C !LOCAL VARIABLES: ====================================================
      INTEGER i,j,k
      INTEGER iTr, jTr
      INTEGER bi,bj,iMin,iMax,jMin,jMax

C     Initialize gchemTendency
      DO jTr = 1, GCHEM_tendTr_num
       DO bj=myByLo(myThid),myByHi(myThid)
        DO bi=myBxLo(myThid),myBxHi(myThid)
         DO k = 1, Nr
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
            gchemTendency(i,j,k,bi,bj,jTr) = 0. _d 0
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDDO

      IF ( useGCHEM ) THEN

C     Loop over tiles
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)
        iMin = 1
        iMax = sNx
        jMin = 1
        jMax = sNy

#ifdef ALLOW_POLLUTANT
        IF ( usePOLLUTANT ) THEN
         iTr = POLLUTANT_pTr_i1

C--      Robust negative concentration fix-up for pollutant tracer
C        This ensures that any negative values from the advection scheme
C        are corrected before being passed to the source-sink calculation.
         DO k = 1, Nr
          DO j = jMin, jMax
           DO i = iMin, iMax
            pTracer(i,j,k,bi,bj,iTr) = MAX(0. _d 0,
     &           pTracer(i,j,k,bi,bj,iTr))
           ENDDO
          ENDDO
         ENDDO

         jTr = iTr - gchem_sepFTr_num
         CALL POLLUTANT_CALC_TENDENCY(
     I                       pTracer(1-OLx,1-OLy,1,bi,bj,iTr),
     I                       theta(1-OLx,1-OLy,1,bi,bj),
     U                       gchemTendency(1-OLx,1-OLy,1,bi,bj,jTr),
     I                       bi, bj, iMin, iMax, jMin, jMax,
     I                       myTime, myIter, myThid )
        ENDIF
#endif /* ALLOW_POLLUTANT */

       ENDDO
      ENDDO
      ENDIF

#endif /* GCHEM_ADD2TR_TENDENCY */

      RETURN
      END
