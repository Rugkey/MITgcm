#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CStartOfInterface
      SUBROUTINE POLLUTANT_DIAGS( myTime, myIter, myThid )
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_DIAGS
C     | o Do POLLUTANT diagnostic output
C     *==========================================================*
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "DIAGNOSTICS_SIZE.h"
#include "DIAGNOSTICS.h"

C     == Routine arguments ==
C     myTime - Current time of simulation ( s )
C     myIter - Iteration number
C     myThid -  Number of this instance of INI_FORCING
      _RL     myTime
      INTEGER myIter
      INTEGER myThid
CEndOfInterface

#ifdef ALLOW_POLLUTANT
#ifdef ALLOW_TIMEAVE

C     == Local variables ==
      LOGICAL  DIFFERENT_MULTIPLE
      EXTERNAL DIFFERENT_MULTIPLE
      INTEGER bi, bj
      CHARACTER*(10) suff

C     Dump files and restart average computation if needed
      IF ( PTRACERS_taveFreq.GT.0. .AND. 
     &     DIFFERENT_MULTIPLE(PTRACERS_taveFreq,myTime,deltaTClock) ) THEN

C      Normalize by integrated time
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         CALL TIMEAVE_NORMALIZE(sourceAve, POLLUTANT_timeAve, Nr ,
     &                 bi,bj,myThid)
         CALL TIMEAVE_NORMALIZE(sinkAve, POLLUTANT_timeAve, Nr ,
     &                 bi,bj,myThid)
         CALL TIMEAVE_NORMALIZE(decayAve, POLLUTANT_timeAve, Nr ,
     &                 bi,bj,myThid)
         CALL TIMEAVE_NORMALIZE(settlingAve, POLLUTANT_timeAve, Nr ,
     &                 bi,bj,myThid)
         CALL TIMEAVE_NORMALIZE(bioUptakeAve, POLLUTANT_timeAve, Nr ,
     &                 bi,bj,myThid)
        ENDDO
       ENDDO

       IF ( PTRACERS_timeave_mdsio )  THEN
         IF ( rwSuffixType.EQ.0 ) THEN
           WRITE(suff,'(I10.10)') myIter
         ELSE
           CALL RW_GET_SUFFIX( suff, myTime, myIter, myThid )
         ENDIF
         CALL WRITE_FLD_XYZ_RL('POLLUTANT_Srcave.',suff,sourceAve,
     &        myIter,myThid)
         CALL WRITE_FLD_XYZ_RL('POLLUTANT_Sinkave.',suff,sinkAve,
     &        myIter,myThid)
         CALL WRITE_FLD_XYZ_RL('POLLUTANT_Decayave.',suff,decayAve,
     &        myIter,myThid)
         CALL WRITE_FLD_XYZ_RL('POLLUTANT_Settlingave.',suff,settlingAve,
     &        myIter,myThid)
         CALL WRITE_FLD_XYZ_RL('POLLUTANT_BioUptakeave.',suff,bioUptakeAve,
     &        myIter,myThid)
       ENDIF


C      Reset averages to zero
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         CALL TIMEAVE_RESET(sourceAve,Nr,bi,bj,myThid)
         CALL TIMEAVE_RESET(sinkAve,Nr,bi,bj,myThid)
         CALL TIMEAVE_RESET(decayAve,Nr,bi,bj,myThid)
         CALL TIMEAVE_RESET(settlingAve,Nr,bi,bj,myThid)
         CALL TIMEAVE_RESET(bioUptakeAve,Nr,bi,bj,myThid)
         POLLUTANT_timeAve(bi,bj) = 0. _d 0
        ENDDO
       ENDDO

      ENDIF

#endif /* ALLOW_TIMEAVE */
#endif /* ALLOW_POLLUTANT */

      RETURN
      END
