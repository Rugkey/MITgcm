#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_CALC_TENDENCY
C     !INTERFACE:
      SUBROUTINE POLLUTANT_CALC_TENDENCY(
     I                          pTr_Pollutant,
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

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#ifdef ALLOW_OBCS
#include "OBCS.h"
#endif

C     !INPUT/OUTPUT PARAMETERS:
C     pTr_Pollutant :: ocean pollutant concentration
C     gPollutant    :: pollutant tendency
C     bi, bj        :: current tile indices
C     iMin,iMax     :: computation domain, 1rst index bounds
C     jMin,jMax     :: computation domain, 2nd  index bounds
C     myTime        :: current time in simulation
C     myIter        :: current iteration number
C     myThid        :: my Thread Id number
      _RL  pTr_Pollutant((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL  gPollutant((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      INTEGER bi, bj
      INTEGER iMin, iMax, jMin, jMax
      _RL  myTime
      INTEGER myIter, myThid

C     !LOCAL VARIABLES:
      INTEGER i, j, k
      _RL sourceTerm, sinkTerm
      _RL sourceDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL sinkDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL decayDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL settleDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL bioupDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL totalDiag((1-OLx):(sNx+OLx),(1-OLy):(sNy+OLy),Nr)
      _RL pTr_Pollutant_safe
      _RL prevFlux, curFlux, settleTend, wSettle
      _RL volTop, denom
CEOP

#ifdef ALLOW_POLLUTANT

C     Initialize diagnostic arrays
      DO k = 1, Nr
       DO j = (1-OLy), (sNy+OLy)
        DO i = (1-OLx), (sNx+OLx)
         sourceDiag(i,j,k) = 0. _d 0
         sinkDiag(i,j,k) = 0. _d 0
         decayDiag(i,j,k) = 0. _d 0
         settleDiag(i,j,k) = 0. _d 0
         bioupDiag(i,j,k) = 0. _d 0
         totalDiag(i,j,k) = 0. _d 0
        ENDDO
       ENDDO
      ENDDO

C     Calculate pollutant tendency terms (with volume-consistent source and
C     mass-conserving settling as vertical flux divergence)
      DO j = jMin, jMax
       DO i = iMin, iMax

C       Initialize vertical settling flux at top interface (k=1/2)
        prevFlux = 0. _d 0

        DO k = 1, Nr

C        Only process ocean grid points (land mask protection)
         IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN

C         Apply concentration protection to local variable (don't modify tracer)
          pTr_Pollutant_safe = MAX( 0. _d 0, pTr_Pollutant(i,j,k) )

C         Source term (only for surface layer), strictly volume-normalized
          IF ( k.EQ.1 ) THEN
           denom = DBLE(drF(1))
     &            * MAX( DBLE(hFacC(i,j,1,bi,bj)), 1.0D-12 )
           sourceTerm = pollutant_flux(i,j,bi,bj) / denom
          ELSE
           sourceTerm = 0. _d 0
          ENDIF

C         Linear sinks (explicit): decay and bio-uptake
          sinkTerm = 0. _d 0
          IF ( usePollutantDecay ) THEN
           sinkTerm = sinkTerm + pollutant_decay_rate
           IF ( pTr_Pollutant_safe .GT. 0. _d 0 ) THEN
            decayDiag(i,j,k) = pollutant_decay_rate
     &                        * pTr_Pollutant_safe
           ELSE
            decayDiag(i,j,k) = 0. _d 0
           ENDIF
          ELSE
           decayDiag(i,j,k) = 0. _d 0
          ENDIF

          IF ( usePollutantBioUptake ) THEN
           sinkTerm = sinkTerm + pollutant_biouptake_rate
           IF ( pTr_Pollutant_safe .GT. 0. _d 0 ) THEN
            bioupDiag(i,j,k) = pollutant_biouptake_rate
     &                        * pTr_Pollutant_safe
           ELSE
            bioupDiag(i,j,k) = 0. _d 0
           ENDIF
          ELSE
           bioupDiag(i,j,k) = 0. _d 0
          ENDIF

C         Settling as vertical flux divergence (downward positive)
C         use previously-declared curFlux, settleTend, wSettle
          IF ( usePollutantSettling ) THEN
C          Use layer-dependent equivalent velocity (m/s): w = rate(1/s)*drF(m)
           wSettle = pollutant_settle_rate * drF(k)
C          Upwind with downward velocity: interface flux at k+1/2 uses C_k
           curFlux = wSettle * pTr_Pollutant_safe
C          Tendency from settling: -dF/dz over wet thickness
           denom = DBLE(drF(k))
     &             * MAX( DBLE(hFacC(i,j,k,bi,bj)), 1.0D-12 )
           settleTend = -( curFlux - prevFlux ) / denom
          ELSE
           curFlux   = 0. _d 0
           settleTend= 0. _d 0
          ENDIF

C         Store diagnostics
          sourceDiag(i,j,k) = sourceTerm
          IF ( pTr_Pollutant_safe .GT. 0. _d 0 ) THEN
           sinkDiag(i,j,k) = sinkTerm * pTr_Pollutant_safe
          ELSE
           sinkDiag(i,j,k) = 0. _d 0
          ENDIF
          settleDiag(i,j,k) = settleTend

C         Apply source, settling and sink terms to tracer tendency
          gPollutant(i,j,k) = gPollutant(i,j,k) + sourceTerm
          gPollutant(i,j,k) = gPollutant(i,j,k) + settleTend
          IF ( pTr_Pollutant_safe .GT. 0. _d 0 ) THEN
           gPollutant(i,j,k) = gPollutant(i,j,k)
     &                        - sinkTerm * pTr_Pollutant_safe
          ENDIF

C         Total tendency for diagnostics
          totalDiag(i,j,k) = sourceTerm + settleTend - sinkDiag(i,j,k)

C         Final protection: ensure tendency won't make tracer negative
          IF ( pTr_Pollutant(i,j,k) + gPollutant(i,j,k)
     &         .LT. 0. _d 0 ) THEN
           gPollutant(i,j,k) = -pTr_Pollutant(i,j,k)
          ENDIF

C         Update prevFlux for next layer
          prevFlux = curFlux

         ELSE
C        Land grid points - set tendency and diags to zero
          sourceDiag(i,j,k) = 0. _d 0
          sinkDiag(i,j,k) = 0. _d 0
          settleDiag(i,j,k) = 0. _d 0
          totalDiag(i,j,k) = 0. _d 0
          gPollutant(i,j,k) = 0. _d 0
         ENDIF

        ENDDO
       ENDDO
      ENDDO

C     Apply boundary conditions
#ifdef ALLOW_OBCS
      IF ( useOBCS ) THEN
       DO k=1,Nr
        DO j=jMin,jMax
         DO i=iMin,iMax
          gPollutant(i,j,k) = gPollutant(i,j,k)*maskInC(i,j,bi,bj)
         ENDDO
        ENDDO
       ENDDO
      ENDIF
#endif

C     Fill diagnostics
#ifdef ALLOW_DIAGNOSTICS
      CALL DIAGNOSTICS_FILL(sourceDiag,'EDC_SRC ',0,Nr,2,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(sinkDiag,'EDC_SINK',0,Nr,2,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(decayDiag,'EDC_DECAY',0,Nr,2,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(settleDiag,'EDC_SETTLE',0,Nr,2,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(bioupDiag,'EDC_BIOUP',0,Nr,2,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(totalDiag,'EDC_TOTAL',0,Nr,2,bi,bj,myThid)
      
C     Fill additional diagnostics
      CALL DIAGNOSTICS_FILL(pollutant_flux,'EDC_FLUX ',
     &                      0,1,1,bi,bj,myThid)
      CALL DIAGNOSTICS_FILL(pTr_Pollutant,'EDC_CONC ',
     &                      0,Nr,2,bi,bj,myThid)
      
C     Calculate and fill mass diagnostic
      DO k=1,Nr
       DO j=jMin,jMax
        DO i=iMin,iMax
         pollutant_mass(i,j,k,bi,bj) = pTr_Pollutant(i,j,k) * 
     &                                  rA(i,j,bi,bj) * drF(k) * 
     &                                  hFacC(i,j,k,bi,bj)
        ENDDO
       ENDDO
      ENDDO
      CALL DIAGNOSTICS_FILL(pollutant_mass,'EDC_MASS ',
     &                      0,Nr,2,bi,bj,myThid)
#endif

#ifdef ALLOW_TIMEAVE
C     Accumulate time-averaging data
      IF ( PTRACERS_taveFreq.GT.0. ) THEN
       DO k=1,Nr
        DO j=jMin,jMax
         DO i=iMin,iMax
          sourceAve(i,j,k,bi,bj) = sourceAve(i,j,k,bi,bj) +
     &                             sourceDiag(i,j,k)*deltaTClock
          sinkAve(i,j,k,bi,bj) = sinkAve(i,j,k,bi,bj) +
     &                             sinkDiag(i,j,k)*deltaTClock
          decayAve(i,j,k,bi,bj) = decayAve(i,j,k,bi,bj) +
     &                             decayDiag(i,j,k)*deltaTClock
          settlingAve(i,j,k,bi,bj) = settlingAve(i,j,k,bi,bj) +
     &                             settleDiag(i,j,k)*deltaTClock
          bioUptakeAve(i,j,k,bi,bj) = bioUptakeAve(i,j,k,bi,bj) +
     &                             bioupDiag(i,j,k)*deltaTClock
         ENDDO
        ENDDO
       ENDDO
       POLLUTANT_timeAve(bi,bj) = POLLUTANT_timeAve(bi,bj) + deltaTClock
      ENDIF
#endif /* ALLOW_TIMEAVE */

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
