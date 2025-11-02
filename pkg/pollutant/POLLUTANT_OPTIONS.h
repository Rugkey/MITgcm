#ifndef POLLUTANT_OPTIONS_H
#define POLLUTANT_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

#ifdef ALLOW_POLLUTANT

CBOP
C    !ROUTINE: POLLUTANT_OPTIONS.h
C    !INTERFACE:

C    !DESCRIPTION:
C options for ocean pollutant package
CEOP

C o Allow pollutant decay process
#define POLLUTANT_DECAY

C o Allow pollutant settling process  
#define POLLUTANT_SETTLING

C o Allow pollutant bio-uptake process
#define POLLUTANT_BIOUPTAKE

C o Allow pollutant advection
#define POLLUTANT_ADVECTION

C o Allow pollutant diffusion
#define POLLUTANT_DIFFUSION

C o Allow pollutant diagnostics
#define POLLUTANT_DIAGNOSTICS

#endif /* ALLOW_POLLUTANT */
#endif /* POLLUTANT_OPTIONS_H */
