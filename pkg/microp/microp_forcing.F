C $Header: /u/gcmpack/MITgcm/pkg/microp/microp_forcing.F,v 1.10 2010/03/16 00:14:47 jmc Exp $
C $Name: checkpoint64g $

C modified for external_forcing_DIC.F  August 1999
c
c modified swd Oct 01 and Feb 02, for use as package for c40_patch1
c modified to use with c44 and ptracers: swd May 2002
c modified to have carbonate and biological influences: swd June 2002
c modified for MICROP: swd Sep 2003
C

#include "GCHEM_OPTIONS.h"
#include "MICROP_OPTIONS.h"

CStartOfInterFace
      SUBROUTINE MICROP_FORCING( Ptr,
     &                       Gchem,
     &                       bi,bj,imin,imax,jmin,jmax,
     &                       myIter,myTime,myThid)

C     /==========================================================\
C     | SUBROUTINE MICROP_FORCING                               |
C     | o Calculate the changes to microp                       |
C     |   through river    fluxes                               |
C     |==========================================================|
      IMPLICIT NONE

C     == GLobal variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "MICROP_SIZE.h"
#include "MICROP.h"

C     == Routine arguments ==
      INTEGER myIter
      _RL myTime
      INTEGER myThid
      _RL  Ptr  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy,PTRACERS_num)
      _RL  Gchem(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy,PTRACERS_num)
      INTEGER i,j,bi, bj, imin, imax, jmin, jmax

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MICROP
C     == Local variables ==
      _RL  SURMICROP(1-OLx:sNx+OLx,1-OLy:sNy+OLy)

         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           SURMICROP(i,j)=0.d0
          ENDDO
         ENDDO

C MICROP river runoff
       CALL microp_surfforcing( Ptr(1-OLx,1-OLy,1,1,1,1), SURMICROP,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)

         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
            Ptr(i,j,1,bi,bj,imicrop) = Ptr(i,j,1,bi,bj,imicrop)
     &                           + SURMICROP(i,j) * deltaTclock
          ENDDO
         ENDDO

#endif
#endif

       RETURN
       END
