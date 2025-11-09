#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

C !INTERFACE: ==========================================================
      SUBROUTINE POLLUTANT_DIAGS(
     I                           myTime, myIter, myThid )
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_DIAGS
C     | o Assemble pollutant diagnostics and trigger package output.
C     |   Budget accumulation is handled here each time-step so that
C     |   global reductions occur only once per step.
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
#include "POLLUTANT_FIELDS.h"
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
      _RL sourceTerm, sinkTerm
      _RL k_total, k_dark_T, k_bio_T, k_photo_z
      _RL temp_factor_dark, temp_factor_bio
      _RL light_factor
      _RL conc
      _RL denom
      _RL volCell
      _RL massLocal, sourceLocal, sinkLocal

C     Work arrays for block diagnostics fill
      _RL sourceDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL sinkDiag  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL totalDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL massDiag  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL surfDiag  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL globMassDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL globSrcDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL globSnkDiag (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL globCumSDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL globCumKDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)

      iMin = 1
      iMax = sNx
      jMin = 1
      jMax = sNy

      massLocal  = 0. _d 0
      sourceLocal = 0. _d 0
      sinkLocal   = 0. _d 0

C--   Loop tiles and build diagnostics arrays
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)

C      zero work arrays for this tile (including overlap)
            DO k = 1, Nr
             DO j = 1-OLy, sNy+OLy
              DO i = 1-OLx, sNx+OLx
               surfDiag(i,j,k)      = 0. _d 0
               globMassDiag(i,j,k)  = 0. _d 0
               globSrcDiag(i,j,k)   = 0. _d 0
               globSnkDiag(i,j,k)   = 0. _d 0
               globCumSDiag(i,j,k)  = 0. _d 0
               globCumKDiag(i,j,k)  = 0. _d 0
              ENDDO
             ENDDO
            ENDDO

        DO k = 1, Nr
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           sourceDiag(i,j,k) = 0. _d 0
           sinkDiag  (i,j,k) = 0. _d 0
           totalDiag (i,j,k) = 0. _d 0
           massDiag  (i,j,k) = 0. _d 0
          ENDDO
         ENDDO
        ENDDO

        DO k = 1, Nr
         DO j = jMin, jMax
          DO i = iMin, iMax

            IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN

            conc = MAX( 0. _d 0, pTracer(i,j,k,bi,bj,POLLUTANT_pTr_i1) )

C          1) Source term (only k=1) as volume-normalised rate
                  sourceTerm = 0. _d 0
                  IF ( k.EQ.1 ) THEN
                        denom = drF(1) * hFacC(i,j,1,bi,bj)
                        IF ( pollutant_fluxIsCellTotal ) THEN
C             Convert grid-total mol/s to mol/(m^3*s)
                              denom = denom * rA(i,j,bi,bj)
                        ENDIF
                        IF (denom .GT. 0. _d 0) THEN
                        sourceTerm = pollutant_flux(i,j,bi,bj) / denom
                        ENDIF
                        surfDiag(i,j,1) = conc
                  ENDIF

C          2) Sinks
            sinkTerm = 0. _d 0

            IF ( usePollutantDegradation ) THEN
              k_total = 0. _d 0
              IF ( theta(i,j,k,bi,bj) .GT. pollutant_Tc ) THEN

C               a) Temperature-dependent dark and biological degradation (Q10)
                temp_factor_dark = pollutant_Q10_dark **
     &              ( (theta(i,j,k,bi,bj) - 20.0 _d 0) / 10.0 _d 0 )
                k_dark_T = pollutant_k_dark_20 * temp_factor_dark

                temp_factor_bio = pollutant_Q10_bio **
     &              ( (theta(i,j,k,bi,bj) - 20.0 _d 0) / 10.0 _d 0 )
                k_bio_T = pollutant_k_bio_20 * temp_factor_bio

C               b) Depth-dependent direct photolysis (Beer-Lambert law)
                k_photo_z = 0. _d 0
#ifdef ALLOW_EXF
                IF ( pollutant_swdown(i,j,bi,bj) .GT. 0. _d 0 ) THEN
                  light_factor = EXP( -pollutant_light_atten
     &                               * ABS(rC(k)) )
                  k_photo_z = pollutant_k_photo * light_factor
                ENDIF
#endif

C               c) Sum all rates to get total degradation rate
                k_total = k_dark_T + k_bio_T + pollutant_k_OH
     &                  + k_photo_z

              ENDIF

C             Calculate total sink term
              sinkTerm = k_total * conc

            ENDIF

C          3) Mass (mol)
                  volCell = rA(i,j,bi,bj) * drF(k) * hFacC(i,j,k,bi,bj)
                  massDiag(i,j,k) = conc * volCell

                  massLocal = massLocal + massDiag(i,j,k)
                  sinkLocal = sinkLocal + sinkTerm * volCell
                  IF ( k.EQ.1 ) THEN
                     sourceLocal = sourceLocal + sourceTerm * volCell
                  ENDIF

C          4) Store into work arrays
            sourceDiag(i,j,k) = sourceTerm
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
        CALL DIAGNOSTICS_FILL( totalDiag,'POLLUT_T',
     &                        0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(  massDiag,'POLLUT_M',
     &                        0,Nr,2,bi,bj,myThid)
C       2-D surface flux
        CALL DIAGNOSTICS_FILL(pollutant_flux,'POLLUT_F',
     &                        0,1,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(  surfDiag,'POLSURF ',
     &                        0,1,1,bi,bj,myThid)
       ENDDO
      ENDDO

      _GLOBAL_SUM_RL( massLocal,   myThid )
      _GLOBAL_SUM_RL( sourceLocal, myThid )
      _GLOBAL_SUM_RL( sinkLocal,   myThid )

      _BEGIN_MASTER(myThid)
        pollutant_globalMass   = massLocal
        pollutant_globalSource = sourceLocal
        pollutant_globalSink   = sinkLocal
        pollutant_cumuSource = pollutant_cumuSource
     &        + sourceLocal * deltaTClock
        pollutant_cumuSink   = pollutant_cumuSink
     &        + sinkLocal * deltaTClock
      _END_MASTER(myThid)
      _BARRIER

      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)

        DO k = 1, Nr
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
            globMassDiag(i,j,k)  = 0. _d 0
            globSrcDiag (i,j,k)  = 0. _d 0
            globSnkDiag (i,j,k)  = 0. _d 0
            globCumSDiag(i,j,k)  = 0. _d 0
            globCumKDiag(i,j,k)  = 0. _d 0
          ENDDO
         ENDDO
        ENDDO

        DO j = jMin, jMax
         DO i = iMin, iMax
            globMassDiag(i,j,1)  = pollutant_globalMass
            globSrcDiag (i,j,1)  = pollutant_globalSource
            globSnkDiag (i,j,1)  = pollutant_globalSink
            globCumSDiag(i,j,1)  = pollutant_cumuSource
            globCumKDiag(i,j,1)  = pollutant_cumuSink
         ENDDO
        ENDDO

        CALL DIAGNOSTICS_FILL(globMassDiag,'POLGMASS',
     &                        0,1,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(globSrcDiag,'POLGSRC ',
     &                        0,1,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(globSnkDiag,'POLGSNK ',
     &                        0,1,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(globCumSDiag,'POLCSRC ',
     &                        0,1,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(globCumKDiag,'POLCSNK ',
     &                        0,1,1,bi,bj,myThid)

       ENDDO
      ENDDO

#endif

      RETURN
      END
