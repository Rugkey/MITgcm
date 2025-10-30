C--   COMMON /POLLUTANT_LOAD/
C     pollutant_ldRec     :: time-record currently loaded (in temp arrays *[1])
C     pollutantFlux0      :: temporary array for time interpolation
C     pollutantFlux1      :: temporary array for time interpolation

      COMMON /POLLUTANT_LOAD_I/ pollutant_ldRec
      COMMON /POLLUTANT_LOAD_RS/
     &    pollutantFlux0, pollutantFlux1

      INTEGER pollutant_ldRec(nSx,nSy)
      _RS pollutantFlux0(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RS pollutantFlux1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
