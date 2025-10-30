C     *==========================================================*
C     | POLLUTANT.h
C     | o Ocean Pollutant Variables
C     *==========================================================*

C--   COMMON /POLLUTANT_PARAMS_L/
C     usePollutantDecay     :: flag to turn on/off decay process
C     usePollutantSettling  :: flag to turn on/off settling process
C     usePollutantBioUptake :: flag to turn on/off bio-uptake process
C     usePollutantAdvection :: flag to turn on/off advection
C     usePollutantDiffusion :: flag to turn on/off diffusion

      COMMON /POLLUTANT_PARAMS_L/
     &              usePollutantDecay,
     &              usePollutantSettling,
     &              usePollutantBioUptake,
     &              usePollutantAdvection,
     &              usePollutantDiffusion
      LOGICAL usePollutantDecay
      LOGICAL usePollutantSettling
      LOGICAL usePollutantBioUptake
      LOGICAL usePollutantAdvection
      LOGICAL usePollutantDiffusion

C--   COMMON /POLLUTANT_PARAMS_R/
C     pollutant_decay_rate      :: decay rate constant (1/s)
C     pollutant_settle_rate     :: settling rate constant (1/s)
C     pollutant_biouptake_rate  :: bio-uptake rate constant (1/s)
C     pollutant_forcingPeriod   :: forcing period (seconds)
C     pollutant_forcingCycle     :: forcing cycle (seconds)
C     pollutant_monFreq         :: frequency for pollutant monitor (s)

      COMMON /POLLUTANT_PARAMS_R/
     &              pollutant_decay_rate,
     &              pollutant_settle_rate,
     &              pollutant_biouptake_rate,
     &              pollutant_forcingPeriod,
     &              pollutant_forcingCycle,
     &              pollutant_monFreq
      _RL pollutant_decay_rate
      _RL pollutant_settle_rate
      _RL pollutant_biouptake_rate
      _RL pollutant_forcingPeriod
      _RL pollutant_forcingCycle
      _RL pollutant_monFreq

C--   COMMON /POLLUTANT_FILENAMES/
C     pollutant_emission_file :: file name of pollutant emission flux

      COMMON /POLLUTANT_FILENAMES/
     &              pollutant_emission_file
      CHARACTER*(MAX_LEN_FNAM) pollutant_emission_file

C--   COMMON /POLLUTANT_FIELDS/
C     pollutant_flux    :: pollutant emission flux (mol/m^2/s)

      COMMON /POLLUTANT_FIELDS/
     &              pollutant_flux
      _RS pollutant_flux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

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
