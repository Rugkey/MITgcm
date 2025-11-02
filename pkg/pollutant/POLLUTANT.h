C     *==========================================================*
C     | POLLUTANT.h
C     | o Ocean Pollutant Variables
C     *==========================================================*

C--   COMMON /POLLUTANT_PARMS/
C     ========================
C     This common block holds all pollutant package parameters.

C--   User-input half-life parameters [days]
C     pollutant_decay_halflife_d     :: half-life for decay
C     pollutant_settle_halflife_d    :: half-life for phase change (settling)
C     pollutant_biouptake_halflife_d :: half-life for bio-uptake

C--   Logical flags for processes
C     usePollutantDecay     :: flag to turn on/off decay process
C     usePollutantSettling  :: flag to turn on/off settling process (phase change)
C     usePollutantBioUptake :: flag to turn on/off bio-uptake process
C     pollutant_fluxIsCellTotal :: if .TRUE., input emission is mol/s per grid-cell

C--   Parameters for temperature and depth dependent decay
C     useTempDependentDecay :: flag to enable temperature-dependent decay rate
C     decayTempRef          :: reference temperature for decay rate [degC]
C     decayQ10              :: Q10 temperature coefficient for decay rate
C     useDepthDependentDecay:: flag to enable depth-dependent decay rate (light proxy)
C     decayDepthScale       :: e-folding depth scale for decay rate reduction [m]

C--   Internal rate constants [1/s] (calculated from half-lives)
C     pollutant_decay_rate      :: base decay rate constant at reference temp
C     pollutant_settle_rate     :: phase change rate from dissolved to particulate
C     pollutant_biouptake_rate  :: bio-uptake rate constant

      COMMON /POLLUTANT_PARMS/
     &              usePollutantDecay,
     &              usePollutantSettling,
     &              usePollutantBioUptake,
     &              pollutant_fluxIsCellTotal,
     &              useTempDependentDecay,
     &              useDepthDependentDecay,
     &              pollutant_decay_rate,
     &              pollutant_settle_rate,
     &              pollutant_biouptake_rate,
     &              pollutant_forcingPeriod,
     &              pollutant_forcingCycle,
     &              decayTempRef,
     &              decayQ10,
     &              decayDepthScale,
     &              pollutant_emission_file,
     &              pollutant_decay_halflife_d,
     &              pollutant_settle_halflife_d,
     &              pollutant_biouptake_halflife_d

      LOGICAL usePollutantDecay
      LOGICAL usePollutantSettling
      LOGICAL usePollutantBioUptake
      LOGICAL pollutant_fluxIsCellTotal
      LOGICAL useTempDependentDecay
      LOGICAL useDepthDependentDecay

      _RL pollutant_decay_rate
      _RL pollutant_settle_rate
      _RL pollutant_biouptake_rate
      _RL pollutant_forcingPeriod
      _RL pollutant_forcingCycle
      _RL decayTempRef
      _RL decayQ10
      _RL decayDepthScale
      _RL pollutant_decay_halflife_d
      _RL pollutant_settle_halflife_d
      _RL pollutant_biouptake_halflife_d

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
C  decayAve      :: pollutant decay term [mol/m3/s]
C  settlingAve   :: pollutant settling term [mol/m3/s]
C  bioUptakeAve  :: pollutant bio-uptake term [mol/m3/s]
C  POLLUTANT_timeAve :: period over which POLLUTANT averages are calculated [s]

      COMMON /POLLUTANT_TAVE/
     &     sourceAve, sinkAve, decayAve, settlingAve, bioUptakeAve,
     &     POLLUTANT_timeAve

      _RL sourceAve    (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL sinkAve      (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL decayAve     (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL settlingAve  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL bioUptakeAve (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL POLLUTANT_timeAve(nSx,nSy)
#endif /* ALLOW_TIMEAVE */



C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|



