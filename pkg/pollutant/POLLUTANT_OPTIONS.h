#ifndef POLLUTANT_OPTIONS_H
#define POLLUTANT_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

#ifdef ALLOW_POLLUTANT
C     Package-specific Options & Macros go here

C     the following is required to couple to gchem
#define ALLOW_GCHEM

C     the following is required to couple to ptracers
#define ALLOW_PTRACERS

C     the following is required to couple to exf for photolysis
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
#endif

#endif /* ALLOW_POLLUTANT */
#endif /* POLLUTANT_OPTIONS_H */
