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
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      _RL wetArea
      _RL local_total_emission
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

C--   This condition ensures we load data on the first step, or when needed
       IF ( intime1.NE.pollutant_ldRec(bi,bj) .OR. myIter.EQ.nIter0 )
     &  THEN

C--   If the above condition is met then we need to read in new data.
        _BARRIER

         DO bj = myByLo(myThid), myByHi(myThid)
          DO bi = myBxLo(myThid), myBxHi(myThid)
           CALL READ_REC_XY_RS(pollutant_emission_file,
     &          pollutantFlux0(1-OLx,1-OLy,bi,bj),
     &          intime0, myIter, myThid)
           CALL READ_REC_XY_RS(pollutant_emission_file,
     &          pollutantFlux1(1-OLx,1-OLy,bi,bj),
     &          intime1, myIter, myThid)
          ENDDO
         ENDDO

         _EXCH_XY_RS(pollutantFlux0, myThid )
         _EXCH_XY_RS(pollutantFlux1, myThid )

        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
           pollutant_ldRec(bi,bj) = intime1
         ENDDO
        ENDDO

C--   Sanity Check: Calculate and print total global emission on first time step
        IF ( myIter .EQ. nIter0 ) THEN
          local_total_emission = 0. _d 0
          DO bj = myByLo(myThid), myByHi(myThid)
            DO bi = myBxLo(myThid), myBxHi(myThid)
              DO j=1,sNy
                DO i=1,sNx
                  IF ( pollutant_fluxIsCellTotal ) THEN
                    local_total_emission = local_total_emission
     &                   + pollutantFlux0(i,j,bi,bj)
                  ELSE
                    local_total_emission = local_total_emission
     &                   + pollutantFlux0(i,j,bi,bj) * rA(i,j,bi,bj)
                  ENDIF
                ENDDO
              ENDDO
            ENDDO
          ENDDO

          _GLOBAL_SUM_RL( local_total_emission, myThid )

          _BEGIN_MASTER(myThid)
            WRITE(msgBuf,'(A,1PE12.5,A)')
     &        'POLLUTANT: Initial Global Emission Rate = ',
     &        local_total_emission, ' mol/s'
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
          _END_MASTER(myThid)
        ENDIF

       ENDIF

       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           pollutant_flux(i,j,bi,bj) = bWght*pollutantFlux0(i,j,bi,bj)
     &                               + aWght*pollutantFlux1(i,j,bi,bj)

           IF ( pollutant_fluxIsCellTotal ) THEN
            wetArea = rA(i,j,bi,bj)
     &               * MAX( hFacC(i,j,1,bi,bj), 1.0D-12 )
            IF ( wetArea .GT. 0. ) THEN
             pollutant_flux(i,j,bi,bj) =
     &            pollutant_flux(i,j,bi,bj) / wetArea
            ELSE
             pollutant_flux(i,j,bi,bj) = 0.
            ENDIF
           ENDIF
          ENDDO
         ENDDO
        ENDDO
       ENDDO

       _EXCH_XY_RS(pollutant_flux, myThid )

      ENDIF

      RETURN
      END
