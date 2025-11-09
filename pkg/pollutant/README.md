# MITgcm 污染物模块 (`pkg/pollutant`)

## 1. 概述

`pkg/pollutant` 是一个灵活的软件包，用于在 MITgcm 框架内模拟通用污染物的源、传输和汇过程。它构建于 `ptracers` (被动示踪剂) 和 `gchem` (通用化学) 模块之上。

该模块允许用户：
- 将污染物定义为一个被动示踪剂。
- 通过文件引入表层排放通量作为污染物的源。
- 模拟一个综合性的化学和生物降解（汇）过程，该过程基于伪一级动力学，并考虑了温度和光照的影响。

---

## 2. 如何构建 `pollutant` 模块

本节将指导您如何配置和编译一个包含 `pollutant` 模块的 MITgcm 实验。

### 2.1. 依赖关系

`pollutant` 模块依赖于以下几个核心的 MITgcm 模块。您必须确保它们都被激活。

- **`gchem`**: 通用化学框架，用于管理示踪剂的源汇项。
- **`ptracers`**: 被动示踪剂框架，用于定义和传输污染物。
- **`exf`**: 外部强迫模块，用于提供光解作用所需的向下短波辐射数据。
- **`cal`**: 日历模块，`exf` 包需要它来解析日期格式的强迫场时间信息。

### 2.2. 配置文件

在一个新的或已有的实验目录中 (例如 `verification/my_experiment/code/`)，您需要修改 `packages.conf` 文件，确保以上所有依赖的模块以及 `pollutant` 模块本身都被列出：

**`code/packages.conf` 示例:**
```
gchem
ptracers
exf
cal
pollutant
```

### 2.3. 编译选项

`pollutant` 模块通过 `gchem` 与模型核心进行交互。为了确保 `gchem` 能正确地将 `pollutant` 计算出的源汇项应用到示踪剂上，您必须在 `code/GCHEM_OPTIONS.h` 文件中添加一个宏定义。如果该文件不存在，请创建它。

**`code/GCHEM_OPTIONS.h`:**
```c
#ifndef GCHEM_OPTIONS_H
#define GCHEM_OPTIONS_H
#include "PACKAGES_CONFIG.h"

// 允许 gchem 将计算出的趋势项应用到 ptracers
#define GCHEM_ADD2TR_TENDENCY

#endif /* GCHEM_OPTIONS_H */
```

### 2.4. 编译模型

完成以上配置后，进入您的实验构建目录 (例如 `verification/my_experiment/build/`) 并运行标准编译命令。强烈建议在修改 `packages.conf` 后执行 `make clean` 和 `make depend`。

```bash
make clean
make depend
make
```

如果编译成功，您将在 `input/` 或 `run/` 目录中得到一个可执行文件 `mitgcmuv`，该文件已包含了完整的 `pollutant` 功能。

---

## 3. 用户使用手册

本节将详细介绍如何在一个已成功编译的实验中，配置和使用 `pollutant` 模块。

### 3.1. 降解 (汇) 模型公式

污染物的降解遵循伪一级动力学模型，其浓度 `C` (mol/m³) 的变化率由以下公式给出：

$$ \frac{dC}{dt} = -k_{tot} \cdot C $$

其中 `k_tot` 是总降解速率常数 (s⁻¹)。该总速率由几个独立的过程组成：

$$ k_{tot} = k_{dark}(T) + k_{bio}(T) + k_{OH} + k_{photo}(z) $$

- **暗化学与生物降解 (`k_dark`, `k_bio`)**: 速率随温度 `T` 变化，通过 Q10 公式进行修正。
- **间接光解 (`k_OH`)**: 假定为一个常数速率。
- **直接光解 (`k_photo`)**: 速率随深度 `z` 呈指数衰减，依赖于海表的向下短波辐射。

### 3.2. 核心配置文件

您需要在实验的 `input/` 目录下配置以下几个文件：

#### `data.pkg`

确保 `gchem` 和 `pollutant` 模块在运行时被激活。

```
 &PACKAGES
  useGCHEM     = .TRUE.,
  usePOLLUTANT = .TRUE.,
  useDiagnostics = .TRUE.,
  useEXF       = .TRUE.,
 & 
```

#### `data.ptracers`

定义一个被动示踪剂来代表污染物。

```
 &PTRACERS_PARM01
  PTRACERS_numInUse=1,
  PTRACERS_names(1)='Pollutant',
  PTRACERS_initialFile(1)='pollutant_initial.bin',
 & 
```
- `PTRACERS_numInUse`: 示踪剂数量。
- `PTRACERS_names(1)`: 示踪剂的名称。
- `PTRACERS_initialFile(1)`: 初始浓度场的二进制文件路径。如果设为空字符串 `' '`，则从零开始。

#### `data.pollutant`

这是 `pollutant` 模块的主要配置文件，用于设置源和汇的参数。

```
 &POLLUTANT_PARAMS
# --- 源项参数 ---
  pollutant_emission_file   = 'pollutant_emission.bin',
  pollutant_forcingPeriod   = 86400.,
  pollutant_forcingCycle    = 31536000.,
  pollutant_fluxIsCellTotal = .FALSE.,

# --- 汇 (降解) 项参数 ---
  usePollutantDegradation = .TRUE.,
  pollutant_Tc            = 4.0,

  pollutant_k_dark_20_d   = 0.01,
  pollutant_Q10_dark      = 2.0,

  pollutant_k_bio_20_d    = 0.005,
  pollutant_Q10_bio       = 2.2,

  pollutant_k_OH_d        = 0.001,

  pollutant_k_photo_d     = 0.1,
  pollutant_light_atten   = 0.15,
 & 
```

**参数说明:**
- `pollutant_emission_file`: 包含2D表层排放通量数据的二进制文件路径。
- `pollutant_forcingPeriod`: 强迫场数据的时间间隔 (秒)。
- `pollutant_forcingCycle`: 强迫场数据的循环周期 (秒)。
- `pollutant_fluxIsCellTotal`: 定义排放通量的单位。`.TRUE.` 表示 `mol/s` (每个网格的总量)，`.FALSE.` 表示 `mol/m^2/s` (通量密度)。
- `usePollutantDegradation`: 是否启用降解过程的总开关。
- `pollutant_Tc`: 临界温度 (`degC`)。只有当水温高于此值时，降解才会发生。
- `pollutant_k_dark_20_d`: 20°C下的暗化学降解速率 (单位: `d^-1`)。
- `pollutant_Q10_dark`: 暗化学降解的Q10温度系数。
- `pollutant_k_bio_20_d`: 20°C下的生物降解速率 (单位: `d^-1`)。
- `pollutant_Q10_bio`: 生物降解的Q10温度系数。
- `pollutant_k_OH_d`: 间接光解速率 (单位: `d^-1`)。
- `pollutant_k_photo_d`: 海表直接光解速率 (单位: `d^-1`)。
- `pollutant_light_atten`: 水的光衰减系数 (单位: `m^-1`)。

#### `data.exf`

为了驱动光解作用，您必须在 `data.exf` 中提供向下的短波辐射数据。

```
 &EXF_NML_02
  swdownstartdate1 = 19790101,
  swdownperiod     = 2629800,
  swdownfile       = 'NCEP/dswInterp.bin',
 & 
```
- `swdownfile`: 向下短波辐射数据的二进制文件路径。
- `swdownstartdate1`, `swdownperiod`: 数据的时间信息。

### 3.3. 输入数据文件

您需要准备以下二进制格式的输入文件：

- **初始浓度文件**: (例如 `pollutant_initial.bin`) 一个三维数组，定义了污染物在模拟开始时的浓度分布 (单位: `mol/m^3`)。
- **排放源文件**: (例如 `pollutant_emission.bin`) 一个二维或三维（如果随时间变化）数组，定义了污染物在海表的排放通量。
- **向下短波辐射文件**: (例如 `NCEP/dswInterp.bin`) 由 `exf` 模块使用的二维或三维辐射数据。

### 3.4. 诊断输出

您可以在 `data.diagnostics` 文件中请求输出 `pollutant` 模块计算的诊断变量，以供后续分析。

```
 &DIAGNOSTICS_LIST
  fields(1:5,1) = 'POLLUT_S','POLLUT_K','POLLUT_T',
 &                'POLLUT_M','POLLUT_F',
  fileName(1)    = 'output/pollutant_fluxes',
  frequency(1)   = 86400.,

  fields(1:4,2) = 'POLSURF','POLGMASS','POLGSRC',
 &               'POLGSNK',
  fileName(2)   = 'output/pollutant_surface',
  frequency(2)  = 86400.,

  fields(1:3,3) = 'POLCSRC','POLCSNK','TRAC01',
  fileName(3)   = 'output/pollutant_state',
  frequency(3)  = 86400.,
 /
```

**诊断变量说明 (按功能分组):**
- **局地趋势:**
  - `POLLUT_S`：局部源项 (`mol/m^3/s`)，与 `POLLUT_K`、`POLLUT_T` 共同描述源汇平衡，不与全局诊断重复。
  - `POLLUT_K`：局部总汇项 (`mol/m^3/s`)。
  - `POLLUT_T`：局部净趋势 (= 源 − 汇, `mol/m^3/s`)。
- **质量守恒:**
  - `POLLUT_M`：单元质量 (`mol`)；体积加和可得总质量。
  - `POLGMASS`：全局总质量 (`mol`)，在每个网格点填入同一标量值，方便通过标准后处理读取全局守恒量；与 `POLLUT_M` 功能互补而非重复。
  - `POLGSRC` / `POLGSNK`：全局总源/总汇 (`mol/s`)，帮助检查模型整体平衡。
  - `POLCSRC` / `POLCSNK`：自积分以来的累计源/汇 (`mol`)，用于验证全局质量预算的一致性。
- **表层状态:**
  - `POLLUT_F`：表层排放通量 (`mol/m^2/s`)。
  - `POLSURF`：表层 (k=1) 浓度 (`mol/m^3`)，提供与排放通量直接对比的状态变量。
- **示踪剂字段:**
  - `TRAC01`：污染物浓度场 (`mol/m^3`)。

> 提示：`POLGMASS`、`POLGSRC`、`POLGSNK`、`POLCSRC`、`POLCSNK` 以二维标量场的形式输出，这是 MITgcm 诊断基础设施的通用处理方式。它们与局地趋势诊断 (`POLLUT_S`、`POLLUT_K`、`POLLUT_T`) 或局地质量 (`POLLUT_M`) 不重复，而是提供全局守恒信息。通过比较 `POLGMASS` 与 `POLCSRC - POLCSNK` 的时间序列，可以快速检查数值守恒性。
