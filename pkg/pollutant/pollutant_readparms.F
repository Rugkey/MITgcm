#include "GCHEM_OPTIONS.h"
#include "POLLUTANT_OPTIONS.h"

CBOP
C     !ROUTINE: POLLUTANT_READPARMS
C     !INTERFACE:
      SUBROUTINE POLLUTANT_READPARMS( myThid )

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | S/R POLLUTANT_READPARMS
C     | o Initialise and read pollutant package parameters
C     *==========================================================*
C     \ev

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "POLLUTANT.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myThid    :: My Thread Id. number
      INTEGER myThid
CEOP

#ifdef ALLOW_POLLUTANT

C     === Local variables ===
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit
      INTEGER errCount
      _RL     SECONDS_PER_DAY

C--   Namelist for pollutant package parameters
      NAMELIST /POLLUTANT_PARAMS/
     &          usePollutantDegradation,
     &          pollutant_fluxIsCellTotal,
     &          pollutant_forcingPeriod,
     &          pollutant_forcingCycle,
     &          pollutant_emission_file,
     &          pollutant_Tc,
     &          pollutant_k_dark_20_d,
     &          pollutant_Q10_dark,
     &          pollutant_k_bio_20_d,
     &          pollutant_Q10_bio,
     &          pollutant_k_OH_d,
     &          pollutant_k_photo_d,
     &          pollutant_light_atten,
     &          usePollutantAirSeaExchange,
     &          pollutant_henryConst,
     &          pollutant_schmidtRef,
     &          pollutant_schmidtExp,
     &          pollutant_schmidtA0,
     &          pollutant_schmidtA1,
     &          pollutant_schmidtA2,
     &          pollutant_schmidtA3,
     &          pollutant_pistonCoeff,
     &          pollutant_minWind,
     &          pollutant_defaultWind,
     &          pollutant_atmConcConst,
     &          pollutant_atmConc_file,
     &          pollutant_precipConst,
     &          pollutant_useDryDeposition,
     &          pollutant_dryDepVelConst,
     &          pollutant_dryDepVel_file,
     &          pollutant_useWetDeposition,
     &          pollutant_wetDepConcConst,
     &          pollutant_wetDepConc_file

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      _BEGIN_MASTER(myThid)
       errCount = 0

C--   Set default values
       usePollutantDegradation = .FALSE.
       pollutant_fluxIsCellTotal = .FALSE.

       pollutant_forcingPeriod = externForcingPeriod
       pollutant_forcingCycle  = externForcingCycle

       pollutant_Tc              = -100. _d 0
       pollutant_k_dark_20_d   = 0. _d 0
       pollutant_Q10_dark      = 2.0 _d 0
       pollutant_k_bio_20_d    = 0. _d 0
       pollutant_Q10_bio       = 2.0 _d 0
       pollutant_k_OH_d        = 0. _d 0
       pollutant_k_photo_d     = 0. _d 0
       pollutant_light_atten   = 0. _d 0

       pollutant_emission_file = 'pollutant_emission.bin'
      usePollutantAirSeaExchange = .FALSE.
      pollutant_henryConst    = 0. _d 0
      pollutant_schmidtRef    = 660. _d 0
      pollutant_schmidtExp    = 0.5 _d 0
      pollutant_schmidtA0     = 660. _d 0
      pollutant_schmidtA1     = 0. _d 0
      pollutant_schmidtA2     = 0. _d 0
      pollutant_schmidtA3     = 0. _d 0
      pollutant_pistonCoeff   = 0.31 _d 0
      pollutant_minWind       = 0.5 _d 0
      pollutant_defaultWind   = 5. _d 0
      pollutant_atmConcConst  = 0. _d 0
      pollutant_atmConc_file  = ' '
      pollutant_precipConst   = 0. _d 0
      pollutant_useDryDeposition = .FALSE.
      pollutant_dryDepVelConst = 0. _d 0
      pollutant_dryDepVel_file = ' '
      pollutant_useWetDeposition = .FALSE.
      pollutant_wetDepConcConst = 0. _d 0
      pollutant_wetDepConc_file = ' '

      WRITE(msgBuf,'(A)') ' POLLUTANT_READPARMS: opening data.pollutant'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE( 'data.pollutant', 'POLLUTANT_READPARMS', 
     O                          iUnit, myThid )

C--   Read parameters from open data file:
      READ(UNIT=iUnit,NML=POLLUTANT_PARAMS)

      WRITE(msgBuf,'(A)')
     &   ' POLLUTANT_READPARMS: finished reading data.pollutant'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     I                    SQUEEZE_RIGHT, myThid )

C--   Close the open data file
#ifdef SINGLE_DISK_IO
      CLOSE(iUnit)
#else
      CLOSE(iUnit,STATUS='DELETE')
#endif /* SINGLE_DISK_IO */

C--   Convert degradation rates from d^-1 to s^-1
      SECONDS_PER_DAY = 86400. _d 0

      pollutant_k_dark_20 = pollutant_k_dark_20_d / SECONDS_PER_DAY
      pollutant_k_bio_20  = pollutant_k_bio_20_d  / SECONDS_PER_DAY
      pollutant_k_OH      = pollutant_k_OH_d      / SECONDS_PER_DAY
      pollutant_k_photo   = pollutant_k_photo_d   / SECONDS_PER_DAY

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Parameter validation
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( pollutant_k_dark_20_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k_dark_20_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_k_bio_20_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k_bio_20_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_k_OH_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k_OH_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_k_photo_d .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_k_photo_d must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

      IF ( pollutant_light_atten .LT. 0. _d 0 ) THEN
        WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_light_atten must be >= 0'
        CALL PRINT_ERROR( msgBuf, myThid )
        errCount = errCount + 1
      ENDIF

         IF ( pollutant_henryConst .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_henryConst must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_schmidtRef .LE. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &    'pollutant_schmidtRef must be > 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_pistonCoeff .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_pistonCoeff must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_minWind .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_minWind must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_defaultWind .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_defaultWind must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_precipConst .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_precipConst must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_dryDepVelConst .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_dryDepVelConst must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

         IF ( pollutant_wetDepConcConst .LT. 0. _d 0 ) THEN
            WRITE(msgBuf,'(2A)') 'POLLUTANT_READPARMS: ',
     &      'pollutant_wetDepConcConst must be >= 0'
            CALL PRINT_ERROR( msgBuf, myThid )
            errCount = errCount + 1
         ENDIF

C--   Check for fatal errors
      IF ( errCount.GE.1 ) THEN
        WRITE(msgBuf,'(A,I3,A)')
     &       'POLLUTANT_READPARMS: detected', errCount,' fatal error(s)'
        CALL PRINT_ERROR( msgBuf, myThid )
        CALL ALL_PROC_DIE( 0 )
        STOP 'ABNORMAL END: S/R POLLUTANT_READPARMS'
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Print out parameter values
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      iUnit = standardMessageUnit
      WRITE(msgBuf,'(A)') ' '
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// POLLUTANT package parameters :'
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)
      WRITE(msgBuf,'(A)') '// ==================================='
      CALL PRINT_MESSAGE(msgBuf,iUnit,SQUEEZE_RIGHT,myThid)

      CALL WRITE_0D_L( usePollutantDegradation, INDEX_NONE,
     &  'usePollutantDegradation =',
     &  '  /* .TRUE. to enable pollutant degradation */')
      IF (usePollutantDegradation) THEN
        CALL WRITE_0D_RL( pollutant_Tc, INDEX_NONE,
     &    'pollutant_Tc =',
     &    ' /* Critical temperature for degradation [degC] */')
        CALL WRITE_0D_RL( pollutant_k_dark_20_d, INDEX_NONE,
     &    'pollutant_k_dark_20_d =',
     &    ' /* Dark degradation rate at 20C [d^-1] */')
        CALL WRITE_0D_RL( pollutant_Q10_dark, INDEX_NONE,
     &    'pollutant_Q10_dark =',
     &    ' /* Q10 temp coefficient for dark degradation */')
        CALL WRITE_0D_RL( pollutant_k_bio_20_d, INDEX_NONE,
     &    'pollutant_k_bio_20_d =',
     &    ' /* Biological degradation rate at 20C [d^-1] */')
        CALL WRITE_0D_RL( pollutant_Q10_bio, INDEX_NONE,
     &    'pollutant_Q10_bio =',
     &    ' /* Q10 temp coefficient for biological degradation */')
        CALL WRITE_0D_RL( pollutant_k_OH_d, INDEX_NONE,
     &    'pollutant_k_OH_d =',
     &    ' /* Indirect photolysis (OH) rate [d^-1] */')
        CALL WRITE_0D_RL( pollutant_k_photo_d, INDEX_NONE,
     &    'pollutant_k_photo_d =',
     &    ' /* Surface direct photolysis rate [d^-1] */')
        CALL WRITE_0D_RL( pollutant_light_atten, INDEX_NONE,
     &    'pollutant_light_atten =',
     &    ' /* Light attenuation coefficient [m^-1] */')
      ENDIF

      CALL WRITE_0D_L( usePollutantAirSeaExchange, INDEX_NONE,
     &  'usePollutantAirSeaExchange =',
     &  ' /* Enable wind-driven air-sea exchange */')
      IF ( usePollutantAirSeaExchange ) THEN
        CALL WRITE_0D_RL( pollutant_henryConst, INDEX_NONE,
     &    'pollutant_henryConst =',
     &    ' /* Henry solubility (mol/m3 per mol/m3 air) */')
        CALL WRITE_0D_RL( pollutant_schmidtRef, INDEX_NONE,
     &    'pollutant_schmidtRef =',
     &    ' /* Reference Schmidt number */')
        CALL WRITE_0D_RL( pollutant_schmidtExp, INDEX_NONE,
     &    'pollutant_schmidtExp =',
     &    ' /* Exponent for Schmidt scaling */')
        CALL WRITE_0D_RL( pollutant_schmidtA0, INDEX_NONE,
     &    'pollutant_schmidtA0 =',
     &    ' /* Schmidt polynomial constant term */')
        CALL WRITE_0D_RL( pollutant_schmidtA1, INDEX_NONE,
     &    'pollutant_schmidtA1 =',
     &    ' /* Schmidt polynomial linear term */')
        CALL WRITE_0D_RL( pollutant_schmidtA2, INDEX_NONE,
     &    'pollutant_schmidtA2 =',
     &    ' /* Schmidt polynomial quadratic term */')
        CALL WRITE_0D_RL( pollutant_schmidtA3, INDEX_NONE,
     &    'pollutant_schmidtA3 =',
     &    ' /* Schmidt polynomial cubic term */')
        CALL WRITE_0D_RL( pollutant_pistonCoeff, INDEX_NONE,
     &    'pollutant_pistonCoeff =',
     &    ' /* Wind^2 coefficient for piston velocity */')
        CALL WRITE_0D_RL( pollutant_minWind, INDEX_NONE,
     &    'pollutant_minWind =',
     &    ' /* Minimum wind speed used in piston velocity */')
        CALL WRITE_0D_RL( pollutant_defaultWind, INDEX_NONE,
     &    'pollutant_defaultWind =',
     &    ' /* Fallback wind speed (m/s) */')
        CALL WRITE_0D_RL( pollutant_atmConcConst, INDEX_NONE,
     &    'pollutant_atmConcConst =',
     &    ' /* Constant atmospheric concentration [mol/m3] */')
        CALL WRITE_0D_C( pollutant_atmConc_file, -1, INDEX_NONE,
     &    'pollutant_atmConc_file =',
     &    ' /* Optional atmospheric concentration file */')
        CALL WRITE_0D_RL( pollutant_precipConst, INDEX_NONE,
     &    'pollutant_precipConst =',
     &    ' /* Constant precipitation rate [m/s] */')
        CALL WRITE_0D_L( pollutant_useDryDeposition, INDEX_NONE,
     &    'pollutant_useDryDeposition =',
     &    ' /* Enable dry deposition flux */')
        IF ( pollutant_useDryDeposition ) THEN
          CALL WRITE_0D_RL( pollutant_dryDepVelConst, INDEX_NONE,
     &      'pollutant_dryDepVelConst =',
     &      ' /* Dry deposition velocity [m/s] */')
      CALL WRITE_0D_C( pollutant_dryDepVel_file, -1, INDEX_NONE,
     &      'pollutant_dryDepVel_file =',
     &      ' /* Optional dry deposition velocity file */')
        ENDIF
        CALL WRITE_0D_L( pollutant_useWetDeposition, INDEX_NONE,
     &    'pollutant_useWetDeposition =',
     &    ' /* Enable wet deposition flux */')
        IF ( pollutant_useWetDeposition ) THEN
          CALL WRITE_0D_RL( pollutant_wetDepConcConst, INDEX_NONE,
     &      'pollutant_wetDepConcConst =',
     &      ' /* Rainwater pollutant concentration [mol/m3] */')
      CALL WRITE_0D_C( pollutant_wetDepConc_file, -1, INDEX_NONE,
     &      'pollutant_wetDepConc_file =',
     &      ' /* Optional rain concentration file */')
        ENDIF
      ENDIF

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

#endif /* ALLOW_POLLUTANT */

      RETURN
      END
