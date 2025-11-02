#ifdef ALLOW_GCHEM

CBOP
C    !ROUTINE: GCHEM.h
C    !INTERFACE:

C    !DESCRIPTION:
C Contains tracer parameters and input files for chemical tracers.
C These can be read in from data.gchem
C
C--   COMMON /GCHEM_PARM_L/ Logical valued parameters used by GCHEM pkg.
C     useCFC    :: flag to turn on/off CFC pkg
C     useDIC    :: flag to turn on/off DIC pkg
C     useBLING  :: flag to turn on/off BLING pkg
C     useSPOIL  :: flag to turn on/off SPOIL pkg
C     useDARWIN :: flag to turn on/off darwin pkg
C     usePOLLUTANT :: flag to turn on/off POLLUTANT pkg

      COMMON /GCHEM_PARM_L/
     &              useCFC,
     &              useDIC,
     &              useBLING,
     &              useSPOIL,
     &              useDARWIN,
     &              usePOLLUTANT
      LOGICAL useCFC, useDIC, useBLING, useSPOIL, useDARWIN
      LOGICAL usePOLLUTANT

      COMMON /GCHEM_PARM_C/
     &                   fileName1, fileName2, fileName3,
     &                   fileName4, fileName5
      CHARACTER*(MAX_LEN_FNAM) fileName1
      CHARACTER*(MAX_LEN_FNAM) fileName2
      CHARACTER*(MAX_LEN_FNAM) fileName3
      CHARACTER*(MAX_LEN_FNAM) fileName4
      CHARACTER*(MAX_LEN_FNAM) fileName5

      COMMON /GCHEM_PARM_I/
     &           gchem_Tracer_num, gchem_sepFTr_num,
     &           nsubtime,   gchem_int1, gchem_int2,
     &           gchem_int3, gchem_int4, gchem_int5
      INTEGER gchem_Tracer_num
      INTEGER gchem_sepFTr_num
      INTEGER nsubtime
      INTEGER gchem_int1
      INTEGER gchem_int2
      INTEGER gchem_int3
      INTEGER gchem_int4
      INTEGER gchem_int5

      COMMON /GCHEM_PARM_R/
     &           gchem_rl1, gchem_rl2, gchem_rl3,
     &           gchem_rl4, gchem_rl5,
     &           gchem_ForcingPeriod, gchem_ForcingCycle
      _RL     gchem_rl1
      _RL     gchem_rl2
      _RL     gchem_rl3
      _RL     gchem_rl4
      _RL     gchem_rl5
      _RL     gchem_ForcingPeriod
      _RL     gchem_ForcingCycle

#endif /* ALLOW_GCHEM */
