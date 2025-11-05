C $Header: /u/gcmpack/MITgcm/pkg/microp/MICROP.h,v 1.5 2011/04/17 21:01:36 jmc Exp $
C $Name: checkpoint64g $

C     *==========================================================*
C     | MICROP.h
C     *==========================================================*

       COMMON /MICROP_NEEDS/
     &              MICROPRiver
      _RL  MICROPRiver(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

C     time-record currently loaded (in temp arrays *[1])
      COMMON /MICROP_LOAD_I/ MICROP_ldRec_forcing, MICROP_ldRec_chem
      INTEGER MICROP_ldRec_forcing(nSx,nSy), MICROP_ldRec_chem(nSx,nSy)

      COMMON /MICROP_LOAD/
     &    MICROPriver0, MICROPriver1
      _RS MICROPriver0 (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RS MICROPriver1 (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

C--   COMMON /MICROP_FILENAMES/
C  MICROP_forcingPeriod :: periodic forcing parameter specific for microp (seconds)
C  MICROP_forcingCycle  :: periodic forcing parameter specific for microp (seconds)
C  MICROP_chemPeriod :: periodic forcing parameter specific for microp (seconds)
C  MICROP_chemCycle  :: periodic forcing parameter specific for microp (seconds)

C  MICROP_riverFile    :: file name of microp riverine runoff
      COMMON /MICROP_FILENAMES/
     &        MICROP_forcingPeriod, MICROP_forcingCycle,
     &        MICROP_chemPeriod, MICROP_chemCycle,	 
     &        MICROP_riverFile

	  CHARACTER*(MAX_LEN_FNAM) MICROP_riverFile
      _RL     MICROP_forcingPeriod   
      _RL     MICROP_forcingCycle
      _RL     MICROP_chemPeriod   
      _RL     MICROP_chemCycle

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
