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
      _RL aWght, bWght

C--   Load pollutant emission forcing
      IF ( pollutant_forcingCycle.GT.0. _d 0 .AND. 
     &     pollutant_emission_file.NE.' ' ) THEN

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
        IF ( intime1.NE.pollutant_ldRec(bi,bj) ) THEN

          CALL READ_REC_XY_RL( pollutant_emission_file, 
     &                         pollutant_flux0, intime0, 1, myThid )
          CALL READ_REC_XY_RL( pollutant_emission_file, 
     &                         pollutant_flux1, intime1, 1, myThid )

          _EXCH_XY_RL( pollutant_flux0, myThid )
          _EXCH_XY_RL( pollutant_flux1, myThid )

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
             pollutant_flux(i,j,bi,bj) = 
     &              bWght*pollutant_flux0(i,j,bi,bj) +
     &              aWght*pollutant_flux1(i,j,bi,bj)
           ENDDO
          ENDDO
         ENDDO
        ENDDO

      ELSEIF ( pollutant_emission_file.NE.' ' ) THEN
        CALL READ_REC_XY_RS( pollutant_emission_file, 
     &                       pollutant_flux, 1, 1, myThid )
        _EXCH_XY_RS( pollutant_flux, myThid )
      ENDIF

C--   Load fields from EXF package
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