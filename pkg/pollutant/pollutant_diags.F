#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

C !INTERFACE: ==========================================================
      SUBROUTINE POLLUTANT_DIAGS(
     I                           myTime, myIter, myThid )
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_DIAGS
C     | o Only trigger diagnostics package to write outputs.
C     |   All pollutant diagnostic filling is done in
C     |   pollutant_calc_tendency.F each time-step.
C     *==========================================================*
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"

C     == Routine arguments ==
      _RL     myTime
      INTEGER myIter
      INTEGER myThid

#if (defined (ALLOW_DIAGNOSTICS) && defined (ALLOW_POLLUTANT))

C     == Local variables ==
      INTEGER i,j,k,bi,bj
      INTEGER iMin,iMax,jMin,jMax
      _RL sourceTerm
      _RL decayTerm, settleTerm, bioupTerm, sinkTerm
      _RL local_decay_rate, temp_factor, depth_factor
      _RL conc
      _RL denom

C     Work arrays for block diagnostics fill
      _RL sourceDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL sinkDiag  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL decayDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL settleDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL bioupDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL totalDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL massDiag  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)

      iMin = 1
      iMax = sNx
      jMin = 1
      jMax = sNy

C--   Loop tiles and build diagnostics arrays
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)

C      zero work arrays for this tile (including overlap)
        DO k = 1, Nr
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           sourceDiag(i,j,k) = 0. _d 0
           sinkDiag  (i,j,k) = 0. _d 0
           decayDiag (i,j,k) = 0. _d 0
           settleDiag(i,j,k) = 0. _d 0
           bioupDiag (i,j,k) = 0. _d 0
           totalDiag (i,j,k) = 0. _d 0
           massDiag  (i,j,k) = 0. _d 0
          ENDDO
         ENDDO
        ENDDO

        DO k = 1, Nr
         DO j = jMin, jMax
          DO i = iMin, iMax

           IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN

C          1) Source term (only k=1) as volume-normalised rate
            sourceTerm = 0. _d 0
            IF ( k.EQ.1 ) THEN
              denom = drF(1) * hFacC(i,j,1,bi,bj)
              IF (denom .GT. 0. _d 0) THEN
                sourceTerm = pollutant_flux(i,j,bi,bj) / denom
              ENDIF
            ENDIF

C          2) Sinks
            conc = MAX( 0. _d 0, pTracer(i,j,k,bi,bj,POLLUTANT_pTr_i1) )
            decayTerm  = 0. _d 0
            settleTerm = 0. _d 0
            bioupTerm  = 0. _d 0

            IF ( usePollutantDecay ) THEN
              local_decay_rate = pollutant_decay_rate
              IF ( useTempDependentDecay ) THEN
                temp_factor = decayQ10 ** ((theta(i,j,k,bi,bj)
     &                                   - decayTempRef)/10.0 _d 0)
                local_decay_rate = local_decay_rate * temp_factor
              ENDIF
              IF ( useDepthDependentDecay ) THEN
                depth_factor = EXP( rC(k) / decayDepthScale )
                local_decay_rate = local_decay_rate * depth_factor
              ENDIF
              decayTerm = local_decay_rate * conc
            ENDIF
            IF ( usePollutantSettling ) THEN
              settleTerm = pollutant_settle_rate * conc
            ENDIF
            IF ( usePollutantBioUptake ) THEN
              bioupTerm = pollutant_biouptake_rate * conc
            ENDIF

            sinkTerm = decayTerm + settleTerm + bioupTerm

C          3) Mass (mol)
            massDiag(i,j,k) = conc * rA(i,j,bi,bj)
     &                        * drF(k) * hFacC(i,j,k,bi,bj)

C          4) Store into work arrays
            sourceDiag(i,j,k) = sourceTerm
            decayDiag (i,j,k) = decayTerm
            settleDiag(i,j,k) = settleTerm
            bioupDiag (i,j,k) = bioupTerm
            sinkDiag  (i,j,k) = sinkTerm
            totalDiag (i,j,k) = sourceTerm - sinkTerm

           ENDIF

          ENDDO
         ENDDO
        ENDDO

C      Fill block diagnostics for this tile
        CALL DIAGNOSTICS_FILL(sourceDiag,'POLLUT_S',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(  sinkDiag,'POLLUT_K',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL( decayDiag,'POLLUT_D',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(settleDiag,'POLLUT_L',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL( bioupDiag,'POLLUT_B',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL( totalDiag,'POLLUT_T',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(  massDiag,'POLLUT_M',
     &                        0,Nr,2,bi,bj,myThid)
C       2-D surface flux
        CALL DIAGNOSTICS_FILL(pollutant_flux,'POLLUT_F',
     &                        0,1,1,bi,bj,myThid)

       ENDDO
      ENDDO

#endif

      RETURN
      END
