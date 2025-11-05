#!/usr/bin/env python3
"""
简化版 MITgcm 污染物排放文件生成脚本
- 将河流浓度数据转换为物理上正确的排放通量
- 采用“先掩码后映射”的健壮逻辑，确保排放点落在海洋网格
Author: 汪锐
"""

import numpy as np
import pandas as pd
import os

def find_nearest_ocean_cell(start_j, start_i, ocean_mask, max_search_dist=5):
    """在一个点周围搜索最近的海洋网格。"""
    ny, nx = ocean_mask.shape
    # 检查起始点本身
    if ocean_mask[start_j, start_i]:
        return start_j, start_i

    # 从1开始，向外扩展搜索窗口
    for dist in range(1, max_search_dist + 1):
        min_j = max(0, start_j - dist)
        max_j = min(ny - 1, start_j + dist)
        min_i = max(0, start_i - dist)
        max_i = min(nx - 1, start_i + dist)

        best_point = None
        min_dist_sq = float('inf')

        # 遍历搜索窗口的边界
        for j in range(min_j, max_j + 1):
            for i in range(min_i, max_i + 1):
                # 只检查边界上的点
                if j > min_j and j < max_j and i > min_i and i < max_i:
                    continue
                
                if ocean_mask[j, i]:
                    dist_sq = (j - start_j)**2 + (i - start_i)**2
                    if dist_sq < min_dist_sq:
                        min_dist_sq = dist_sq
                        best_point = (j, i)
        
        if best_point:
            return best_point

    return None # 如果在搜索范围内找不到海洋点

def create_pollutant_emission_file(filename='pollutant_emission.bin',
                                   nx=180, ny=80,
                                   river_csv='./river_emissions.csv',
                                   mask_file='./input/ETOPO/topo.bin'):

    # --- 1. 定义模型网格中心 ---
    reso = 360.0 / nx
    xc = np.arange(0.0 + reso / 2.0, 360.0, reso)
    yc = np.arange(-80.0 + reso / 2.0, 80.0, reso)

    # --- 2. 提前加载海洋掩码 ---
    if os.path.exists(mask_file):
        try:
            mask_data = np.fromfile(mask_file, dtype='>f4', count=nx*ny).reshape((ny, nx))
            ocean_mask = (mask_data < 0)
        except Exception as e:
            print(f"错误: 应用掩码时出错: {e}")
            return False
    else:
        print(f"错误: 找不到地形文件 {mask_file}，无法应用海洋掩码。")
        return False

    # --- 3. 读取并处理CSV数据 ---
    if not os.path.exists(river_csv):
        print(f"错误: 找不到河口 CSV 文件 {river_csv}")
        return False
    
    try:
        rivers_df = pd.read_csv(river_csv)
    except Exception as e:
        print(f"读取CSV文件时出错: {e}")
        return False

    # --- 4. 初始化排放场并进行健壮的映射 ---
    emission_data = np.zeros((ny, nx), dtype='>f4')
    points_mapped = 0
    points_discarded = 0

    print(f"Mapping {len(rivers_df)} data points using robust ocean-first logic...")
    for _, river in rivers_df.iterrows():
        lon = river['lon']
        lat = river['lat']
        emission_rate_yearly = river.get('Mid', 0)

        # 转换为秒排放通量 (mol/s)
        seconds_per_year = 31557600.0 # 365.25 * 24 * 3600
        emission_flux = emission_rate_yearly*1000000 / seconds_per_year

        if lon < 0:
            lon += 360
        
        # 找到最近邻的网格索引
        initial_i = np.abs(xc - lon).argmin()
        initial_j = np.abs(yc - lat).argmin()

        # 查找最近的海洋网格
        target_cell = find_nearest_ocean_cell(initial_j, initial_i, ocean_mask)

        if target_cell:
            j, i = target_cell
            emission_data[j, i] += emission_flux
            points_mapped += 1
        else:
            points_discarded += 1
            # print(f"警告: 无法为 lon={lon}, lat={lat} 找到海洋网格，该点被丢弃。")

    if points_discarded > 0:
        print(f"警告: {points_discarded} 个数据点因附近无海洋网格而被丢弃。")

    # --- 5. 写出二进制文件 ---
    try:
        with open(filename, 'wb') as f:
            emission_data.tofile(f)
        print(f"✅ 排放文件 {filename} 创建完成")
        print(f"   总排放量: {np.sum(emission_data):.2e} g/s, 非零网格数: {np.count_nonzero(emission_data)}")
        print(f"   成功映射 {points_mapped} 个点，丢弃 {points_discarded} 个点。")
    except Exception as e:
        print(f"写入二进制文件时出错: {e}")
        return False

    return True


if __name__ == "__main__":
    create_pollutant_emission_file()
