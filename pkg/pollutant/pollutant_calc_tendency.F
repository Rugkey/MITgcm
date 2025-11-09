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
      _RL denom, flux_emission, flux_vol, flux_dry
      _RL flux_wet, flux_total, kw, Sc
      _RL atmConc, openFrac, surfTemp, surfTemp2, precipRate
      _RL dryVel, wetConc
CEOP

C     Calculate pollutant tendency terms
      DO j = 1-OLy, sNy+OLy
       DO i = 1-OLx, sNx+OLx
        pollutant_flux_vol(i,j,bi,bj) = 0. _d 0
        pollutant_flux_dry(i,j,bi,bj) = 0. _d 0
        pollutant_flux_wet(i,j,bi,bj) = 0. _d 0
        pollutant_flux_net(i,j,bi,bj) = pollutant_flux(i,j,bi,bj)
       ENDDO
      ENDDO

      DO j = jMin, jMax
       DO i = iMin, iMax
        DO k = 1, Nr

C        Only process ocean grid points
         IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN

C         Use local variable for concentration, ensuring it's non-negative
          pTr_Pollutant_safe = MAX( 0. _d 0, pTr_Pollutant(i,j,k) )

C--       1. Source term (emission flux at surface)
                              sourceTerm = 0. _d 0
C         Convert flux to volumetric rate only in the surface layer
            IF ( k.EQ.1 ) THEN
                  denom = drF(1) * hFacC(i,j,1,bi,bj)
                  IF ( pollutant_fluxIsCellTotal ) THEN
C           Convert grid-total mol/s to surface flux [mol/(m^3*s)]
                  denom = denom * rA(i,j,bi,bj)
                  ENDIF
                  flux_emission = pollutant_flux(i,j,bi,bj)
                  flux_vol = 0. _d 0
                  flux_dry = 0. _d 0
                  flux_wet = 0. _d 0
                  IF ( usePollutantAirSeaExchange ) THEN
                        atmConc = pollutant_atmConc(i,j,bi,bj)
                        openFrac = pollutant_openFrac(i,j,bi,bj)
                        dryVel = pollutant_dryDepVel(i,j,bi,bj)
                        wetConc = pollutant_wetDepConc(i,j,bi,bj)
                        precipRate = pollutant_precipRate(i,j,bi,bj)
                        surfTemp = theta_arg(i,j,k)
                        Sc = pollutant_schmidtA0
                        Sc = Sc + pollutant_schmidtA1*surfTemp
                        surfTemp2 = surfTemp*surfTemp
                        Sc = Sc + pollutant_schmidtA2*surfTemp2
                        Sc = Sc + pollutant_schmidtA3*surfTemp2*surfTemp
                        Sc = MAX( 1.D-12, Sc )
                        kw = openFrac * pollutant_pistonVel(i,j,bi,bj)
                        IF ( kw .GT. 0. _d 0 .AND.
     &                       pollutant_schmidtRef .GT. 0. _d 0 ) THEN
                              kw = kw * ( pollutant_schmidtRef / Sc )
     &                                 ** pollutant_schmidtExp
                              flux_vol = kw
     &                        * ( pollutant_henryConst*atmConc
     &                        - pTr_Pollutant_safe )
                        ENDIF
                        IF ( pollutant_useDryDeposition ) THEN
                              flux_dry = dryVel * atmConc
                        ENDIF
                        IF ( pollutant_useWetDeposition ) THEN
                              flux_wet = precipRate * wetConc
                        ENDIF
                  ENDIF
                  flux_total = flux_emission + flux_dry + flux_wet
     &                          + flux_vol
                  pollutant_flux_vol(i,j,bi,bj) = flux_vol
                  pollutant_flux_dry(i,j,bi,bj) = flux_dry
                  pollutant_flux_wet(i,j,bi,bj) = flux_wet
                  pollutant_flux_net(i,j,bi,bj) = flux_total
                  IF (denom .GT. 0. _d 0) THEN
                        sourceTerm = flux_total / denom
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
     &             ( (theta_arg(i,j,k) - 20.0 _d 0) / 10.0 _d 0 )
              k_dark_T = pollutant_k_dark_20 * temp_factor_dark

              temp_factor_bio = pollutant_Q10_bio **
     &             ( (theta_arg(i,j,k) - 20.0 _d 0) / 10.0 _d 0 )
              k_bio_T = pollutant_k_bio_20 * temp_factor_bio

C             b) Depth-dependent direct photolysis (Beer-Lambert law)
              k_photo_z = 0. _d 0
#ifdef ALLOW_EXF
                  IF ( pollutant_swdown(i,j,bi,bj) .GT. 0. _d 0 ) THEN
                        light_factor = EXP(-pollutant_light_atten
     &             * ABS(rC(k)))
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
