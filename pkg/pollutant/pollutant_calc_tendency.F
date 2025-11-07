#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_CALC_TENDENCY
C     !INTERFACE:
      SUBROUTINE POLLUTANT_CALC_TENDENCY(
     I                          pTr_Pollutant, theta_arg,
     U                          gPollutant,
     I                          bi, bj, iMin, iMax, jMin, jMax,
     I                          myTime, myIter, myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_CALC_TENDENCY
C     | o Calculate pollutant source and sink terms
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == Global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"
#include "POLLUTANT_FIELDS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"
#include "DYNVARS.h"

C     !INPUT/OUTPUT PARAMETERS:
      _RL  pTr_Pollutant(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  theta_arg(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  gPollutant(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      INTEGER bi, bj
      INTEGER iMin, iMax, jMin, jMax
      _RL  myTime
      INTEGER myIter, myThid

#ifdef ALLOW_POLLUTANT
C     !LOCAL VARIABLES:
      INTEGER i, j, k
      _RL sourceTerm, sinkTerm
      _RL k_total, k_dark_T, k_bio_T, k_photo_z
      _RL temp_factor_dark, temp_factor_bio
      _RL light_factor
      _RL pTr_Pollutant_safe
      _RL denom
CEOP

C     Calculate pollutant tendency terms
      DO j = jMin, jMax
       DO i = iMin, iMax
        DO k = 1, Nr

C        Only process ocean grid points
         IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN

C         Use local variable for concentration, ensuring it's non-negative
          pTr_Pollutant_safe = MAX( 0. _d 0, pTr_Pollutant(i,j,k) )

C--       1. Source term (emission flux at surface)
          sourceTerm = 0. _d 0
          IF ( k.EQ.1 ) THEN
           denom = drF(1) * hFacC(i,j,1,bi,bj)
           IF (denom .GT. 0. _d 0) THEN
             sourceTerm = pollutant_flux(i,j,bi,bj) / denom
           ENDIF
          ENDIF

C--       2. Sink term (degradation)
          sinkTerm = 0. _d 0
          IF ( usePollutantDegradation ) THEN
            k_total = 0. _d 0

C           Only calculate degradation if temperature is above critical temp
            IF ( theta_arg(i,j,k) .GT. pollutant_Tc ) THEN

C             a) Temperature-dependent dark and biological degradation (Q10)
              temp_factor_dark = pollutant_Q10_dark **
     &                         ( (theta_arg(i,j,k) - 20.0 _d 0) / 10.0 _d 0 )
              k_dark_T = pollutant_k_dark_20 * temp_factor_dark

              temp_factor_bio = pollutant_Q10_bio **
     &                        ( (theta_arg(i,j,k) - 20.0 _d 0) / 10.0 _d 0 )
              k_bio_T = pollutant_k_bio_20 * temp_factor_bio

C             b) Depth-dependent direct photolysis (Beer-Lambert law)
              k_photo_z = 0. _d 0
#ifdef ALLOW_EXF
              IF ( pollutant_swdown(i,j,bi,bj) .GT. 0. _d 0 ) THEN
                light_factor = EXP(-pollutant_light_atten * ABS(rC(k)))
                k_photo_z = pollutant_k_photo * light_factor
              ENDIF
#endif

C             c) Sum all rates to get total degradation rate
              k_total = k_dark_T + k_bio_T + pollutant_k_OH + k_photo_z

            ENDIF

C           Calculate total sink term
            sinkTerm = k_total * pTr_Pollutant_safe

          ENDIF

C--       3. Apply tendencies
          gPollutant(i,j,k) = gPollutant(i,j,k)
     &                      + sourceTerm - sinkTerm

C--       4. Final protection to prevent negative concentrations
          IF ( (pTr_Pollutant(i,j,k)
     &         + gPollutant(i,j,k)*deltaTClock)
     &         .LT. 0. _d 0 ) THEN
            gPollutant(i,j,k) = -pTr_Pollutant(i,j,k)
     &                        / deltaTClock
          ENDIF

         ELSE
C         Land grid points - set tendency to zero
          gPollutant(i,j,k) = 0. _d 0
         ENDIF

        ENDDO
       ENDDO
      ENDDO

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
