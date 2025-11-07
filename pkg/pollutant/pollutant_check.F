#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_CHECK
C     !INTERFACE:
      SUBROUTINE POLLUTANT_CHECK( myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE POLLUTANT_CHECK
C     | o Check pollutant package parameters and configuration
C     *==========================================================*

C     !USES:
      IMPLICIT NONE

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"
#include "POLLUTANT_SIZE.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"

C     !INPUT/OUTPUT PARAMETERS:
C     myThid     :: my Thread Id number
      INTEGER myThid

C     !LOCAL VARIABLES:
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

#ifdef ALLOW_POLLUTANT

      _BEGIN_MASTER(myThid)
      WRITE(msgBuf,'(A)') 'POLLUTANT_CHECK:   #define ALLOW_POLLUTANT'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      _END_MASTER(myThid)

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C     Print parameter summary
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)') '// POLLUTANT package configuration:'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A,L5)') '// usePollutantDegradation: ',
     &                        usePollutantDegradation
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      IF (usePollutantDegradation) THEN
        WRITE(msgBuf,'(A,F8.3)') '// pollutant_Tc (degC): ',
     &                           pollutant_Tc
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE10.3)') '// pollutant_k_dark_20 (s-1): ',
     &                               pollutant_k_dark_20
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,F8.3)') '// pollutant_Q10_dark: ',
     &                           pollutant_Q10_dark
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE10.3)') '// pollutant_k_bio_20 (s-1): ',
     &                               pollutant_k_bio_20
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,F8.3)') '// pollutant_Q10_bio: ',
     &                           pollutant_Q10_bio
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE10.3)') '// pollutant_k_OH (s-1): ',
     &                               pollutant_k_OH
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,1PE10.3)') '// pollutant_k_photo (s-1): ',
     &                               pollutant_k_photo
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,F8.3)') '// pollutant_light_atten (m-1): ',
     &                           pollutant_light_atten
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                      SQUEEZE_RIGHT, myThid )
      ENDIF

      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      _END_MASTER(myThid)

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
