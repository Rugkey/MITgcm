#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_FIELDS_LOAD
C     !INTERFACE:
      SUBROUTINE POLLUTANT_FIELDS_LOAD( myTime, myIter, myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_FIELDS_LOAD
C     | o Load external fields needed by pollutant package
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == Global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "POLLUTANT.h"
#include "POLLUTANT_FIELDS.h"
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_PARAM.h"
# include "EXF_FIELDS.h"
#endif

C     !INPUT/OUTPUT PARAMETERS:
C     myTime     :: current time in simulation
C     myIter     :: current iteration number
C     myThid     :: my Thread Id number
      _RL myTime
      INTEGER myIter, myThid

#ifdef ALLOW_POLLUTANT
C     !LOCAL VARIABLES:
      INTEGER intimeP, intime0, intime1
      INTEGER bi, bj, i, j
      LOGICAL needPeriodic, haveEmissionFile
      LOGICAL haveAtmFile, haveDryFile, haveWetFile
      LOGICAL loadNewRecord
      _RL aWght, bWght
      _RL windEff

      haveEmissionFile = ( pollutant_emission_file .NE. ' ' )
      haveAtmFile = usePollutantAirSeaExchange .AND.
     &              ( pollutant_atmConc_file .NE. ' ' )
      haveDryFile = usePollutantAirSeaExchange .AND.
     &              pollutant_useDryDeposition .AND.
     &              ( pollutant_dryDepVel_file .NE. ' ' )
      haveWetFile = usePollutantAirSeaExchange .AND.
     &              pollutant_useWetDeposition .AND.
     &              ( pollutant_wetDepConc_file .NE. ' ' )

      needPeriodic = ( pollutant_forcingCycle.GT.0. _d 0 ) .AND.
     &     ( haveEmissionFile .OR. haveAtmFile .OR.
     &       haveDryFile .OR. haveWetFile )

      IF ( needPeriodic ) THEN

        IF ( myIter.EQ.nIter0 ) THEN
          DO bj = myByLo(myThid), myByHi(myThid)
           DO bi = myBxLo(myThid), myBxHi(myThid)
             pollutant_ldRec(bi,bj) = 0
           ENDDO
          ENDDO
        ENDIF

        CALL GET_PERIODIC_INTERVAL(
     O        intimeP, intime0, intime1, bWght, aWght,
     I        pollutant_forcingCycle, pollutant_forcingPeriod,
     I        deltaTClock, myTime, myThid )

        bi = myBxLo(myThid)
        bj = myByLo(myThid)
        loadNewRecord = ( intime1.NE.pollutant_ldRec(bi,bj) )

        IF ( loadNewRecord ) THEN

          IF ( haveEmissionFile ) THEN
            CALL READ_REC_XY_RL( pollutant_emission_file,
     &                           pollutant_flux0, intime0, 1, myThid )
            CALL READ_REC_XY_RL( pollutant_emission_file,
     &                           pollutant_flux1, intime1, 1, myThid )
            _EXCH_XY_RL( pollutant_flux0, myThid )
            _EXCH_XY_RL( pollutant_flux1, myThid )
          ENDIF

          IF ( haveAtmFile ) THEN
            CALL READ_REC_XY_RL( pollutant_atmConc_file,
     &                       pollutant_atmConc0, intime0, 1, myThid )
            CALL READ_REC_XY_RL( pollutant_atmConc_file,
     &                       pollutant_atmConc1, intime1, 1, myThid )
            _EXCH_XY_RL( pollutant_atmConc0, myThid )
            _EXCH_XY_RL( pollutant_atmConc1, myThid )
          ENDIF

          IF ( haveDryFile ) THEN
            CALL READ_REC_XY_RL( pollutant_dryDepVel_file,
     &                   pollutant_dryDepVel0, intime0, 1, myThid )
            CALL READ_REC_XY_RL( pollutant_dryDepVel_file,
     &                   pollutant_dryDepVel1, intime1, 1, myThid )
            _EXCH_XY_RL( pollutant_dryDepVel0, myThid )
            _EXCH_XY_RL( pollutant_dryDepVel1, myThid )
          ENDIF

          IF ( haveWetFile ) THEN
            CALL READ_REC_XY_RL( pollutant_wetDepConc_file,
     &                       pollutant_wetDepConc0, intime0, 1, myThid )
            CALL READ_REC_XY_RL( pollutant_wetDepConc_file,
     &                       pollutant_wetDepConc1, intime1, 1, myThid )
            _EXCH_XY_RL( pollutant_wetDepConc0, myThid )
            _EXCH_XY_RL( pollutant_wetDepConc1, myThid )
          ENDIF

          DO bj = myByLo(myThid), myByHi(myThid)
           DO bi = myBxLo(myThid), myBxHi(myThid)
             pollutant_ldRec(bi,bj) = intime1
           ENDDO
          ENDDO

        ENDIF

        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
             IF ( haveEmissionFile ) THEN
               pollutant_flux(i,j,bi,bj) =
     &              bWght*pollutant_flux0(i,j,bi,bj) +
     &              aWght*pollutant_flux1(i,j,bi,bj)
             ELSE
               pollutant_flux(i,j,bi,bj) = 0. _d 0
             ENDIF
             IF ( haveAtmFile ) THEN
               pollutant_atmConc(i,j,bi,bj) =
     &              bWght*pollutant_atmConc0(i,j,bi,bj) +
     &              aWght*pollutant_atmConc1(i,j,bi,bj)
             ENDIF
             IF ( haveDryFile ) THEN
               pollutant_dryDepVel(i,j,bi,bj) =
     &              bWght*pollutant_dryDepVel0(i,j,bi,bj) +
     &              aWght*pollutant_dryDepVel1(i,j,bi,bj)
             ENDIF
             IF ( haveWetFile ) THEN
               pollutant_wetDepConc(i,j,bi,bj) =
     &              bWght*pollutant_wetDepConc0(i,j,bi,bj) +
     &              aWght*pollutant_wetDepConc1(i,j,bi,bj)
             ENDIF
           ENDDO
          ENDDO
         ENDDO
        ENDDO

      ELSE

        IF ( haveEmissionFile ) THEN
          CALL READ_REC_XY_RS( pollutant_emission_file,
     &                         pollutant_flux, 1, 1, myThid )
          _EXCH_XY_RS( pollutant_flux, myThid )
        ENDIF

        IF ( haveAtmFile ) THEN
          CALL READ_REC_XY_RL( pollutant_atmConc_file,
     &                         pollutant_atmConc, 1, 1, myThid )
          _EXCH_XY_RL( pollutant_atmConc, myThid )
        ENDIF

        IF ( haveDryFile ) THEN
          CALL READ_REC_XY_RL( pollutant_dryDepVel_file,
     &                         pollutant_dryDepVel, 1, 1, myThid )
          _EXCH_XY_RL( pollutant_dryDepVel, myThid )
        ENDIF

        IF ( haveWetFile ) THEN
          CALL READ_REC_XY_RL( pollutant_wetDepConc_file,
     &                         pollutant_wetDepConc, 1, 1, myThid )
          _EXCH_XY_RL( pollutant_wetDepConc, myThid )
        ENDIF

      ENDIF

C--   Apply constants and defaults for air-sea exchange fields
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
           pollutant_openFrac(i,j,bi,bj) = hFacC(i,j,1,bi,bj)
           IF ( .NOT. usePollutantAirSeaExchange ) THEN
             pollutant_atmConc(i,j,bi,bj) = 0. _d 0
             pollutant_dryDepVel(i,j,bi,bj) = 0. _d 0
             pollutant_wetDepConc(i,j,bi,bj) = 0. _d 0
             pollutant_pistonVel(i,j,bi,bj) = 0. _d 0
             pollutant_precipRate(i,j,bi,bj) = 0. _d 0
           ELSE
             IF ( .NOT. haveAtmFile ) THEN
               pollutant_atmConc(i,j,bi,bj) = pollutant_atmConcConst
             ENDIF
             IF ( .NOT. pollutant_useDryDeposition ) THEN
               pollutant_dryDepVel(i,j,bi,bj) = 0. _d 0
             ELSEIF ( .NOT. haveDryFile ) THEN
               pollutant_dryDepVel(i,j,bi,bj) = pollutant_dryDepVelConst
             ENDIF
             IF ( .NOT. pollutant_useWetDeposition ) THEN
               pollutant_wetDepConc(i,j,bi,bj) = 0. _d 0
             ELSEIF ( .NOT. haveWetFile ) THEN
               pollutant_wetDepConc(i,j,bi,bj) =
     &              pollutant_wetDepConcConst
             ENDIF

#ifdef ALLOW_EXF
# ifdef ALLOW_ATM_TEMP
             IF ( useEXF ) THEN
               pollutant_precipRate(i,j,bi,bj) =
     &              MAX( 0. _d 0, precip(i,j,bi,bj) )
             ELSE
               pollutant_precipRate(i,j,bi,bj) = pollutant_precipConst
             ENDIF
# else
             pollutant_precipRate(i,j,bi,bj) = pollutant_precipConst
# endif
#else
             pollutant_precipRate(i,j,bi,bj) = pollutant_precipConst
#endif

#ifdef ALLOW_EXF
             IF ( useEXF ) THEN
               windEff = MAX( pollutant_minWind,
     &              wspeed(i,j,bi,bj) )
             ELSE
               windEff = pollutant_defaultWind
             ENDIF
#else
             windEff = pollutant_defaultWind
#endif
             windEff = MAX( pollutant_minWind, windEff )
             pollutant_pistonVel(i,j,bi,bj) = 0. _d 0
             IF ( pollutant_openFrac(i,j,bi,bj) .GT. 0. _d 0 .AND.
     &            maskC(i,j,1,bi,bj) .NE. 0. _d 0 ) THEN
               pollutant_pistonVel(i,j,bi,bj) =
     &            pollutant_pistonCoeff * windEff * windEff
               pollutant_pistonVel(i,j,bi,bj) =
     &            pollutant_pistonVel(i,j,bi,bj) / 3.6 _d 5
             ENDIF
           ENDIF
         ENDDO
        ENDDO
       ENDDO
      ENDDO

      _EXCH_XY_RL( pollutant_atmConc, myThid )
      _EXCH_XY_RL( pollutant_dryDepVel, myThid )
      _EXCH_XY_RL( pollutant_wetDepConc, myThid )
      _EXCH_XY_RL( pollutant_pistonVel, myThid )
      _EXCH_XY_RL( pollutant_openFrac, myThid )
      _EXCH_XY_RL( pollutant_precipRate, myThid )

C--   Load fields from EXF package for radiation
#ifdef ALLOW_EXF
# ifdef ALLOW_DOWNWARD_RADIATION
      IF ( useEXF ) THEN
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1, sNy
           DO i = 1, sNx
             pollutant_swdown(i,j,bi,bj) = swdown(i,j,bi,bj)
           ENDDO
          ENDDO
         ENDDO
        ENDDO
      ENDIF
# endif /* ALLOW_DOWNWARD_RADIATION */
#endif /* ALLOW_EXF */

#endif /* ALLOW_POLLUTANT */

      RETURN
      END