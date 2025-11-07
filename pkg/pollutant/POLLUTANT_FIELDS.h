C     *==========================================================*
C     | POLLUTANT_FIELDS.h
C     | o Header file for pollutant package fields used in common
C     *==========================================================*

#ifdef ALLOW_POLLUTANT

      COMMON /POLLUTANT_EXF_FIELDS/
     &      pollutant_swdown
      _RL pollutant_swdown(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

#endif /* ALLOW_POLLUTANT */

