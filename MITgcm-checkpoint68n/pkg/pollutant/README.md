# MITgcm POLLUTANT 包使用说明

## 概述

本模块实现了独立的 POLLUTANT 包，在 MITgcm 的 GCHEM + PTRACERS 框架中增加了污染物（EDC - Endocrine Disrupting Chemical）示踪物功能，支持全球河流排放的网格化输入和多种汇过程。

## 主要功能

### 1. 物理过程
- **平流与扩散**：由 PTRACERS 模块负责
- **源项**：读取外部网格化排放场文件（全球河流排放），单位 mol m⁻² s⁻¹
- **汇项**：包含三种可选机制
  - 一阶降解（光降解/生物降解）：`-k_deg * C`
  - 吸附沉降：`-k_settle * C`
  - 生物富集与摄取：`-k_bio * C`
  - 总汇项：`-(k_deg + k_settle + k_bio) * C`
- **负值保护**：多层保护机制确保tracer浓度不会变为负值
- **时间平均**：支持时间平均诊断输出，可输出源项、汇项、降解、沉降、生物摄取的时间平均值

### 2. POLLUTANT 包架构

#### CPP 选项（POLLUTANT_OPTIONS.h）
POLLUTANT包支持以下编译时选项：
- `POLLUTANT_DECAY`：启用降解过程
- `POLLUTANT_SETTLING`：启用沉降过程
- `POLLUTANT_BIOUPTAKE`：启用生物摄取过程
- `POLLUTANT_ADVECTION`：启用平流过程
- `POLLUTANT_DIFFUSION`：启用扩散过程
- `POLLUTANT_DIAGNOSTICS`：启用诊断输出

POLLUTANT 包是独立的 MITgcm 包，包含以下文件：
- `POLLUTANT.h` - 参数声明和公共块定义
- `POLLUTANT_SIZE.h` - 包大小定义
  - `POLLUTANT_num = 1`：最大示踪剂数量
  - `POLLUTANT_Tr_num = 1`：当前示踪剂数量
  - `POLLUTANT_numDiag = 6`：最大诊断数量
  - `POLLUTANT_pTr_i1`：第一个示踪剂的索引
- `POLLUTANT_OPTIONS.h` - CPP 选项（定义各种过程开关）
- `POLLUTANT_LOAD.h` - 时间插值数组定义
  - `pollutant_ldRec(nSx,nSy)`：当前加载的时间记录
  - `pollutantFlux0(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)`：时间插值数组0
  - `pollutantFlux1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)`：时间插值数组1
- `pollutant_readparms.F` - 参数读取和验证
- `pollutant_tr_register.F` - 示踪剂注册
  - 注册POLLUTANT_Tr_num个示踪剂到PTRACERS系统
  - 设置POLLUTANT_pTr_i1为第一个示踪剂的索引
  - 输出注册信息到标准输出
- `pollutant_fields_load.F` - 外部场加载和时间插值
- `pollutant_calc_tendency.F` - 源汇项计算
- `pollutant_check.F` - 参数检查（新增）
  - 输出POLLUTANT包配置信息
  - 显示所有逻辑开关状态
  - 显示所有速率参数值
  - 提供包状态确认
- `pollutant_diagnostics_init.F` - 诊断初始化
- `pollutant_init_fixed.F` - 固定变量初始化
  - 初始化pollutant_flux、pollutantFlux0、pollutantFlux1为0
  - 初始化pollutant_ldRec为0
  - 初始化时间平均数组（如果启用ALLOW_TIMEAVE）
  - 调用TIMEAVE_RESET重置所有时间平均变量
- `pollutant_param.F` - 默认参数设置
- `pollutant_diags.F` - 时间平均诊断输出处理
  - 检查PTRACERS_taveFreq是否到达输出时间
  - 调用TIMEAVE_NORMALIZE标准化时间平均数据
  - 输出时间平均文件：POLLUTANT_Srcave、POLLUTANT_Sinkave等
  - 调用TIMEAVE_RESET重置时间平均数组

### 3. 可控参数
所有参数在 `data.pollutant` 中配置：

#### 逻辑开关（POLLUTANT_PARAMS_L）
- `usePollutantDecay`：启用/禁用降解过程
- `usePollutantSettling`：启用/禁用沉降过程  
- `usePollutantBioUptake`：启用/禁用生物摄取过程
- `usePollutantAdvection`：启用/禁用平流（由PTRACERS处理）
- `usePollutantDiffusion`：启用/禁用扩散（由PTRACERS处理）

#### 速率参数（POLLUTANT_PARAMS_R）
- `pollutant_decay_rate`：降解速率 (s⁻¹)，默认值：1.0e-7（在pollutant_param.F中设置）
- `pollutant_settle_rate`：沉降速率 (s⁻¹)，默认值：5.0e-8（在pollutant_param.F中设置）
- `pollutant_biouptake_rate`：生物摄取速率 (s⁻¹)，默认值：2.0e-8（在pollutant_param.F中设置）
- `pollutant_monFreq`：监控频率（秒），默认值：86400（1天）

#### 强迫参数（POLLUTANT_FORCING）
- `pollutant_emission_file`：排放文件名，默认值：'pollutant_emission.bin'
- `pollutant_forcingPeriod`：强迫周期（秒），默认值：externForcingPeriod
- `pollutant_forcingCycle`：强迫循环（秒），默认值：externForcingCycle


#### 时间强迫参数详解
**`pollutant_forcingPeriod`** 和 **`pollutant_forcingCycle`** 控制排放场的时间变化：

- **`pollutant_forcingPeriod`**：数据切换周期（秒）
  - 定义排放场数据的时间分辨率
  - 每Period秒切换一次排放数据记录
  - 示例：2592000秒 = 30天，表示每30天切换一次数据

- **`pollutant_forcingCycle`**：完整循环周期（秒）
  - 定义排放场数据的完整重复周期
  - 每Cycle秒后重新开始循环
  - 示例：31104000秒 = 360天，表示每360天重复一次

**约束条件**：
- `pollutant_forcingCycle` 必须是 `pollutant_forcingPeriod` 的整数倍
- 记录数 = `pollutant_forcingCycle` ÷ `pollutant_forcingPeriod`

**使用场景**：

1. **静态排放**（推荐用于单记录数据）：
   ```fortran
   pollutant_forcingPeriod = 0.     ! 不切换数据
   pollutant_forcingCycle  = 0.     ! 禁用周期性
   ```
   - 始终使用同一个排放记录
   - 适合只有1个数据记录的情况

2. **日变化排放**：
   ```fortran
   pollutant_forcingPeriod = 86400.     ! 1天
   pollutant_forcingCycle  = 86400.     ! 1天
   ```
   - 需要1个记录，每天重复
   - 记录数 = 1

3. **季节性变化**：
   ```fortran
   pollutant_forcingPeriod = 2592000.   ! 30天
   pollutant_forcingCycle  = 31104000.  ! 360天
   ```
   - 需要12个记录（360÷30=12），每30天切换一次
   - 记录数 = 12

4. **月变化**：
   ```fortran
   pollutant_forcingPeriod = 2592000.   ! 30天
   pollutant_forcingCycle  = 15552000.  ! 180天
   ```
   - 需要6个记录（180÷30=6），每30天切换一次
   - 记录数 = 6

## 配置步骤

### 1. 启用包
在 `packages.conf` 中启用：
```
gfd
cd_code
gmredi
diagnostics
kpp
exf
ptracers
generic_advdiff
gchem
pollutant
```
**注意**：
- 如果需要输出诊断（如EDC_SRC、EDC_SINK等），必须启用diagnostics包
- 如果需要时间平均输出，必须启用diagnostics包和ALLOW_TIMEAVE

### 2. 配置 data.pkg
```fortran
# 包启用配置
&PACKAGES
 useGMRedi=.TRUE.,
 useDIAGNOSTICS=.TRUE.,
 useEXF=.TRUE.,
 useKPP=.TRUE.,
 useCAL=.TRUE.,
 usePTRACERS=.TRUE.,
 useGCHEM=.TRUE.,
/
```

### 3. 配置 data.gchem
```fortran
# GCHEM包配置
&GCHEM_PARM01
 usePOLLUTANT = .TRUE.,
/
```

### 4. 配置 data.pollutant
```fortran
# 逻辑开关配置
&POLLUTANT_PARAMS_L
 usePollutantDecay     = .TRUE.,
 usePollutantSettling  = .TRUE.,
 usePollutantBioUptake = .TRUE.,
 usePollutantAdvection = .TRUE.,
 usePollutantDiffusion = .TRUE.,
/

# 速率参数配置
&POLLUTANT_PARAMS_R
 pollutant_decay_rate      = 1.0e-7,
 pollutant_settle_rate     = 5.0e-8,
 pollutant_biouptake_rate  = 2.0e-8,
 pollutant_forcingPeriod   = 2592000.,
 pollutant_forcingCycle    = 31104000.,
 pollutant_monFreq         = 86400.,
/

# 文件名配置
&POLLUTANT_FORCING
 pollutant_emission_file = 'pollutant_emission.bin',
/
```

### 6. 配置 data.ptracers
```fortran
&PTRACERS_PARM01
 PTRACERS_numInUse = 1,
 PTRACERS_Iter0 = 0,
 PTRACERS_names(1) = 'EDC',
 PTRACERS_long_names(1) = 'Endocrine Disrupting Chemical',
 PTRACERS_units(1) = 'mol/m3',
/
```


### 6. 准备排放文件
创建 `pollutant_emission.bin` 文件：

#### 文件格式要求
- **格式**：二进制文件（big-endian）
- **单位**：mol m⁻² s⁻¹
- **维度**：水平网格场 (sNx × sNy)
- **时间**：按 `pollutant_forcingPeriod/Cycle` 设置
- **数据类型**：Real*4 (单精度浮点数)

#### 数据生成工具
使用提供的 `create_pollutant_emission.py` 脚本：

```python
#!/usr/bin/env python3
"""
简化版 MITgcm 污染物排放文件生成脚本
- 保证南北极顺序与 MITgcm 读取一致（南极→北极）
- 直接使用 numpy 操作，最简单逻辑
Author: 汪锐
"""

import numpy as np
import pandas as pd
import struct
import os

def create_pollutant_emission_file(filename='pollutant_emission.bin',
                                   nx=180, ny=80,
                                   nrec=1,
                                   use_ocean_mask=True,
                                   river_csv='../river_emissions.csv',
                                   mask_file='./ETOPO/topo.bin'):
    """
    创建污染物排放文件（最简逻辑）
    """
    if not os.path.exists(river_csv):
        print(f"错误: 找不到河口 CSV 文件 {river_csv}")
        return False
    rivers_df = pd.read_csv(river_csv)

    # 初始化排放场
    emission_data = np.zeros((ny, nx), dtype=np.float64)

    # === 添加河口排放 ===
    for _, river in rivers_df.iterrows():
        lon = river['lon']
        lat = river['lat']
        if lon < 0:
            lon += 360
        i = int(lon * nx / 360)
        j = int((lat + 90) * ny / 180)  # 南北极顺序与 MITgcm 一致
        if 0 <= i < nx and 0 <= j < ny:
            emission_data[j, i] += river['Mid']

    # === 应用掩码 ===
    if use_ocean_mask and os.path.exists(mask_file):
        mask_data = np.fromfile(mask_file, dtype='>f4', count=nx*ny).reshape((ny, nx))
        ocean_mask = mask_data < 0  # 海洋 True
        # MITgcm 读取顺序是南北极顺序，掩码同样
        emission_data *= ocean_mask

    # === 写出二进制文件 ===
    with open(filename, 'wb') as f:
        # MITgcm 默认读取南北极顺序，直接按行扁平化即可
        f.write(struct.pack('>' + 'f'*nx*ny, *emission_data.flatten()))

    print(f"✅ 排放文件 {filename} 创建完成")
    print(f"总排放量: {np.sum(emission_data):.2e} mol/s, 非零网格: {np.sum(emission_data>0)}")
    return True


if __name__ == "__main__":
    create_pollutant_emission_file()

```

## 编译与运行

### 编译步骤
```bash
# 1. 进入实验目录
cd verification/MGO_MP_2_gchem

# 2. 生成Makefile
./genmake2 -mods=../code

# 3. 生成依赖关系
make depend

# 4. 编译
make

# 5. 检查编译结果
ls -la mitgcmuv
```

### 运行前检查
确保以下文件在运行目录：
- `data.gchem` - GCHEM包配置
- `data.ptracers` - 被动示踪剂配置
- `pollutant_emission.bin` - 排放数据文件
- `data` - 主配置文件
- `data.pkg` - 包启用配置

### 运行命令
```bash
# 单进程运行
./mitgcmuv

# 多进程运行（例如4个进程）
mpirun -np 4 ./mitgcmuv
```

## 诊断输出

### 时间平均功能
POLLUTANT包支持时间平均诊断输出，可以计算和输出各种过程的时间平均值：

#### 时间平均变量
- **`sourceAve`**：源项时间平均 (mol m⁻³ s⁻¹)
- **`sinkAve`**：汇项时间平均 (mol m⁻³ s⁻¹)  
- **`decayAve`**：降解项时间平均 (mol m⁻³ s⁻¹)
- **`settlingAve`**：沉降项时间平均 (mol m⁻³ s⁻¹)
- **`bioUptakeAve`**：生物摄取项时间平均 (mol m⁻³ s⁻¹)
- **`POLLUTANT_timeAve`**：时间平均周期 (s)

#### 时间平均机制
- 使用`PTRACERS_taveFreq`控制时间平均频率
- 在每个时间步累积时间平均数据
- 在指定频率时输出并重置平均值
- 支持与PTRACERS包的时间平均系统集成

### 诊断配置（data.diagnostics）
**前提条件**：必须启用diagnostics包（在data.pkg中设置`useDiagnostics=.TRUE.`）

```fortran
# 污染物诊断输出配置
&DIAGNOSTICS_LIST
# 污染物源项和汇项诊断
 fields(1:2,1)  = 'EDC_SRC ','EDC_SINK',
  fileName(1) = 'output/pollutant_tendency',
 frequency(1) = -2592000.,
 timePhase(1) = 0,

# 污染物浓度诊断
 fields(1:1,2)  = 'TRAC01  ',
  fileName(2) = 'output/pollutant_concentration',
 frequency(2) = -2592000.,
 timePhase(2) = 0,
/
```

**注意**：
- `EDC_SRC` 和 `EDC_SINK` 是自定义诊断名称
- `TRAC01` 是PTRACERS包提供的示踪剂浓度诊断
- `frequency` 为负值表示快照输出，正值表示时间平均
- 输出频率应与模型时间步长匹配
- 时间平均诊断需要设置`PTRACERS_taveFreq`参数

### 诊断说明
- **`EDC_SRC`**：污染物源项趋势 (mol m⁻³ s⁻¹)
  - 仅在表面层（k=1）有值
  - 表示从排放文件读取的源项
- **`EDC_SINK`**：污染物总汇项趋势 (mol m⁻³ s⁻¹)
  - 所有层都有值
  - 包含降解、沉降、生物摄取的总和
- **`EDC_DECAY`**：降解项趋势 (mol m⁻³ s⁻¹)
- **`EDC_SETTLE`**：沉降项趋势 (mol m⁻³ s⁻¹)
- **`EDC_BIOUP`**：生物摄取项趋势 (mol m⁻³ s⁻¹)
- **`EDC_TOTAL`**：总趋势 (mol m⁻³ s⁻¹) = EDC_SRC - EDC_SINK
- **`TRAC01`**：污染物浓度场 (mol m⁻³)
  - 被动示踪剂的浓度分布
- **`UTRAC01`**：污染物纬向质量加权输运 (mol m⁻³ m/s)
- **`VTRAC01`**：污染物经向质量加权输运 (mol m⁻³ m/s)
- **`WTRAC01`**：污染物垂直质量加权输运 (mol m⁻³ m/s)

### 时间平均诊断说明
- **`EDC_SRC`（时间平均）**：污染物源项时间平均 (mol m⁻³ s⁻¹)
- **`EDC_SINK`（时间平均）**：污染物总汇项时间平均 (mol m⁻³ s⁻¹)
- **`EDC_DECAY`（时间平均）**：降解项时间平均 (mol m⁻³ s⁻¹)
- **`EDC_SETTLE`（时间平均）**：沉降项时间平均 (mol m⁻³ s⁻¹)
- **`EDC_BIOUP`（时间平均）**：生物摄取项时间平均 (mol m⁻³ s⁻¹)

### 时间平均输出文件
根据 `pollutant_diags.F` 实现，会生成以下时间平均文件：
- `POLLUTANT_Srcave.0000000000.data` - 源项时间平均
- `POLLUTANT_Sinkave.0000000000.data` - 汇项时间平均
- `POLLUTANT_Decayave.0000000000.data` - 降解项时间平均
- `POLLUTANT_Settlingave.0000000000.data` - 沉降项时间平均
- `POLLUTANT_BioUptakeave.0000000000.data` - 生物摄取项时间平均

### 诊断输出文件
根据 `data.diagnostics` 配置，会生成以下文件：
- `output/pollutant_tendency.0000000000.data` - 包含EDC_SRC和EDC_SINK的源汇项场
- `output/pollutant_concentration.0000000000.data` - 包含TRAC01的浓度场
- `output/pollutant_details.0000000000.data` - 包含EDC_DECAY、EDC_SETTLE、EDC_BIOUP、EDC_TOTAL的详细汇项场
- `output/pollutant_timeave.0000000000.data` - 包含时间平均的诊断场

**文件格式**：
- 二进制格式，可使用MITgcm工具读取
- 文件名格式：`fileName.时间戳.data`
- 时间戳格式：`YYYYMMDDHHMMSS`

## 技术细节

### 源码文件结构

#### POLLUTANT 包文件
1. **`POLLUTANT.h`** - 参数声明和公共块定义
   - 逻辑开关、速率参数、文件名参数
   - 通量数组和加载索引
2. **`POLLUTANT_SIZE.h`** - 包大小定义
   - 示踪剂数量和索引定义
3. **`pollutant_readparms.F`** - 参数读取
   - 从data.pollutant文件读取用户配置
4. **`pollutant_tr_register.F`** - 示踪剂注册
   - 注册POLLUTANT示踪剂到PTRACERS系统
5. **`pollutant_fields_load.F`** - 外部场加载
   - 使用`READ_REC_XY_RS`读取排放文件
   - 时间插值处理
6. **`pollutant_calc_tendency.F`** - 源汇项计算
   - 源项：仅在表面层添加
   - 汇项：所有层应用，包含负值保护
   - 包含OBCS边界条件处理
   - 诊断数据填充（DIAGNOSTICS_FILL）
7. **`pollutant_check.F`** - 参数检查
   - 参数验证和错误检查
8. **`pollutant_diagnostics_init.F`** - 诊断初始化
   - 注册EDC_SRC、EDC_SINK等诊断
9. **`pollutant_init_fixed.F`** - 固定变量初始化
   - 初始化POLLUTANT包固定变量
10. **`pollutant_diags.F`** - 诊断输出
    - 时间平均数据处理
    - 使用标准诊断系统

#### GCHEM 包集成
- **`GCHEM.h`** - 添加usePOLLUTANT开关
- **`gchem_readparms.F`** - 调用POLLUTANT_READPARMS
- **`gchem_fields_load.F`** - 调用POLLUTANT_FIELDS_LOAD
- **`gchem_tr_register.F`** - 调用POLLUTANT_TR_REGISTER
- **`gchem_calc_tendency.F`** - 调用POLLUTANT_CALC_TENDENCY
- **`gchem_init_fixed.F`** - 调用POLLUTANT_PARAM
- **`gchem_diagnostics_init.F`** - 调用POLLUTANT_DIAGNOSTICS_INIT

### 关键算法
- **源项计算**：仅在表面层（k=1）添加，通量除以层厚
  ```fortran
  IF ( k.EQ.1 ) THEN
   sourceTerm = pollutant_flux(i,j,bi,bj) / drF(k)
  ELSE
   sourceTerm = 0. _d 0
  ENDIF
  ```
- **汇项计算**：所有层都应用，使用局部变量保护
  ```fortran
  pTr_Pollutant_safe = MAX( 0. _d 0, pTr_Pollutant(i,j,k) )
  sinkTerm = pollutant_decay_rate + pollutant_settle_rate + pollutant_biouptake_rate
  gPollutant(i,j,k) = gPollutant(i,j,k) + sourceTerm
  IF ( pTr_Pollutant_safe .GT. 0. _d 0 ) THEN
   gPollutant(i,j,k) = gPollutant(i,j,k) - sinkTerm * pTr_Pollutant_safe
  ENDIF
  ```
- **负值保护**：多层保护机制
  ```fortran
  IF ( pTr_Pollutant(i,j,k) + gPollutant(i,j,k) .LT. 0. _d 0 ) THEN
   gPollutant(i,j,k) = -pTr_Pollutant(i,j,k)
  ENDIF
  ```
- **时间插值**：使用`GET_PERIODIC_INTERVAL`进行时间权重插值
- **陆地掩码**：只在海洋网格点计算
  ```fortran
  IF ( maskC(i,j,k,bi,bj) .NE. 0. _d 0 ) THEN
   ! 计算源汇项
  ENDIF
  ```
- **诊断输出**：支持6种诊断变量
  - `EDC_SRC`：源项诊断
  - `EDC_SINK`：总汇项诊断  
  - `EDC_DECAY`：降解项诊断
  - `EDC_SETTLE`：沉降项诊断
  - `EDC_BIOUP`：生物摄取项诊断
  - `EDC_TOTAL`：总趋势诊断
- **时间平均**：支持时间平均诊断输出
  - 使用`PTRACERS_taveFreq`控制输出频率
  - 累积时间平均数据：`sourceAve`, `sinkAve`, `decayAve`, `settlingAve`, `bioUptakeAve`
  - 在指定频率时输出并重置平均值

### 数组分配
- **`pollutant_flux`**：存储插值后的通量场
  - 维度：(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
- **`pollutantFlux0/1`**：存储时间插值的两个时间点
  - 维度：(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
- **`gPollutant`**：POLLUTANT包的tendency数组
  - 维度：(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
- **诊断数组**：局部诊断数组用于输出
  - `sourceDiag`, `sinkDiag`, `decayDiag`, `settleDiag`, `bioupDiag`, `totalDiag`
- **时间平均数组**：用于累积时间平均数据
  - `sourceAve`, `sinkAve`, `decayAve`, `settlingAve`, `bioUptakeAve`
  - 维度：(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
  - `POLLUTANT_timeAve`：时间平均周期数组，维度：(nSx,nSy)

## 注意事项

### 配置注意事项
1. **包启用**：确保在 `packages.conf` 中启用了 `pollutant` 包
2. **文件格式**：排放文件必须是 MITgcm 可读的二进制格式（big-endian）
3. **时间设置**：`pollutant_forcingPeriod/Cycle` 必须与排放文件的时间轴匹配
4. **单位一致性**：确保所有参数单位一致（时间：秒，浓度：mol m⁻³）
5. **参数检查**：运行时会自动检查参数合理性，注意STDOUT中的警告信息
6. **负值保护**：已实现多层保护机制，但仍需注意参数设置合理性
7. **示踪剂索引**：POLLUTANT包使用PTRACERS的索引1（TRAC01）
8. **海洋掩码**：确保地形文件正确，海洋区域为负值（深度）
9. **诊断输出**：需要启用diagnostics包才能输出EDC_SRC、EDC_SINK等诊断
10. **内存使用**：POLLUTANT包会增加内存使用，注意系统资源
11. **时间平均**：使用PTRACERS_taveFreq控制时间平均输出频率

### 性能考虑
1. **内存使用**：pollutant数组会增加内存使用量
2. **I/O性能**：频繁读取排放文件可能影响性能
3. **计算开销**：额外的源汇项计算会增加CPU时间

### 数值稳定性
1. **时间步长**：确保化学时间步长不会导致数值不稳定
2. **速率参数**：避免过大的降解/沉降速率
3. **边界条件**：注意边界处的数值处理

## 示例配置

### 完整配置文件示例

#### data.pkg
```fortran
# 启用必要的包
&PACKAGES
 useGMRedi=.TRUE.,
 useDIAGNOSTICS=.TRUE.,
 useEXF=.TRUE.,
 useKPP=.TRUE.,
 useCAL=.TRUE.,
 usePTRACERS=.TRUE.,
 useGCHEM=.TRUE.,
 useMNC=.TRUE.,
/
```

#### data.gchem
```fortran
# GCHEM包配置
&GCHEM_PARM01
 usePOLLUTANT = .TRUE.,
/
```


#### data.pollutant
```fortran
# 文件名配置
&POLLUTANT_FORCING
 pollutant_emission_file = 'pollutant_emission.bin',
 pollutant_forcingPeriod = 86400.,
 pollutant_forcingCycle = 86400.,
/

# 逻辑开关配置
&POLLUTANT_PARAMS_L
 usePollutantDecay     = .TRUE.,
 usePollutantSettling  = .TRUE.,
 usePollutantBioUptake = .TRUE.,
 usePollutantAdvection = .TRUE.,
 usePollutantDiffusion = .TRUE.,
/

# 速率参数配置
&POLLUTANT_PARAMS_R
 pollutant_decay_rate      = 1.0e-7,
 pollutant_settle_rate     = 5.0e-8,
 pollutant_biouptake_rate  = 2.0e-8,
 pollutant_monFreq         = 86400.,
/
```

#### data.ptracers
```fortran
&PTRACERS_PARM01
 PTRACERS_numInUse=1,
 PTRACERS_Iter0=0,
# tracer 1 - pollutant
 PTRACERS_names(1)='Pollutant',
 PTRACERS_long_names(1)='Ocean Pollutant Concentration [mol/m^3]',
 PTRACERS_units(1)='mol/m^3',
 PTRACERS_advScheme(1)=77,
 PTRACERS_diffKh(1)=0.E3,
 PTRACERS_diffKr(1)=3.E-5,
 PTRACERS_useGMRedi(1)=.TRUE.,
 PTRACERS_initialFile(1)=' ',
 PTRACERS_ref(1:15,1) = 15*0.,
 PTRACERS_EvPrRn(1)=0.,
/
```

#### data.diagnostics
```fortran
# 污染物诊断输出配置
&DIAGNOSTICS_LIST
# 污染物源项和汇项诊断
 fields(1:2,1)  = 'EDC_SRC ','EDC_SINK',
  fileName(1) = 'output/pollutant_tendency',
 frequency(1) = -2592000.,
 timePhase(1) = 0,

# 污染物详细汇项诊断
 fields(1:4,2)  = 'EDC_DECAY','EDC_SETTLE','EDC_BIOUP','EDC_TOTAL',
  fileName(2) = 'output/pollutant_details',
 frequency(2) = -2592000.,
 timePhase(2) = 0,

# 污染物浓度诊断
 fields(1:1,3)  = 'PTRAC01  ',
  fileName(3) = 'output/pollutant_concentration',
 frequency(3) = -2592000.,
 timePhase(3) = 0,

# 时间平均诊断（正值表示时间平均）
 fields(1:5,4)  = 'EDC_SRC ','EDC_SINK ','EDC_DECAY','EDC_SETTLE','EDC_BIOUP',
  fileName(4) = 'output/pollutant_timeave',
 frequency(4) = 2592000.,
 timePhase(4) = 0,
/
```

## 故障排除

### 常见问题及解决方案

#### 1. 编译错误
**问题**：编译时出现"Symbol has no IMPLICIT type"错误
**原因**：缺少头文件包含或变量未声明
**解决**：确保包含了`POLLUTANT.h`、`POLLUTANT_SIZE.h`等必要头文件

**问题**：编译时出现"Unterminated character constant"错误
**原因**：Fortran固定格式行长度超过72列
**解决**：检查字符串长度，必要时分行

#### 2. 运行时错误
**问题**：运行时找不到排放文件
**原因**：文件路径或文件名错误
**解决**：检查`pollutant_emission_file`参数和文件是否存在

**问题**：PTRAC01出现负值
**原因**：汇项参数过大或时间步长不稳定
**解决**：检查速率参数和时间步长，已实现负值保护机制

**问题**：诊断输出为零
**原因**：诊断未正确注册或计算错误
**解决**：检查`data.diagnostics`配置和`pollutant_diagnostics_init.F`

**问题**：段错误（SIGSEGV）
**原因**：代码结构错误或内存访问问题
**解决**：已修复以下问题：
- 添加了OBCS头文件包含保护
- 修复了边界条件处理的条件编译
- 简化了pollutant_diags.F，使用标准诊断系统
- 修复了gchem_calc_tendency.F中的诊断填充错误

#### 3. 参数检查
**问题**：参数检查失败
**原因**：参数设置不合理
**解决**：查看STDOUT中的参数检查信息，调整参数值

#### 4. 排放文件问题
**问题**：海洋网格点数为0，所有排放值都为0
**原因**：海洋掩码逻辑错误（地形数据为负值表示海洋）
**解决**：检查地形文件格式，确保海洋掩码逻辑正确

**问题**：排放文件读取失败
**原因**：文件路径错误或文件格式不正确
**解决**：检查`pollutant_emission_file`参数，确保文件存在且格式正确

#### 5. 诊断输出问题
**问题**：EDC_SRC、EDC_SINK等诊断输出为零
**原因**：诊断未正确注册或计算错误
**解决**：检查`data.diagnostics`配置，确保启用了diagnostics包

### 调试建议
1. **使用调试模式**：设置`debugLevel=2`查看详细输出
2. **检查日志**：查看`available_diagnostics.log`确认诊断名称
3. **验证配置**：确保示踪物索引不与其他包冲突
4. **测试数据**：使用简单的测试数据验证功能
5. **段错误调试**：使用gdb等调试工具定位内存访问问题
6. **时间平均测试**：检查时间平均输出是否正确累积和输出

### 性能优化
1. **减少I/O**：使用较大的时间步长减少文件读取频率
2. **内存优化**：根据实际需要调整数组大小
3. **并行优化**：使用合适的进程数进行并行计算

## 扩展功能

### 添加新污染物
如需添加更多污染物或修改物理过程，可参考现有代码结构：

1. **参数扩展**：在 `GCHEM.h` 中添加新参数
   ```fortran
   LOGICAL useNewPollutant
   _RL newPollutant_rate
   INTEGER NEWPOLLUTANT_pTr_i1
   ```

2. **数组扩展**：在 `GCHEM_FIELDS.h` 中添加新数组
   ```fortran
   _RL newPollutant_flux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
   ```

3. **计算扩展**：在 `gchem_calc_tendency.F` 中添加新过程
   ```fortran
   IF ( useNewPollutant ) THEN
    gchemTendency(idx,jdx,k,bi,bj,jTr) = 
     &  gchemTendency(idx,jdx,k,bi,bj,jTr)
     &  - newPollutant_rate * pTracer(idx,jdx,k,bi,bj,iTr)
   ENDIF
   ```

4. **诊断扩展**：在 `gchem_diagnostics_init.F` 中添加新诊断
   ```fortran
   CALL DIAGNOSTICS_ADDTOLIST( 'NEWPOLLUTANT_SINK',
     &  DIAG_GCHEM_TENDENCY, 1, myThid )
   ```

### 自定义物理过程
- **非线性过程**：修改汇项计算，添加浓度依赖项
- **空间变化**：使用空间变化的速率参数
- **时间变化**：添加时间依赖的源汇项
- **耦合过程**：与其他示踪剂或生物过程耦合

### 高级功能
- **多时间尺度**：实现不同过程的多种时间尺度
- **自适应时间步**：根据浓度变化调整时间步长
- **数据同化**：集成观测数据进行参数优化

## 参考文献

- MITgcm官方文档：https://mitgcm.readthedocs.io/en/latest/
- GCHEM包文档：https://mitgcm.readthedocs.io/en/latest/phys_pkgs/phys_pkgs.html#gchem
- PTRACERS包文档：https://mitgcm.readthedocs.io/en/latest/phys_pkgs/phys_pkgs.html#ptracers

## 版本信息

- **MITgcm版本**：checkpoint68n
- **POLLUTANT包版本**：v1.1
- **最后更新**：2025年1月
- **兼容性**：与MITgcm GCHEM + PTRACERS框架完全兼容

## 更新日志

### v1.2 (2025年1月)
- **完善参数验证机制**：
  - 参考DIC包实现全面的参数验证
  - 添加参数合理性检查和错误报告
  - 提供详细的参数输出和说明
- **优化时间插值机制**：
  - 参考CFC包改进时间插值逻辑
  - 添加调试输出和AUTODIFF支持
  - 增强错误处理和文件检查
- **增强诊断输出功能**：
  - 新增EDC_FLUX、EDC_CONC、EDC_MASS诊断
  - 提供完整的参数检查机制
- **代码结构优化**：
  - 按照CFC/DIC/DARWIN包结构重构
  - 提高代码可维护性和稳定性
  - 完善错误处理和调试功能

### v1.1 (2025年1月)
- **修复段错误问题**：
  - 添加OBCS头文件包含保护
  - 修复边界条件处理的条件编译
  - 简化pollutant_diags.F，使用标准诊断系统
  - 修复gchem_calc_tendency.F中的诊断填充错误
- **优化输出架构**：
  - 使用MITgcm标准诊断系统进行输出
  - 移除复杂的MNC输出代码
  - 提高代码稳定性和可维护性
- **添加时间平均功能**：
  - 支持源项、汇项、降解、沉降、生物摄取的时间平均
  - 集成PTRACERS时间平均系统
  - 提供完整的时间平均诊断输出
- **完善文档**：
  - 更新故障排除指南
  - 添加时间平均功能说明
  - 完善技术细节说明

### v1.0 (2024)
- 初始版本发布
- 实现基本的污染物源汇项功能
- 支持6种诊断输出
- 集成到GCHEM包框架
- 提供完整的配置示例和故障排除指南

## 致谢

感谢MITgcm开发团队提供的优秀框架，以及所有贡献者的努力。
