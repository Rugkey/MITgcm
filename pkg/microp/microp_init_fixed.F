C $Header: /u/gcmpack/pkg/MICROP/MICROP_init_fixed.F,v 1.0 2013/07/11 09:38:10 yanxu Exp $
C $Name:  $

#include "CPP_OPTIONS.h"
#include "PTRACERS_OPTIONS.h"
#include "MICROP_OPTIONS.h"

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MICROP

c===============================================================================
C===============================================================================
CStartofinterface
      SUBROUTINE MICROP_INIT_FIXED(myThid)
C     =============== Global data ==========================================
C     === Global variables ===
         implicit none
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "GCHEM.h"
#include "MICROP_SIZE.h"
#include "MICROP.h"

        INTEGER myThid

C set up diagnostics
#ifdef ALLOW_DIAGNOSTICS
      IF ( useDIAGNOSTICS ) THEN
        CALL MICROP_DIAGNOSTICS_INIT( myThid )
      ENDIF
#endif /* ALLOW_DIAGNOSTICS */
C

        RETURN
        END
C============================================================================
#endif
#endif

