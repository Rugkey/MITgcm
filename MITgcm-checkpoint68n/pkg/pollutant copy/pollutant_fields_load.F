#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_FIELDS_LOAD
C     !INTERFACE:
      SUBROUTINE POLLUTANT_FIELDS_LOAD (
     I           myTime, myIter, myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_FIELDS_LOAD
C     | o Load pollutant emission flux fields
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "POLLUTANT.h"
#include "POLLUTANT_LOAD.h"

C     !INPUT/OUTPUT PARAMETERS:
C     myTime     :: current time in simulation
C     myIter     :: current iteration number
C     myThid     :: my Thread Id number
      _RL myTime
      INTEGER myIter
      INTEGER myThid

C     !LOCAL VARIABLES:
      INTEGER intimeP, intime0, intime1
      INTEGER bi, bj, i, j
      _RL aWght, bWght
      LOGICAL fileExists
CEOP

      IF ( pollutant_forcingCycle .GT. 0. _d 0 .AND.
     &     pollutant_emission_file .NE. ' ' ) THEN

C First call requires that we initialize everything to zero for safety
       IF ( myIter .EQ. nIter0 ) THEN
         DO bj = myByLo(myThid), myByHi(myThid)
          DO bi = myBxLo(myThid), myBxHi(myThid)
            pollutant_ldRec(bi,bj) = 0
            DO j=1-OLy,sNy+OLy
             DO i=1-OLx,sNx+OLx
              pollutantFlux0(i,j,bi,bj) = 0. _d 0
              pollutantFlux1(i,j,bi,bj) = 0. _d 0
              pollutant_flux(i,j,bi,bj) = 0. _d 0
             ENDDO
            ENDDO
          ENDDO
         ENDDO
       ENDIF

C--   Now calculate whether it is time to update the forcing arrays
       CALL GET_PERIODIC_INTERVAL(
     O                   intimeP, intime0, intime1, bWght, aWght,
     I                   pollutant_forcingCycle,
     I                   pollutant_forcingPeriod, deltaTClock,
     I                   myTime, myThid )

       bi = myBxLo(myThid)
       bj = myByLo(myThid)

       IF ( intime1.NE.pollutant_ldRec(bi,bj) ) THEN

C--   If the above condition is met then we need to read in
C     data for the period ahead and the period behind myTime.
        _BARRIER

C--   Check if pollutant emission file exists
         INQUIRE(FILE=pollutant_emission_file, EXIST=fileExists)
         IF (.NOT.fileExists) THEN
          WRITE(standardMessageUnit,'(2A)') 
     &     'POLLUTANT: ERROR - pollutant_emission_file not found: ',
     &     pollutant_emission_file
          STOP 'ABNORMAL END: S/R POLLUTANT_FIELDS_LOAD'
         ENDIF

         DO bj = myByLo(myThid), myByHi(myThid)
          DO bi = myBxLo(myThid), myBxHi(myThid)
C--   Read pollutant flux data
           CALL READ_REC_XY_RS(pollutant_emission_file,
     &          pollutantFlux0(1-OLx,1-OLy,bi,bj),
     &          intime0, myIter, myThid)
           CALL READ_REC_XY_RS(pollutant_emission_file,
     &          pollutantFlux1(1-OLx,1-OLy,bi,bj),
     &          intime1, myIter, myThid)
          ENDDO
         ENDDO

C--   fill-in overlap after loading temp arrays:
         _EXCH_XY_RS(pollutantFlux0, myThid )
         _EXCH_XY_RS(pollutantFlux1, myThid )

C-    save newly loaded time-record
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
           pollutant_ldRec(bi,bj) = intime1
         ENDDO
        ENDDO

C--   end if-block for loading new time-records
       ENDIF

       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           pollutant_flux(i,j,bi,bj) = bWght*pollutantFlux0(i,j,bi,bj)
     &                               + aWght*pollutantFlux1(i,j,bi,bj)
          ENDDO
         ENDDO
        ENDDO
       ENDDO

C--   fill-in overlap after updating flux array:
       _EXCH_XY_RS(pollutant_flux, myThid )

C endif for periodicForcing
      ENDIF

      RETURN
      END
