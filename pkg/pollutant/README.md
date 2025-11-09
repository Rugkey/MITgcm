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

# --- 气-海交换与沉降 ---
  usePollutantAirSeaExchange = .FALSE.,
  pollutant_henryConst       = 0.0,
  pollutant_schmidtRef       = 660.0,
  pollutant_schmidtExp       = 0.5,
  pollutant_schmidtA0        = 660.0,
  pollutant_schmidtA1        = 0.0,
  pollutant_schmidtA2        = 0.0,
  pollutant_schmidtA3        = 0.0,
  pollutant_pistonCoeff      = 0.31,
  pollutant_minWind          = 0.5,
  pollutant_defaultWind      = 5.0,
  pollutant_atmConcConst     = 0.0,
  pollutant_atmConc_file     = ' ',
  pollutant_precipConst      = 0.0,
  pollutant_useDryDeposition = .FALSE.,
  pollutant_dryDepVelConst   = 0.0,
  pollutant_dryDepVel_file   = ' ',
  pollutant_useWetDeposition = .FALSE.,
  pollutant_wetDepConcConst  = 0.0,
  pollutant_wetDepConc_file  = ' ',
 & 
```

**参数说明:**

##### 3.2.1 污染物参数速查

| 参数 | 默认值 | 含义 | 使用建议 |
| --- | --- | --- | --- |
| `pollutant_emission_file` | `'pollutant_emission.bin'` | 表层排放场 (mol/s 或 mol/m²/s) | 必填；支持时间序列。 |
| `pollutant_forcingPeriod` / `pollutant_forcingCycle` | `externForcingPeriod/externForcingCycle` | 排放与气-海交换场的插值周期/循环 | 若强迫为逐日/逐年数据需显式设置。 |
| `pollutant_fluxIsCellTotal` | `.FALSE.` | 说明排放单位是网格总量还是面通量 | River 口总排污常用 `.TRUE.`。 |
| `usePollutantDegradation` | `.FALSE.` | 总开关 | 关闭时后续降解参数被忽略。 |
| `pollutant_Tc` | `-100.` | 启动降解的临界温度 (°C) | 设为常温以下以全域激活；设为 0~5°C 表示寒冷水体抑制降解。 |
| `pollutant_k_dark_20_d` / `pollutant_k_bio_20_d` | `0.` | 20°C 下的暗化学 / 生物降解速率 (d⁻¹) | 可依据实验半衰期 `k = ln(2)/t₁/₂` 估算。 |
| `pollutant_Q10_dark` / `pollutant_Q10_bio` | `2.` | 温度每升高 10°C 的增益因子 | 有机物降解常取 2~3。 |
| `pollutant_k_OH_d` | `0.` | 间接光解 (d⁻¹) | 若缺省，可维持 0。 |
| `pollutant_k_photo_d` | `0.` | 海表直射光解 (d⁻¹) | 配合 `pollutant_light_atten` 做指数衰减。 |
| `pollutant_light_atten` | `0.` | 光衰减系数 (m⁻¹) | 清澈海水 0.04~0.08；近岸浑浊水体更大。 |

##### 3.2.2 气-海交换与沉降参数

| 参数 | 默认值 | 含义 | 典型范围 |
| --- | --- | --- | --- |
| `usePollutantAirSeaExchange` | `.FALSE.` | 打开风速控制的气-海交换与沉降 | 开启后，以下参数生效。 |
| `pollutant_henryConst` | `0.` | 亨利常数 (mol/m³ 水 / mol/m³ 空气) | BPA 量级 1~10；数值越大越易溶于水。 |
| `pollutant_schmidtRef` | `660.` | 参考施密特数 | 保持 660 以兼容 Wanninkhof 经验式。 |
| `pollutant_schmidtExp` | `0.5` | 施密特缩放指数 | Wanninkhof(1992) 建议 0.5。 |
| `pollutant_schmidtA0~A3` | `660.,0,0,0` | 施密特数随温度 (°C) 的多项式系数 | 若无资料仅设 A0。 |
| `pollutant_pistonCoeff` | `0.31` | 活塞速度系数 (kw = coeff * u10² / 3.6e5) | 0.27~0.39 范围常见。 |
| `pollutant_minWind` | `0.5` m/s | 风速下限 | 防止 kw 因风速为零而消失。 |
| `pollutant_defaultWind` | `5.0` m/s | 未启用 EXF 时的备用风速 | 使用 EXF 时不会被访问。 |
| `pollutant_atmConcConst` / `pollutant_atmConc_file` | `0.` / `' '` | 大气浓度 (mol/m³) 常数或文件 | 若提供文件则随时间插值。 |
| `pollutant_useDryDeposition` | `.FALSE.` | 干沉降开关 | |
| `pollutant_dryDepVelConst` / `pollutant_dryDepVel_file` | `0.` / `' '` | 干沉降速度 (m/s) | 典型值 10⁻⁴~10⁻²。 |
| `pollutant_useWetDeposition` | `.FALSE.` | 湿沉降开关 | |
| `pollutant_wetDepConcConst` / `pollutant_wetDepConc_file` | `0.` / `' '` | 雨水浓度 (mol/m³) | 可按降水化验值设定。 |
| `pollutant_precipConst` | `0.` | 当未提供 EXF `precip` 时的降水速率 (m/s) | 3×10⁻⁸ ≈ 2.6 mm/day。 |

较常用的常数初值示例（适用于尚无观测的测试实验）：

```
pollutant_atmConcConst   = 1.0e-8   ! mol/m^3，对应数 ng/m^3 的大气浓度
pollutant_dryDepVelConst = 1.0e-3   ! m/s，约 0.1 cm/s 的干沉降速度
pollutant_wetDepConcConst= 1.0e-8   ! mol/m^3，雨水中污染物浓度
pollutant_precipConst    = 3.0e-8   ! m/s，约 2.6 mm/day 的降水
```

若提供 `pollutant_atmConc_file`、`pollutant_dryDepVel_file` 或 `pollutant_wetDepConc_file`，其时间插值与 `pollutant_emission_file` 共用 `pollutant_forcingPeriod`/`pollutant_forcingCycle` 设置。文件应采用 MITgcm 标准的二进制 XY 场 (可选时间序列)；留空字符串时将退回到对应的常数参数。

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
  fields(1:9,1) = 'POLLUT_S','POLLUT_K','POLLUT_T',
 &                'POLLUT_M','POLLUT_F','POLFNET ',
 &                'POLFVOL ','POLFDRY ','POLFWET ',
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
  - `POLGSRC` / `POLGSNK`：全局当前时刻总源/总汇 (`mol/s`)，帮助检查模型整体平衡。
  - `POLCSRC` / `POLCSNK`：自积分以来的累计源/汇 (`mol`)，用于验证全局质量预算的一致性。
- **表层状态:**
  - `POLLUT_F`：表层排放通量 (`mol/m^2/s`)。
  - `POLFNET`：表层净通量（排放 + 挥发 + 干/湿沉降）。
  - `POLFVOL`：挥发（气化）通量，正值表示入海。
  - `POLFDRY`：干沉降通量。
  - `POLFWET`：湿沉降通量。
  - `POLSURF`：表层 (k=1) 浓度 (`mol/m^3`)，提供与排放通量直接对比的状态变量。
- **示踪剂字段:**
  - `TRAC01`：污染物浓度场 (`mol/m^3`)。

> 提示：`POLGMASS`、`POLGSRC`、`POLGSNK`、`POLCSRC`、`POLCSNK` 以二维标量场的形式输出，这是 MITgcm 诊断基础设施的通用处理方式。它们与局地趋势诊断 (`POLLUT_S`、`POLLUT_K`、`POLLUT_T`) 或局地质量 (`POLLUT_M`) 不重复，而是提供全局守恒信息。通过比较 `POLGMASS` 与 `POLCSRC - POLCSNK` 的时间序列，可以快速检查数值守恒性。

> 气-海交换提示：挥发项使用 `F_vol = k_w (C_eq - C_w)`，其中 `k_w` 源于风速驱动的活塞速度并按施密特数缩放，`C_eq = pollutant_henryConst * C_air`。干沉降 (`F_dry = v_d * C_air`) 与湿沉降 (`F_wet = P * C_rain`) 默认为向海洋的正通量，可借助 `POLFDRY`、`POLFWET` 独立审查其量级。

### 3.5. 气-海交换与沉降功能实现原理

- **数据读取 (`pollutant_fields_load.F`)**：
  - 新增大气浓度、干沉降速度、湿沉降雨水浓度的两种通道：若指定文件名，则按 `pollutant_forcingPeriod/Cycle` 与排放场一同线性插值；否则回退到常数参数。
  - 如果启用 EXF，自动复用 `wspeed`、`precip`、`swdown` 等场；未启用时则使用 `pollutant_defaultWind`、`pollutant_precipConst`。
  - 计算活塞速度 `kw = coeff * u10^2 / 3.6e5`（乘以开水面分数并施密特数缩放），并缓存到 `pollutant_pistonVel`。

- **趋势计算 (`pollutant_calc_tendency.F`)**：
  - 在 `k=1` 表层层，将排放、挥发、干沉降、湿沉降通量求和，转换为体积源项写入 `gPollutant`。
  - 亨利常数、施密特多项式和 `pollutant_schmidtExp` 控制温度依赖的挥发强度；干/湿沉降分别使用沉降速度与降水乘以大气/雨水浓度。
  - 新的诊断数组 `pollutant_flux_[vol|dry|wet|net]` 记录各分量，便于守恒检查。

- **诊断输出 (`pollutant_diags.F`)**：
  - 在原有的 `POLLUT_F` 基础上，新增 `POLFNET`、`POLFVOL`、`POLFDRY`、`POLFWET` 四个二维诊断。
  - `POLFNET` 与 `POLLUT_T`、`POLGSRC`/`POLGSNK` 联合分析，可验证挥发与沉降对总体预算的贡献。

### 3.6. 使用步骤建议

1. **选择模式**：在 `data.pollutant` 中将 `usePollutantAirSeaExchange` 设为 `.TRUE.`，按需求启用 `pollutant_useDryDeposition`、`pollutant_useWetDeposition`。
2. **提供输入**：
   - 若有时空变化的大气/沉降数据，准备与排放场一致尺寸的二进制文件，并填写对应的 `*_file` 名称；
   - 否则将文件名留空，并在 `pollutant_atmConcConst`、`pollutant_dryDepVelConst`、`pollutant_wetDepConcConst`、`pollutant_precipConst` 中填写常数。
3. **风速与降水来源**：确保 `useEXF = .TRUE.` 并在 `data.exf` 中提供 `wspeed` 和 `precip`；如果暂不使用 EXF，可依赖 `pollutant_defaultWind` 与 `pollutant_precipConst` 常数驱动。
4. **诊断配置**：在 `data.diagnostics` 中加入 `POLFNET`、`POLFVOL`、`POLFDRY`、`POLFWET`，便于分别检查各通量分量。
5. **结果分析**：
   - 使用 `POLFNET` 与 `POLLUT_M`、`POLGMASS` 比对确认整体守恒；
   - `POLFVOL`、`POLFDRY`、`POLFWET` 可用于制作空间分布图，诊断挥发与沉降热区；
   - 若结合生态模型（例如 MaxEnt），可将 `POLSURF`、`POLFNET`/`POLFDRY` 转换为栖息地风险指标。

完成上述配置后，重新编译并执行实验，便可在任意污染物示踪剂上启用气-海交换与干湿沉降模拟。
