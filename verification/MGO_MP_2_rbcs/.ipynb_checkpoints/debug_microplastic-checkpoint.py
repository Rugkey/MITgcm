#!/usr/bin/env python3
"""
微塑料模拟调试脚本
用于诊断数据问题
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False

def debug_simulation():
    """调试微塑料模拟"""
    print("=" * 60)
    print("微塑料模拟调试")
    print("=" * 60)
    
    # 1. 检查河口排放数据
    print("\n1. 检查河口排放数据...")
    try:
        df = pd.read_csv('river_emissions.csv')
        emissions = df['Mid'].values
        print(f"  河口数量: {len(emissions)}")
        print(f"  排放量范围: {emissions.min():.2f} - {emissions.max():.2f} kg/day")
        print(f"  平均排放量: {emissions.mean():.2f} kg/day")
        print(f"  前5个河口排放量: {emissions[:5]}")
    except Exception as e:
        print(f"  错误: {e}")
        return
    
    # 2. 检查高斯随机场
    print("\n2. 检查高斯随机场...")
    nx, ny, nz = 180, 80, 40
    field_3d = np.zeros((nz, ny, nx))
    
    # 创建测试高斯场
    for k in range(nz):
        noise = np.random.normal(0, 1, (ny, nx))
        field_2d = noise * 0.01 + 0.01  # 平均浓度 0.01 kg/m³
        field_2d = np.maximum(field_2d, 0.0)
        field_3d[k, :, :] = field_2d
    
    print(f"  高斯场统计:")
    print(f"    平均值: {field_3d.mean():.6f} kg/m³")
    print(f"    标准差: {field_3d.std():.6f} kg/m³")
    print(f"    最小值: {field_3d.min():.6f} kg/m³")
    print(f"    最大值: {field_3d.max():.6f} kg/m³")
    
    # 3. 检查河口排放转换
    print("\n3. 检查河口排放转换...")
    # 模拟一个河口的排放转换
    test_emission = emissions[0]  # 第一个河口的排放量
    grid_area = 4e10  # m²
    layer_thickness = 10  # m
    grid_volume = grid_area * layer_thickness  # m³
    concentration = test_emission / grid_volume  # kg/m³
    
    print(f"  测试河口排放: {test_emission:.2f} kg/day")
    print(f"  网格面积: {grid_area:.2e} m²")
    print(f"  网格体积: {grid_volume:.2e} m³")
    print(f"  转换后浓度: {concentration:.6f} kg/m³")
    
    # 4. 检查地形掩膜
    print("\n4. 检查地形掩膜...")
    try:
        with open('input/ETOPO/topo.bin', 'rb') as f:
            topo_data = np.frombuffer(f.read(), dtype='>f4')
        topo_2d = topo_data.reshape(ny, nx)
        ocean_mask = topo_2d < 0
        
        print(f"  地形数据范围: {topo_2d.min():.2f} - {topo_2d.max():.2f} m")
        print(f"  海洋网格点: {np.count_nonzero(ocean_mask)}")
        print(f"  陆地网格点: {np.count_nonzero(~ocean_mask)}")
        print(f"  海洋覆盖率: {np.count_nonzero(ocean_mask) / (ny * nx) * 100:.1f}%")
    except Exception as e:
        print(f"  错误: {e}")
    
    # 5. 创建简单的可视化
    print("\n5. 创建调试可视化...")
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    
    # 表层浓度
    surface_field = field_3d[0, :, :]
    im1 = axes[0,0].pcolormesh(surface_field, cmap='viridis', shading='auto')
    axes[0,0].set_title('高斯随机场 (表层)')
    axes[0,0].set_xlabel('经度索引')
    axes[0,0].set_ylabel('纬度索引')
    plt.colorbar(im1, ax=axes[0,0])
    
    # 地形
    if 'topo_2d' in locals():
        im2 = axes[0,1].pcolormesh(topo_2d, cmap='terrain', shading='auto')
        axes[0,1].set_title('地形 (m)')
        axes[0,1].set_xlabel('经度索引')
        axes[0,1].set_ylabel('纬度索引')
        plt.colorbar(im2, ax=axes[0,1])
    
    # 海洋掩膜
    if 'ocean_mask' in locals():
        im3 = axes[1,0].pcolormesh(ocean_mask.astype(float), cmap='RdYlBu', shading='auto')
        axes[1,0].set_title('海洋掩膜 (蓝色=海洋)')
        axes[1,0].set_xlabel('经度索引')
        axes[1,0].set_ylabel('纬度索引')
        plt.colorbar(im3, ax=axes[1,0])
    
    # 应用掩膜后的场
    if 'ocean_mask' in locals():
        masked_field = surface_field * ocean_mask
        im4 = axes[1,1].pcolormesh(masked_field, cmap='viridis', shading='auto')
        axes[1,1].set_title('应用掩膜后的场')
        axes[1,1].set_xlabel('经度索引')
        axes[1,1].set_ylabel('纬度索引')
        plt.colorbar(im4, ax=axes[1,1])
    
    plt.tight_layout()
    plt.savefig('debug_microplastic.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    print(f"\n调试可视化已保存到 debug_microplastic.png")
    print("=" * 60)

if __name__ == "__main__":
    debug_simulation()
