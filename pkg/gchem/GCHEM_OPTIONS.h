#ifndef GCHEM_OPTIONS_H
#define GCHEM_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

#ifdef ALLOW_GCHEM

C-- Collect here all CPP options for the gchem package.
C-- You can modify this file, but it is recommended to use
C-- the GCHEM_OPTIONS.h file in your own experiment directory.

C o This is the main switch for gchem.
#define GCHEM_ADD2TR_TENDENCY

#endif /* ALLOW_GCHEM */
#endif /* GCHEM_OPTIONS_H */
