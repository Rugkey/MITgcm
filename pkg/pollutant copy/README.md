# MITgcm pkg/pollutant 使用手册（面向初学者与科研）

本手册介绍如何编译与使用 MITgcm 的污染物包 pkg/pollutant，并给出数据准备与常见问题说明。内容基于当前代码的真实实现（包括单位修正、体积守恒、沉降守恒等最近更新）。

====================================
一、功能概述
====================================

pkg/pollutant 在 GCHEM + PTRACERS 框架下，提供“新污染物”示踪模拟能力，适用于 BPA、增塑剂、PCBs、PAHs 等多类污染物的平移、扩散与源汇研究。当前实现支持：
- 源项：读取外部排放场，支持单记录或周期性多记录；支持“每格总量 mol/s”或“面通量 mol/m^2/s”。
- 汇项（显式一阶，可逐项开关）：
  - 降解（Decay）、生物摄取（Bio-uptake）。
  - 沉降（Settling）：已改为“垂向通量散度”形式，严格质量守恒（顶界面无通量、底界面为域外汇）。
- 传输：平流与扩散由 PTRACERS/GM-Redi/KPP 等包负责。
- 守恒：
  - 源项体积归一：面通量按“层厚×湿面系数”转为体积分率；
  - 沉降守恒：以界面通量表示，层内趋势为 -dF/dz。
- 诊断：EDC_SRC/EDC_SINK/EDC_DECAY/EDC_SETTLE/EDC_BIOUP/EDC_TOTAL；EDC_FLUX（面源通量）、EDC_CONC（浓度）、EDC_MASS（质量）。

提示：后续可扩展“多相分配、温度依赖、海气交换、沉积物盒模型”等科研功能，但需额外输入数据，见“九、科研拓展建议”。

====================================
二、目录与关键源码
====================================

- POLLUTANT_OPTIONS.h：编译期开关（DECAY/SETTLING/BIOUPTAKE/ADVECTION/DIFFUSION/DIAGNOSTICS）。
- POLLUTANT.h：参数与字段（开关、速率、强迫周期、文件名、flux/concentration/mass 等）；新增标志 pollutant_fluxIsCellTotal。
- POLLUTANT_LOAD.h：强迫读取的临时数组与时间记录号。
- pollutant_readparms.F：读取 data.pollutant；含参数校验与日志打印。新增 namelist /POLLUTANT_FLAGS/，支持 pollutant_fluxIsCellTotal。
- pollutant_fields_load.F：按 forcingPeriod/Cycle 线性插值读取排放；若 pollutant_fluxIsCellTotal=.TRUE.，将“每格总量 mol/s”除以“湿面积= rA×hFacC_top”转为面通量 mol/m^2/s。
- pollutant_calc_tendency.F：计算源汇趋势；
  - 源项：仅顶层，体积归一：flux/(drF(1)×hFacC_top)；
  - 沉降：通量散度 -(F(k+1/2)−F(k−1/2))/(drF×hFacC)；顶界面通量为 0，底界面通量为域外汇；
  - 负值保护：限制趋势不使浓度为负。
- pollutant_diagnostics_init.F / pollutant_diags.F：诊断注册与（如启用）时间平均累积。
- pollutant_init_fixed.F：固定字段与时间平均数组初始化。
- pollutant_param.F：默认速率给定（可被 data.pollutant 覆盖）。

====================================
三、编译前准备
====================================

- packages.conf 至少包含：
  - gchem, ptracers, diagnostics, exf（如用外部强迫）, gmredi（如用等温混合）, kpp（如用混合层参数化）, pollutant。
- 建议 Fortran 编译使用固定格式规范（MITgcm 默认），避免行续行问题。

示例 packages.conf：
  gchem
  ptracers
  diagnostics
  exf
  gmredi
  kpp
  poll
  (其余按实验需要)

====================================
四、编译与运行
====================================

以某 verification 实验为例：

1) 生成 Makefile
  ./genmake2 -mods=../code

2) 依赖
  make depend

3) 编译
  make

4) 运行
  ./mitgcmuv            # 单进程
  mpirun -np 4 ./mitgcmuv  # 多进程

====================================
五、输入文件与最小配置
====================================

1) data.pkg（启用包）
&PACKAGES
 useGMRedi=.TRUE.,
 useDIAGNOSTICS=.TRUE.,
 useEXF=.TRUE.,
 useKPP=.TRUE.,
 useCAL=.TRUE.,
 usePTRACERS=.TRUE.,
 useGCHEM=.TRUE.,
/

2) data.gchem（打开 GCHEM 下的 pollutant）
&GCHEM_PARM01
 usePOLLUTANT = .TRUE.,
/

3) data.ptracers（示踪传输数值设置：建议正定方案+小扩散）
&PTRACERS_PARM01
 PTRACERS_numInUse=1,
 PTRACERS_Iter0=0,
 PTRACERS_names(1)='Pollutant',
 PTRACERS_long_names(1)='Ocean Pollutant [mol/m^3]',
 PTRACERS_units(1)='mol/m^3',
 PTRACERS_advScheme(1)=77,
 PTRACERS_diffKh(1)=1.E3,
 PTRACERS_diffKr(1)=3.E-5,
 PTRACERS_useGMRedi(1)=.TRUE.,
 PTRACERS_initialFile(1)=' ',
/

4) data.pollutant（强迫与源汇参数）
&POLLUTANT_FORCING
 pollutant_emission_file = 'pollutant_emission.bin',
 pollutant_forcingPeriod = 86400.,
 pollutant_forcingCycle  = 86400.,
/
&POLLUTANT_FLAGS
 pollutant_fluxIsCellTotal = .TRUE.,  # 若输入为每格总量 mol/s
/
&POLLUTANT_PARAMS_L
 usePollutantDecay     = .TRUE.,
 usePollutantSettling  = .TRUE.,
 usePollutantBioUptake = .TRUE.,
 usePollutantAdvection = .TRUE.,
 usePollutantDiffusion = .TRUE.,
/
&POLLUTANT_PARAMS_R
 pollutant_decay_rate      = 1.0e-7,
 pollutant_settle_rate     = 5.0e-8,
 pollutant_biouptake_rate  = 2.0e-8,
 pollutant_monFreq         = 86400.,
/

注：- 若 pollutant_fluxIsCellTotal=.TRUE.，代码会在读入后用湿面积 rA×hFacC_top 自动转为 mol/m^2/s。
    - 源项在趋势阶段再除以 drF(1)×hFacC_top，严格体积守恒。

====================================
六、排放数据准备与单位
====================================

- 排放文件 pollutant_emission.bin：
  - 二进制，big-endian，Real*4（float32），网格顺序南→北（与 MITgcm 标准一致）。
  - 若为“面通量 mol/m^2/s”，可设 pollutant_fluxIsCellTotal=.FALSE.
  - 若为“每格总量 mol/s”，需设 pollutant_fluxIsCellTotal=.TRUE.（代码将自动除以湿面积）。
- 推荐在读入后打印“全局总排放（mol/s）”进行 sanity check（可在后续版本加入此打印）。

辅助脚本：verification/…/input/create_pollutant_emission.py（示例）
- 注意：默认示例将河口总量累加到格点，单位为 mol/s；需要在模型端设 pollutant_fluxIsCellTotal=.TRUE.

====================================
七、诊断输出（data.diagnostics）
====================================

- 主要场：
  - 'EDC_FLUX '：面源通量 [mol/m^2/s]
  - 'EDC_SRC  '：体积源项趋势 [mol/m^3/s]
  - 'EDC_SINK '：总汇项趋势（显式）[mol/m^3/s]
  - 'EDC_DECAY'、'EDC_SETTLE'、'EDC_BIOUP'、'EDC_TOTAL'
  - 'PTRAC01  ' 或 'EDC_CONC'：浓度 [mol/m^3]
  - 'EDC_MASS '：格点质量 [mol]

- 样例（快照输出）：
&DIAGNOSTICS_LIST
 fields(1:4,1) = 'EDC_FLUX','EDC_SRC ','EDC_SINK','EDC_TOTAL',
  fileName(1)='output/pollutant_tendency',
  frequency(1)=-2592000.,
/

- 时间平均：设置 frequency 为正、并在 PTRACERS_taveFreq>0 的情况下累积。

====================================
八、常见问题与排查
====================================

1) 数值爆涨/负值：
  - 常因排放单位错误（mol/s 当成 mol/m^2/s 用）。已提供 pollutant_fluxIsCellTotal 读入端修正；并在趋势阶段严格体积归一。
  - 选用正定/受限通量的对流方案（如 77），并给少量水平扩散（1.E3）。

2) 编译错误（固定格式 Fortran）：
  - 变量声明必须在可执行语句之前；避免在 DO 循环内重复声明。
  - 跨行续行使用“     &”风格；长表达式拆分为临时变量（如 denom）。

3) 沉降守恒：
  - 采用界面通量法，顶界面通量=0、底界面通量为域外汇，层内趋势为 -div(Fz)/(drF×hFacC)。

4) 预算闭合：
  - 建议输出/集成全局质量、总源、总汇（含底部沉降通量），检查闭合误差。后续版本可加入自动打印。

====================================
九、科研拓展建议（需要额外数据）
====================================

若要开展“多相分配 + 温度依赖 + 海气交换”等科研模拟，建议逐步加入：
- 物性参数表（每种污染物）：Koc(T)、Henry 常数 H(T,S)、参考降解速率与活化能、Kdoc、分子量等。
- 环境场：DOC/POC 或 fOC、表层 10m 风速 U10、短波辐射/光场、大气浓度 Ca。
- 进阶：黑碳分配、沉积物盒模型、再悬浮与生物扰动参数化、敏感性与不确定性分析。

这些功能尚未在当前仓库实现，但 pkg/pollutant 的结构（在 GCHEM 钩子中）已为扩展留下接口。

====================================
十、最佳实践清单
====================================

- 单位明确：
  - 输入为 mol/s（每格总量）→ pollutant_fluxIsCellTotal=.TRUE.
  - 输入为 mol/m^2/s（面通量）→ pollutant_fluxIsCellTotal=.FALSE.
- 数值稳健：
  - 对流方案用正定/受限通量；CFL 合理；少量水平扩散。
  - 强汇参数（1/s）不要过大；必要时缩小 dt 或引入隐式处理（后续可加）。
- 守恒检查：
  - 对比 EDC_SRC 积分与输入通量、EDC_MASS 的变化、底部沉降通量积分。

====================================
版本信息
====================================

- MITgcm：checkpoint68n
- pkg/pollutant：当前版本（含单位修正、体积归一、沉降守恒等）
- 文档更新：2025-10

如需进一步的科研功能实现或示例用例（单列/理想化/再现论文结果），请在 Issues 中提出需求。
