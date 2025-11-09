C     *==========================================================*
C     | POLLUTANT.h
C     | o Ocean Pollutant Variables
C     *==========================================================*

C--   COMMON /POLLUTANT_PARMS/
C     ========================
C     This common block holds all pollutant package parameters.

C--   Parameters for chemical degradation
C     pollutant_Tc          :: critical temperature for degradation [degC]
C     pollutant_k_dark_20_d :: dark degradation rate at 20C [d^-1]
C     pollutant_Q10_dark    :: Q10 temperature coefficient for dark degradation
C     pollutant_k_bio_20_d  :: biological degradation rate at 20C [d^-1]
C     pollutant_Q10_bio     :: Q10 temperature coefficient for biological degradation
C     pollutant_k_OH_d      :: indirect photolysis (OH) rate [d^-1]
C     pollutant_k_photo_d   :: surface direct photolysis rate [d^-1]
C     pollutant_light_atten :: light attenuation coefficient [m^-1]

C--   Internal rate constants [1/s] (calculated from input)
C     pollutant_k_dark_20   :: dark degradation rate at 20C [s^-1]
C     pollutant_k_bio_20    :: biological degradation rate at 20C [s^-1]
C     pollutant_k_OH        :: indirect photolysis (OH) rate [s^-1]
C     pollutant_k_photo     :: surface direct photolysis rate [s^-1]

C--   Logical flags for processes
C     usePollutantDegradation :: flag to turn on/off degradation process
C     pollutant_fluxIsCellTotal :: if .TRUE., input emission is mol/s per grid-cell

      COMMON /POLLUTANT_PARMS/
     &              pollutant_forcingPeriod,
     &              pollutant_forcingCycle,
     &              pollutant_Tc,
     &              pollutant_k_dark_20_d,
     &              pollutant_Q10_dark,
     &              pollutant_k_bio_20_d,
     &              pollutant_Q10_bio,
     &              pollutant_k_OH_d,
     &              pollutant_k_photo_d,
     &              pollutant_light_atten,
     &              pollutant_k_dark_20,
     &              pollutant_k_bio_20,
     &              pollutant_k_OH,
     &              pollutant_k_photo,
     &              usePollutantDegradation,
     &              pollutant_fluxIsCellTotal,
     &              pollutant_emission_file

      _RL pollutant_forcingPeriod
      _RL pollutant_forcingCycle
      _RL pollutant_Tc
      _RL pollutant_k_dark_20_d
      _RL pollutant_Q10_dark
      _RL pollutant_k_bio_20_d
      _RL pollutant_Q10_bio
      _RL pollutant_k_OH_d
      _RL pollutant_k_photo_d
      _RL pollutant_light_atten
      _RL pollutant_k_dark_20
      _RL pollutant_k_bio_20
      _RL pollutant_k_OH
      _RL pollutant_k_photo

      LOGICAL usePollutantDegradation
      LOGICAL pollutant_fluxIsCellTotal

      CHARACTER*(MAX_LEN_FNAM) pollutant_emission_file

C--   COMMON /POLLUTANT_LOAD/
C     pollutant_ldRec :: time-record currently loaded
      COMMON /POLLUTANT_LOAD_I/ pollutant_ldRec
      INTEGER pollutant_ldRec(nSx,nSy)

      COMMON /POLLUTANT_LOAD_RL/
     &        pollutant_flux0, pollutant_flux1
      _RL pollutant_flux0(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL pollutant_flux1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

C--   COMMON /POLLUTANT_FIELDS/
C     pollutant_flux    :: pollutant emission flux
C                          mol/s per grid if pollutant_fluxIsCellTotal=T
C                          mol/m^2/s if pollutant_fluxIsCellTotal=F
C     pollutant_conc    :: pollutant concentration (mol/m^3)
C     pollutant_mass    :: pollutant mass per grid cell (mol)

      COMMON /POLLUTANT_FIELDS/
     &              pollutant_flux, pollutant_conc, pollutant_mass
      _RS pollutant_flux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL pollutant_conc(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL pollutant_mass(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)

C--   COMMON /POLLUTANT_BUDGET/
C     pollutant_globalMass   :: instantaneous global inventory [mol]
C     pollutant_globalSource :: instantaneous global source  [mol/s]
C     pollutant_globalSink   :: instantaneous global sink    [mol/s]
C     pollutant_cumuSource   :: cumulative global source     [mol]
C     pollutant_cumuSink     :: cumulative global sink       [mol]

      COMMON /POLLUTANT_BUDGET/
     &    pollutant_globalMass,
     &    pollutant_globalSource,
     &    pollutant_globalSink,
     &    pollutant_cumuSource,
     &    pollutant_cumuSink

      _RL pollutant_globalMass
      _RL pollutant_globalSource
      _RL pollutant_globalSink
      _RL pollutant_cumuSource
      _RL pollutant_cumuSink

C--   COMMON /POLLUTANT_BUDGET_CTRL/
C     pollutant_budgetIter :: iteration counter used to reset accumulators
      COMMON /POLLUTANT_BUDGET_CTRL/
     &    pollutant_budgetIter

       INTEGER pollutant_budgetIter

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
