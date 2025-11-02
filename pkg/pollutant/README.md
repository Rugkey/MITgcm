# MITgcm pkg/pollutant 使用说明（同步当前实现）

本说明覆盖 pkg/pollutant 的真实代码结构、编译与运行配置、诊断输出以及常见问题排查，已与当前仓库中的源码实现保持一致（calc 纯物理、diags 在采样窗口内统一计算+填充、diagnostics 包统一写出）。

----------------------------------------
## 1. 模块定位与调用关系

- 依赖框架：ptracers + gchem + diagnostics
  - ptracers：负责污染物的平流/扩散和追踪器容器。
  - gchem：提供“生地化学过程”统一挂载点（注册与计算时序）。
  - diagnostics：提供通用诊断开关、采样与输出。

- 当前实现的核心时序（重要）：
  1) pollutant_calc_tendency.F：只做物理计算（源/汇/沉降），不做诊断填充。
  2) pollutant_diags.F：在“采样窗口”打开期间（由 DO_STATEVARS_DIAGS 调用）统一计算诊断数组，并调用 DIAGNOSTICS_FILL 批量填充（不在此写出）。
  3) diagnostics 包在其既定时序写出（DIAGNOSTICS_WRITE）。

- 为什么这样设计：
  - diagnostics 填充必须发生在 DIAGNOSTICS_SWITCH_ONOFF 之后、DIAGNOSTICS_WRITE 之前，否则会出现：
    - has not been filled (ndiag=0)
    - 或 expectStatus/pkStatus 错误（wrong place）。
  - 将填充分离到 pollutant_diags.F，并从 DO_STATEVARS_DIAGS 调用，保证总在采样窗口内，稳定无错。

----------------------------------------
## 2. 编译与启用

- packages.conf（实验 code/ 下）：
  - 必须包含：
    - ptracers
    - gchem
    - pollutant

- GCHEM 选项（实验 code/GCHEM_OPTIONS.h）：
  - 定义：
    - #define GCHEM_ADD2TR_TENDENCY
  - 作用：使 gchem_calc_tendency 路径生效，污染物源汇趋势进入 gchem 统一趋势缓冲并加回 ptracers（由 gchem_add_tendency 完成）。

- 全量编译：
  - make clean; make depend; make

----------------------------------------
## 3. 运行时配置

### 3.1 data.ptracers（追踪器槽位与初值）

示例：
```
&PTRACERS_PARM01
 PTRACERS_numInUse       = 1,
 PTRACERS_names(1)       = 'Pollutant',
 PTRACERS_advScheme(1)   = 77,
 PTRACERS_initialFile(1) = 'pollutant_initial.bin',
 PTRACERS_enforcePositive(1) = .TRUE.,
/
```
注意：
- pollutant 注册的槽位起始号为 POLLUTANT_pTr_i1（运行时 STDOUT 会打印起始槽位与数量）。
- 建议将 pollutant 放在首个槽位，避免与其它手动 TRAC01 冲突；或确保 numInUse 与顺序一致。

### 3.2 data.pollutant（物理过程与强迫）

示例：
```
&POLLUTANT_PARAMS
  pollutant_emission_file   = 'pollutant_emission.bin',
  pollutant_forcingPeriod   = 900.,
  pollutant_forcingCycle    = 900.,
  pollutant_fluxIsCellTotal = .TRUE.,

  usePollutantDecay     = .TRUE.,
  usePollutantSettling  = .FALSE.,
  usePollutantBioUptake = .FALSE.,

  pollutant_decay_halflife_d     = 30.0,
  pollutant_settle_halflife_d    = 30.0,
  pollutant_biouptake_halflife_d = 30.0,

  useTempDependentDecay  = .TRUE.,
  decayTempRef           = 20.0,
  decayQ10               = 2.0,
  useDepthDependentDecay = .TRUE.,
  decayDepthScale        = 50.0,
/
```
要点：
- pollutant_fluxIsCellTotal 含义：
  - =.TRUE.：emission 文件为“每格总通量 mol/s”；代码会除以湿面积转为面通量（mol/m2/s），再体积归一为源项（mol/m3/s）。
  - =.FALSE.：emission 为面通量（mol/m2/s），不再除面积。
- 半衰期[d] 自动转速率[1/s]，温/深依赖可选。
- 首步 STDOUT 打印总排放速率以核对数量级：
  - `POLLUTANT: Initial Global Emission Rate = ... mol/s`

### 3.3 data.diagnostics（诊断流）

示例：
```
&DIAGNOSTICS_LIST
  fields(1:6,3) = 'POLLUT_S','POLLUT_K','POLLUT_D','POLLUT_L','POLLUT_B','POLLUT_T',
  fileName(3)   = 'output/pollutant_tendency',
  frequency(3)  = -86400.,
  timePhase(3)  = 0,

  fields(1:2,4) = 'TRAC01  ','POLLUT_M',
  fileName(4)   = 'output/pollutant_state',
  frequency(4)  = -86400.,
  timePhase(4)  = 0,
/
```
- 负频率：时间平均（例如 -86400.= 日平均）。
- 正频率：快照（例如 +900.= 每 900 s 快照）。
- 若需快速验证链路，建议将 frequency 暂改为 +900. 看是否立刻出现非零值；确认后再改回 -86400.。

----------------------------------------
## 4. 诊断变量与单位

在 pollutant_diagnostics_init.F 中注册的诊断：
- POLLUT_S：源项（mol/m3/s）
- POLLUT_K：总汇项（mol/m3/s）= Decay+Settling+BioUptake
- POLLUT_D：降解（mol/m3/s）
- POLLUT_L：相转化/沉降（mol/m3/s）
- POLLUT_B：生物摄取（mol/m3/s）
- POLLUT_T：净趋势（mol/m3/s）= 源 - 总汇
- POLLUT_M：单元质量（mol）= C × 体积
- POLLUT_F：表面通量（mol/m2/s，2D）

维度：除 POLLUT_F 为 2D 外，其余均为 3D（Nr 层）。

----------------------------------------
## 5. 常见问题与排查

1) has not been filled (ndiag=0)
- 原因：诊断填充不在采样窗口内。当前实现将填充放在 DO_STATEVARS_DIAGS 调用的 pollutant_diags.F 中（采样窗口内），并由 diagnostics 统一写出，可避免该问题。
- 若仍遇到：
  - 确认 do_statevars_diags.F 已调用 POLLUTANT_DIAGS（seqFlag=0 处）。
  - 确认未在 gchem_output（IO 阶段）调用 POLLUTANT_DIAGS。
  - 可将 frequency 暂改为 +900. 快照验证。

2) DIAGNOSTICS_FILL wrong place / segfault
- 原因：在 IO 阶段（或在 DIAGNOSTICS_SWITCH_ONOFF 之前）调用 DIAGNOSTICS_FILL。
- 解决：确保只在 DO_STATEVARS_DIAGS 阶段调用 POLLUTANT_DIAGS；pollutant_calc_tendency.F 不做填充。

3) 数值一直很小/接近 0
- 检查：
  - pollutant_fluxIsCellTotal 与 emission 单位是否匹配。
  - 表层 k=1 是否湿格（hFacC>0）、排放区域是否落在海洋网格。
  - 用正频率快照（+900.）快速验证是否出现非零。

4) 追踪器槽位不匹配
- 查看 STDOUT 中 POLLUTANT_TR_REGISTER 打印的起始槽位与数量，确保 data.ptracers 的配置一致且未与其它 TRACxx 冲突。

----------------------------------------
## 6. 运行流程小结（当前实现）

- 编译：ptracers+gchem+pollutant，并在 GCHEM_OPTIONS.h 定义 GCHEM_ADD2TR_TENDENCY。
- 计算阶段：
  - gchem_calc_tendency → POLLUTANT_CALC_TENDENCY：只算物理源汇趋势。
- 采样阶段：
  - do_statevars_diags.F（seqFlag=0）→ POLLUTANT_DIAGS：构建诊断数组并 DIAGNOSTICS_FILL，保证采样窗口内计数生效。
- 写出阶段：
  - diagnostics 包统一 DIAGNOSTICS_WRITE。

----------------------------------------
## 7. 附：最小工作示例（MWE）

- packages.conf：
```
ptracers
gchem
pollutant
```
- code/GCHEM_OPTIONS.h：
```
#define GCHEM_ADD2TR_TENDENCY
```
- data.ptracers / data.pollutant / data.diagnostics 如前文示例。
- 全量编译并运行：
```
make clean; make depend; make
```
- 验证：
  - STDOUT 有 “POLLUTANT: Initial Global Emission Rate=… mol/s”。
  - 输出含非零 POLLUT_S（表层）、POLLUT_M（随时间增加）。

----------------------------------------
文档更新于：2025-11
