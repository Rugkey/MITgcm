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
