#!/usr/bin/env python3
"""
简化版 MITgcm 污染物排放文件生成脚本
- 将河流浓度数据转换为物理上正确的排放通量
- 使用最近邻方法进行网格映射
Author: 汪锐
"""

import numpy as np
import pandas as pd
import os

def create_pollutant_emission_file(filename='pollutant_emission.bin',
                                   nx=180, ny=80,
                                   river_csv='./river_emissions.csv',
                                   mask_file='./input/ETOPO/topo.bin'):
    """
    创建污染物排放文件，通过 浓度*流量 的方式计算排放通量。
    """
    # --- 1. 关键参数定义 ---
    # !!! 警告: 这是一个假定的平均河流流量值 !!!
    # !!! 为了获得科学准确的结果，您应该为每条河流提供真实的流量数据 !!!
    assumed_river_discharge_m3_s = 1000.0
    print("-" * 50)
    print(f"警告: 正在使用假定的河流流量 {assumed_river_discharge_m3_s} m³/s 进行计算。")
    print("      为了获得准确结果，请在CSV文件中提供真实的流量数据。")
    print("-" * 50)

    # --- 2. 定义模型网格中心 ---
    reso = 360.0 / nx
    xc = np.arange(0.0 + reso / 2.0, 360.0, reso)
    yc = np.arange(-80.0 + reso / 2.0, 80.0, reso)

    # --- 3. 读取并处理CSV数据 ---
    if not os.path.exists(river_csv):
        print(f"错误: 找不到河口 CSV 文件 {river_csv}")
        return False
    
    try:
        rivers_df = pd.read_csv(river_csv)
    except Exception as e:
        print(f"读取CSV文件时出错: {e}")
        return False

    # --- 4. 初始化排放场并进行映射 ---
    emission_data = np.zeros((ny, nx), dtype='>f4')

    print(f"Mapping {len(rivers_df)} data points using nearest neighbor logic...")
    for _, river in rivers_df.iterrows():
        lon = river['lon']
        lat = river['lat']
        # 读取浓度值 (mol/m³)
        concentration = river.get('Mid', 0)
        # 如果CSV文件中有 'discharge' 列，则使用它，否则使用假定值
        discharge = river.get('discharge', assumed_river_discharge_m3_s)

        # 计算排放通量 (mol/s)
        emission_flux = concentration * discharge

        if lon < 0:
            lon += 360
        
        i = np.abs(xc - lon).argmin()
        j = np.abs(yc - lat).argmin()
        
        emission_data[j, i] += emission_flux

    # === 5. 应用海洋掩码 ===
    if os.path.exists(mask_file):
        try:
            mask_data = np.fromfile(mask_file, dtype='>f4', count=nx*ny).reshape((ny, nx))
            ocean_mask = (mask_data < 0)
            emission_data *= ocean_mask
        except Exception as e:
            print(f"应用掩码时出错: {e}")
    else:
        print(f"警告: 找不到地形文件 {mask_file}，未应用海洋掩码。")

    # === 6. 写出二进制文件 ===
    try:
        with open(filename, 'wb') as f:
            emission_data.tofile(f)
        print(f"✅ 排放文件 {filename} 创建完成")
        print(f"   总排放量: {np.sum(emission_data):.2e} mol/s, 非零网格数: {np.count_nonzero(emission_data)}")
    except Exception as e:
        print(f"写入二进制文件时出错: {e}")
        return False

    return True


if __name__ == "__main__":
    create_pollutant_emission_file()
