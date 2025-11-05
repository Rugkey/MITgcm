C     *==========================================================*
C     | POLLUTANT.h
C     | o Ocean Pollutant Variables
C     *==========================================================*

C--   COMMON /POLLUTANT_PARMS/
C     ========================
C     This common block holds all pollutant package parameters.

C--   Logical flags for processes
C     usePollutantDegradation :: flag to turn on/off degradation process
C     pollutant_fluxIsCellTotal :: if .TRUE., input emission is mol/s per grid-cell

C--   Parameters for temperature-dependent degradation
C     pollutant_Tc          :: critical temperature for degradation [degC]
C     pollutant_k1_deg_20_d :: first-order degradation rate at 20C [d^-1]
C     pollutant_kt_deg      :: temperature coefficient for degradation
C     pollutant_fr_deg      :: fraction subject to degradation

C--   Internal rate constant [1/s] (calculated from input)
C     pollutant_k0_deg      :: zeroth-order degradation rate [mol/m^3/s]
C     pollutant_k1_deg_20   :: first-order degradation rate at 20C [s^-1]

      COMMON /POLLUTANT_PARMS/
     &              usePollutantDegradation,
     &              pollutant_fluxIsCellTotal,
     &              pollutant_forcingPeriod,
     &              pollutant_forcingCycle,
     &              pollutant_emission_file,
     &              pollutant_Tc,
     &              pollutant_k1_deg_20_d,
     &              pollutant_kt_deg,
     &              pollutant_fr_deg,
     &              pollutant_k0_deg_d,
     &              pollutant_k0_deg,
     &              pollutant_k1_deg_20

      LOGICAL usePollutantDegradation
      LOGICAL pollutant_fluxIsCellTotal

      _RL pollutant_forcingPeriod
      _RL pollutant_forcingCycle
      _RL pollutant_Tc
      _RL pollutant_k1_deg_20_d
      _RL pollutant_kt_deg
      _RL pollutant_fr_deg
      _RL pollutant_k0_deg_d
      _RL pollutant_k0_deg
      _RL pollutant_k1_deg_20

      CHARACTER*(MAX_LEN_FNAM) pollutant_emission_file

C--   COMMON /POLLUTANT_FIELDS/
C     pollutant_flux    :: pollutant emission flux (mol/m^2/s)
C     pollutant_conc    :: pollutant concentration (mol/m^3)
C     pollutant_mass    :: pollutant mass per grid cell (mol)

      COMMON /POLLUTANT_FIELDS/
     &              pollutant_flux, pollutant_conc, pollutant_mass
      _RS pollutant_flux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL pollutant_conc(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL pollutant_mass(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)

#ifdef ALLOW_TIMEAVE
C For time-averages output using TIMEAVE pkg:
C  sourceAve     :: pollutant source term [mol/m3/s]
C  sinkAve       :: pollutant sink term [mol/m3/s]
C  POLLUTANT_timeAve :: period over which POLLUTANT averages are calculated [s]

      COMMON /POLLUTANT_TAVE/
     &     sourceAve, sinkAve,
     &     POLLUTANT_timeAve

      _RL sourceAve    (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL sinkAve      (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL POLLUTANT_timeAve(nSx,nSy)
#endif /* ALLOW_TIMEAVE */



C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|



