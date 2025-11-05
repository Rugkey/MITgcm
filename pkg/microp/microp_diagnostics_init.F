C $Header: /u/gcmpack/MITgcm/pkg/MICROP/MICROP_diagnostics_init.F,v 1.0 2013/07/11 08:50:17 yanxu Exp $
C $Name:  $

#include "CPP_OPTIONS.h"
#include "PTRACERS_OPTIONS.h"
#include "MICROP_OPTIONS.h"

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MICROP

CBOP
C     !ROUTINE MICROP_DIAGNOSTICS_INIT
C     !INTERFACE:
      SUBROUTINE MICROP_DIAGNOSTICS_INIT( myThid )
C     !DESCRIPTION:
C     Routine to initialize MICROP diagnostics

C     !USES:
      IMPLICIT NONE
C     === Global variables ===
#include "SIZE.h"
#include "PTRACERS_SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GCHEM.h"
#include "MICROP_SIZE.h"
#include "MICROP.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myThid -  Number of this instance of MICROP_DIAGNOSTICS_INIT
      INTEGER myThid
CEOP

#ifdef ALLOW_DIAGNOSTICS
C     !LOCAL VARIABLES:
C     === Local variables ===
C     msgBuf      - Informational/error meesage buffer
c     CHARACTER*(MAX_LEN_MBUF) msgBuf

      INTEGER       diagNum
      CHARACTER*9   diagName
      CHARACTER*16  diagCode
      CHARACTER*16  diagUnits
      CHARACTER*(80) diagTitle


C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C--   Add diagnostics to the (long) list

C--   Add diagnostic MICROP2DEPO, MICROP0CONC, MICROP0EVAS, MICROP2REDN, and MICROPPSINK

      diagName = 'MPRIVER '
      WRITE(diagTitle, '(A)') 'MICROP riverine runoff'
      diagUnits = 'num/m^2/s       '
      diagCode  = 'SM P    M1      '
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I             diagName, diagCode, diagUnits, diagTitle, 0, myThid )
     
#endif /* ALLOW_DIAGNOSTICS */

      RETURN
      END     
C============================================================================
#endif
#endif
