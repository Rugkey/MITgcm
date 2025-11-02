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
      _RL decayTerm, settleTerm, bioupTerm
      _RL local_decay_rate, temp_factor, depth_factor
      _RL pTr_Pollutant_safe, mass
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

C--       2. Sink terms (decay, settling/phase-change, bio-uptake)
          decayTerm = 0. _d 0
          IF ( usePollutantDecay ) THEN
            local_decay_rate = pollutant_decay_rate
            IF ( useTempDependentDecay ) THEN
              temp_factor = decayQ10 ** ((theta_arg(i,j,k)
     &                                   - decayTempRef) / 10.0 _d 0)
              local_decay_rate = local_decay_rate * temp_factor
            ENDIF
            IF ( useDepthDependentDecay ) THEN
              depth_factor = EXP( rC(k) / decayDepthScale )
              local_decay_rate = local_decay_rate * depth_factor
            ENDIF
            decayTerm = local_decay_rate * pTr_Pollutant_safe
          ENDIF

          settleTerm = 0. _d 0
          IF ( usePollutantSettling ) THEN
            settleTerm = pollutant_settle_rate * pTr_Pollutant_safe
          ENDIF

          bioupTerm = 0. _d 0
          IF ( usePollutantBioUptake ) THEN
            bioupTerm = pollutant_biouptake_rate * pTr_Pollutant_safe
          ENDIF

          sinkTerm = decayTerm + settleTerm + bioupTerm

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
