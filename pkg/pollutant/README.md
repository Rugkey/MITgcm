# MITgcm Pollutant Package (pkg/pollutant)

## 1. Overview

The `pkg/pollutant` is a flexible package for simulating the source, transport, and sink of a generic pollutant within the MITgcm framework. It is built upon the `ptracers` (passive tracers) and `gchem` (generic chemistry) packages.

This package allows users to:
- Define a pollutant as a passive tracer.
- Introduce pollutant sources via surface emission fluxes from a file.
- Simulate a unified degradation (sink) process that is dependent on water temperature, following a first-order kinetics model with an optional zeroth-order term.

## 2. Dependencies and Compilation

### 2.1. Required Packages

To use `pkg/pollutant`, you must enable the following packages in your `packages.conf` file (e.g., located in `code/` or `build/`):

```
ptracers
gchem
pollutant
```

### 2.2. Required C-Preprocessor Options

The `gchem` package requires a specific C-preprocessor flag to ensure that the pollutant's source/sink tendencies are correctly applied to the tracer. You must add the following line to your `GCHEM_OPTIONS.h` file (e.g., located in `code/`):

```c
#define GCHEM_ADD2TR_TENDENCY
```

### 2.3. Building the Model

After configuring `packages.conf` and `GCHEM_OPTIONS.h`, compile the model from your build directory (e.g., `build/`) as usual:

```bash
make clean
make depend
make
```

## 3. Runtime Configuration

To run a simulation with `pkg/pollutant`, you need to configure three main input files: `data.ptracers`, `data.pollutant`, and `data.diagnostics`.

### 3.1. `data.ptracers` - Defining the Pollutant Tracer

This file tells the model to activate a passive tracer for the pollutant.

**Example:**
```
&PTRACERS_PARM01
 PTRACERS_numInUse       = 1,
 PTRACERS_names(1)       = 'Pollutant',
 PTRACERS_advScheme(1)   = 77,
 PTRACERS_initialFile(1) = 'pollutant_initial.bin',
 PTRACERS_enforcePositive(1) = .TRUE.,
/
```
- `PTRACERS_numInUse`: Set to the number of tracers you are using.
- `PTRACERS_names(1)`: A descriptive name for the tracer.
- `PTRACERS_initialFile(1)`: Path to a binary file containing the initial 3D concentration field of the pollutant.

### 3.2. `data.pollutant` - Configuring Sources and Sinks

This is the main configuration file for the pollutant package.

**Example:**
```
&POLLUTANT_PARAMS
  pollutant_emission_file   = 'pollutant_emission.bin',
  pollutant_forcingPeriod   = 900.,
  pollutant_forcingCycle    = 900.,
  pollutant_fluxIsCellTotal = .TRUE.,

  usePollutantDegradation = .TRUE.,
  pollutant_k0_deg_d      = 0.0,
  pollutant_Tc            = 0.0,
  pollutant_k1_deg_20_d   = 0.0231,
  pollutant_kt_deg        = 1.047,
  pollutant_fr_deg        = 1.0,
/
```

**Parameter Descriptions:**

**Source Term:**
- `pollutant_emission_file`: Path to the binary file containing the 2D surface emission flux data.
- `pollutant_forcingPeriod`: The time in seconds at which the forcing data is updated (e.g., `86400.` for daily).
- `pollutant_forcingCycle`: The period in seconds over which the forcing data file repeats (e.g., `31536000.` for a yearly cycle).
- `pollutant_fluxIsCellTotal`: Defines the units of the emission file.
  - `.TRUE.`: The file contains total flux per grid cell (units: `mol/s`). The model will convert it to a flux density (`mol/m^2/s`).
  - `.FALSE.`: The file already contains flux density (`mol/m^2/s`).

**Sink (Degradation) Term:**
- `usePollutantDegradation`: (`.TRUE.`/`.FALSE.`) Master switch to enable or disable the degradation process.
- `pollutant_k0_deg_d`: The zeroth-order degradation rate (units: `g/m^3/d`). This rate is applied constantly, independent of concentration or temperature. Defaults to `0.0`.
- `pollutant_Tc`: The critical temperature (units: `degC`). The first-order degradation only occurs when the water temperature is *above* this value.
- `pollutant_k1_deg_20_d`: The first-order degradation rate at a reference temperature of 20°C (units: `d^-1`).
- `pollutant_kt_deg`: The dimensionless temperature coefficient used in the degradation formula `k_t^(T-20)`.
- `pollutant_fr_deg`: The fraction (from 0 to 1) of the pollutant concentration that is subject to first-order degradation.

### 3.3. `data.diagnostics` - Setting Up Output

This file controls which variables are written to output files.

**Example:**
```
&DIAGNOSTICS_LIST
  fields(1:3,1) = 'POLLUT_S','POLLUT_K','POLLUT_T',
  fileName(1)   = 'output/pollutant_tendency',
  frequency(1)  = -86400.,

  fields(1:2,2) = 'TRAC01  ','POLLUT_M',
  fileName(2)   = 'output/pollutant_state',
  frequency(2)  = -86400.,
/
```
- A negative `frequency` (e.g., `-86400.`) requests a time-average (e.g., daily average).
- A positive `frequency` (e.g., `900.`) requests a snapshot at that interval.

## 4. Diagnostic Variables

The following variables can be requested in `data.diagnostics`:

- `POLLUT_S`: Source term (`mol/m^3/s`)
- `POLLUT_K`: Total sink term (`mol/m^3/s`)
- `POLLUT_T`: Net tendency (Source - Sink) (`mol/m^3/s`)
- `POLLUT_M`: Pollutant mass per grid cell (`mol`)
- `POLLUT_F`: 2D surface flux (`mol/m^2/s`)

## 5. Quick Start Example

1.  **`packages.conf`**: Add `ptracers`, `gchem`, `pollutant`.
2.  **`code/GCHEM_OPTIONS.h`**: Add `#define GCHEM_ADD2TR_TENDENCY`.
3.  **Compile**: `make clean && make depend && make`.
4.  **`data.ptracers`**: Configure `PTRACERS_PARM01` to use at least one tracer.
5.  **`data.pollutant`**: Create the file with the `&POLLUTANT_PARAMS` namelist as shown in the example above.
6.  **`data.diagnostics`**: Configure your desired output files.
7.  **Run the model**.
