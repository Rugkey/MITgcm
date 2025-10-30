#!/usr/bin/env python3
"""
微塑料全球海洋模拟脚本
基于MITgcm模型，实现微塑料在全球海洋中的传输模拟

功能：
1. 创建高斯随机分布的微塑料初始场
2. 处理河口微塑料排放数据
3. 使用topo.bin将陆地浓度置零
4. 可视化浓度和河口情况
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import ndimage
import os

plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False

class MicroplasticSimulation:
    def __init__(self, nx=180, ny=80, nz=40):
        """初始化微塑料模拟类"""
        self.nx = nx
        self.ny = ny 
        self.nz = nz
        
        # 网格设置
        self.dx = 2.0  # 经度分辨率 (度)
        self.dy = 2.0  # 纬度分辨率 (度)
        
        # 坐标网格
        self.lon = np.arange(0, 360, self.dx)  # 经度: 0-358度
        self.lat = np.arange(-80, 80, self.dy)  # 纬度: -80到78度
        
        print(f"网格设置: {nx} x {ny} x {nz}")
        print(f"经度范围: {self.lon[0]}° - {self.lon[-1]}°")
        print(f"纬度范围: {self.lat[0]}° - {self.lat[-1]}°")
    
    def load_river_emissions(self, csv_file='river_emissions.csv'):
        """加载河口微塑料浓度数据"""
        print("加载河口微塑料浓度数据...")
        
        df = pd.read_csv(csv_file)
        rivers = df['rivers'].values
        lats = df['lat'].values  
        lons = df['lon'].values
        # 统一经度到 [0, 360]
        lons = np.mod(lons, 360.0)
        concentrations = df['Mid'].values
        
        print(f"加载了 {len(rivers)} 个河口的浓度数据")
        print(f"浓度范围: {concentrations.min():.2f} - {concentrations.max():.2f}")
        
        return rivers, lats, lons, concentrations
    
    def fill_missing_with_gaussian(self, field_3d, ocean_mask, mean=5.0, std=1000.0, correlation_length=8.0):
        """仅在海洋且当前为0的网格，用掩膜归一化高斯进行填充（表层及各层）。"""
        print("仅填充海洋中缺失(为0)的网格为高斯背景...")

        sigma = correlation_length / self.dx
        eps = 1e-6

        for k in range(self.nz):
            layer = field_3d[k]
            need_fill_mask = (layer <= 0) & ocean_mask

            if not np.any(need_fill_mask):
                continue

            noise = np.random.normal(0.0, 1.0, (self.ny, self.nx)) * need_fill_mask
            num = ndimage.gaussian_filter(noise, sigma=sigma, mode='nearest')
            den = ndimage.gaussian_filter(need_fill_mask.astype(float), sigma=sigma, mode='nearest')
            smooth = num / np.maximum(den, eps)

            ocean_values = smooth[need_fill_mask]
            ocean_mean = ocean_values.mean() if ocean_values.size > 0 else 0.0
            ocean_std = ocean_values.std() if ocean_values.size > 0 else 1.0
            if ocean_std < 1e-12:
                ocean_std = 1.0

            scaled = mean + std * (smooth - ocean_mean) / ocean_std
            scaled = np.maximum(scaled, 0.0)
            layer[need_fill_mask] = scaled[need_fill_mask]

            field_3d[k] = layer

        return field_3d
    
    # 已移除“移动到最近海洋点”的逻辑，改为简单映射到最近网格点
    
    def add_river_emissions(self, field_3d, rivers, lats, lons, concentrations, decay_radius=8.0):
        """在最近海洋格点设置河口浓度，并在周围做高斯扩散。
        - decay_radius: 扩散半径（单位：格）"""
        print("设置河口微塑料浓度(含高斯扩散)...")
        
        # 加载地形数据用于判断海洋/陆地
        topo_file = 'input/ETOPO/topo.bin'
        if os.path.exists(topo_file):
            with open(topo_file, 'rb') as f:
                topo_data = np.fromfile(f, dtype='>f4').reshape((self.ny, self.nx))
            print(f"地形数据加载成功: 形状{topo_data.shape}, 范围{topo_data.min():.1f}到{topo_data.max():.1f}")
        else:
            print("警告: 找不到topo.bin文件，无法判断海洋/陆地")
            topo_data = np.zeros((self.ny, self.nx))  # 假设都是海洋
        
        # 创建河口浓度场(表层)
        river_field_2d = np.zeros((self.ny, self.nx))
        moved_rivers = 0

        # 河口数据本身就是浓度单位；设置到最近“通海”的海洋格点（更大半径、邻居优先）
        for i, (river, lat, lon, concentration) in enumerate(zip(rivers, lats, lons, concentrations)):
            # 直接映射到最近海洋网格（掩膜之后执行，确保写在海上）
            lat_idx = int(np.argmin(np.abs(self.lat - lat)))
            lon_idx = int(np.argmin(np.abs(self.lon - lon)))
            # 在更大范围内寻找“更开放”的海洋格点（避免单格封闭海湾）
            def ocean_neighbors_count(j, i):
                count = 0
                for ddy in (-1, 0, 1):
                    for ddx in (-1, 0, 1):
                        if ddy == 0 and ddx == 0:
                            continue
                        jj = j + ddy
                        ii = i + ddx
                        if 0 <= jj < self.ny and 0 <= ii < self.nx and topo_data[jj, ii] < 0:
                            count += 1
                return count

            best = None  # (neighbors, -distance, depth_abs, j, i)
            max_radius = 20
            for radius in range(0, max_radius + 1):
                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        j = lat_idx + dy
                        i = lon_idx + dx
                        if not (0 <= j < self.ny and 0 <= i < self.nx):
                            continue
                        if topo_data[j, i] < 0:
                            neighbors = ocean_neighbors_count(j, i)
                            dist = np.hypot(dx, dy)
                            depth_abs = -topo_data[j, i]
                            cand = (neighbors, -dist, depth_abs, j, i)
                            if (best is None) or (cand > best):
                                best = cand
                # 早停：一旦半径增长到某层已经找到较好候选且邻居数较多
                if best is not None and best[0] >= 5 and radius >= 3:
                    break

            if best is not None:
                lat_idx, lon_idx = best[3], best[4]

            # 调试打印：标注点最终是否在海洋
            is_ocean = topo_data[lat_idx, lon_idx] < 0
            if i < 15:  # 打印前15个以免刷屏
                print(f"  调试-河口 '{river}': 目标({lat:.2f}N,{lon:.2f}E) -> 网格({lat_idx},{lon_idx}), 深度={topo_data[lat_idx, lon_idx]:.1f}m, 海洋={is_ocean}")
            
            # 在河口周围做高斯扩散（中心保持原浓度，周围递减，仅在海洋格点）
            R = int(max(1, round(decay_radius)))
            sigma = max(1e-6, decay_radius / 2.0)
            for dy in range(-R, R + 1):
                for dx in range(-R, R + 1):
                    j = lat_idx + dy
                    i2 = lon_idx + dx
                    if 0 <= j < self.ny and 0 <= i2 < self.nx and topo_data[j, i2] < 0:
                        r = np.hypot(dx, dy)
                        if r <= decay_radius:
                            weight = np.exp(-0.5 * (r / sigma) ** 2)
                            candidate_value = concentration * weight
                            # 取较大值，避免被更小的扩散值覆盖
                            if candidate_value > river_field_2d[j, i2]:
                                river_field_2d[j, i2] = candidate_value
            
            if i < 10:
                print(f"  {river}: ({lat:.1f}°N, {lon:.1f}°E) -> 网格({lat_idx}, {lon_idx}), 中心浓度: {concentration:.1f}, 扩散半径: {decay_radius}")
        
        # 在河口位置替换背景浓度，而不是叠加
        final_field = field_3d.copy()
        river_mask = river_field_2d > 0
        final_field[0, river_mask] = river_field_2d[river_mask]
        
        print(f"河口浓度统计:")
        print(f"  移动到海洋的河口数: {moved_rivers} / {len(rivers)}")
        print(f"  河口总浓度: {river_field_2d.sum():.2f}")
        print(f"  有河口浓度的网格点: {np.count_nonzero(river_field_2d)}")
        print(f"  最大河口浓度: {river_field_2d.max():.1f}")
        print(f"  应用前场总浓度: {field_3d.sum():.2f}")
        print(f"  应用后场总浓度: {final_field.sum():.2f}")
        
        return final_field, river_field_2d
    
    def apply_ocean_mask(self, field_3d, topo_file='input/ETOPO/topo.bin'):
        """使用topo.bin将陆地浓度置零（严格：topo<0 视为海洋）。"""
        print("应用海洋掩膜...")
        
        try:
            with open(topo_file, 'rb') as f:
                topo_data = np.frombuffer(f.read(), dtype='>f4')
            
            topo_2d = topo_data.reshape(self.ny, self.nx)
            ocean_mask = topo_2d < 0
    
            # 应用掩膜前的统计
            print(f"应用掩膜前:")
            print(f"  总浓度: {field_3d.sum():.2f}")
            print(f"  非零网格点: {np.count_nonzero(field_3d)}")
            print(f"  最大浓度: {field_3d.max():.6f}")
            
            for k in range(self.nz):
                field_3d[k, :, :] = field_3d[k, :, :] * ocean_mask
            
            print(f"海洋掩膜应用完成")
            print(f"  海洋网格点: {np.count_nonzero(ocean_mask)}")
            print(f"  陆地网格点: {np.count_nonzero(~ocean_mask)}")
            print(f"  海洋覆盖率: {np.count_nonzero(ocean_mask) / (self.ny * self.nx) * 100:.1f}%")
            print(f"应用掩膜后:")
            print(f"  总浓度: {field_3d.sum():.2f}")
            print(f"  非零网格点: {np.count_nonzero(field_3d)}")
            print(f"  最大浓度: {field_3d.max():.6f}")
            
        except FileNotFoundError:
            print(f"警告: 未找到地形文件 {topo_file}")
            print("跳过海洋掩膜应用")
        
        return field_3d
    
    def write_binary_file(self, field_3d, filename):
        """将3D场写入二进制文件"""
        print(f"写入二进制文件: {filename}")
        
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'wb') as f:
            f.write(field_3d.astype('>f4').tobytes())
        
        print(f"文件大小: {os.path.getsize(filename) / 1024 / 1024:.2f} MB")
    
    def create_visualization(self, field_3d, rivers, lats, lons, concentrations, output_dir='results'):
        """创建简化可视化：1) 浓度分布 2) 河口位置"""
        print("创建简化可视化...")
        
        os.makedirs(output_dir, exist_ok=True)
        
        # 创建坐标网格
        lon_grid, lat_grid = np.meshgrid(self.lon, self.lat)
        surface_field = field_3d[0, :, :]
        
        # 计算移动后的河口坐标用于可视化
        print("计算移动后的河口坐标用于可视化...")
        topo_file = 'input/ETOPO/topo.bin'
        if os.path.exists(topo_file):
            with open(topo_file, 'rb') as f:
                topo_data = np.fromfile(f, dtype='>f4').reshape((self.ny, self.nx))
        else:
            topo_data = np.zeros((self.ny, self.nx))
        
        # 存储移动后的坐标
        moved_lats = []
        moved_lons = []
        
        for river, lat, lon in zip(rivers, lats, lons):
            # 最近网格索引
            lat_idx = int(np.argmin(np.abs(self.lat - lat)))
            lon_idx = int(np.argmin(np.abs(self.lon - lon)))
            # 使用与赋值相同的“通海优先”搜索
            def ocean_neighbors_count(j, i):
                count = 0
                for ddy in (-1, 0, 1):
                    for ddx in (-1, 0, 1):
                        if ddy == 0 and ddx == 0:
                            continue
                        jj = j + ddy
                        ii = i + ddx
                        if 0 <= jj < self.ny and 0 <= ii < self.nx and topo_data[jj, ii] < 0:
                            count += 1
                return count

            best = None
            max_radius = 20
            for radius in range(0, max_radius + 1):
                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        j = lat_idx + dy
                        i = lon_idx + dx
                        if not (0 <= j < self.ny and 0 <= i < self.nx):
                            continue
                        if topo_data[j, i] < 0:
                            neighbors = ocean_neighbors_count(j, i)
                            dist = np.hypot(dx, dy)
                            depth_abs = -topo_data[j, i]
                            cand = (neighbors, -dist, depth_abs, j, i)
                            if (best is None) or (cand > best):
                                best = cand
                if best is not None and best[0] >= 5 and radius >= 3:
                    break

            if best is not None:
                lat_idx, lon_idx = best[3], best[4]
            # 调试打印：用于确认标注点是否在海洋
            is_ocean = topo_data[lat_idx, lon_idx] < 0
            print(f"  可视化-河口 '{river}': 网格({lat_idx},{lon_idx}), 深度={topo_data[lat_idx, lon_idx]:.1f}m, 海洋={is_ocean}")
            moved_lats.append(self.lat[lat_idx])
            moved_lons.append(self.lon[lon_idx])
        
        moved_lats = np.array(moved_lats)
        moved_lons = np.array(moved_lons)
        
        # 图1：浓度分布（陆地单独着色）
        fig1, ax1 = plt.subplots(1, 1, figsize=(20, 10))
        ocean_mask = topo_data < 0
        masked_surface = np.ma.masked_where(~ocean_mask, surface_field)
        cmap1 = plt.cm.get_cmap('viridis').copy()
        cmap1.set_bad(color='lightgray')  # 陆地为浅灰
        im1 = ax1.pcolormesh(lon_grid, lat_grid, masked_surface, cmap=cmap1, shading='auto')
        ax1.set_xlabel('经度', fontsize=14)
        ax1.set_ylabel('纬度', fontsize=14)
        ax1.set_title('全球海洋微塑料浓度分布 (kg/m³)', fontsize=16, fontweight='bold')
        ax1.set_xlim(0, 360)
        ax1.set_ylim(-80, 80)
        ax1.grid(True, alpha=0.3)
        cbar1 = plt.colorbar(im1, ax=ax1, orientation='horizontal', shrink=0.8, pad=0.1)
        cbar1.set_label('微塑料浓度 (kg/m³)', fontsize=12)
        plt.tight_layout()
        plt.savefig(f'{output_dir}/global_concentration.png', dpi=300, bbox_inches='tight')
        plt.show()

        # 图2：河口位置（仅标记河口，陆地单独着色）
        fig2, ax2 = plt.subplots(1, 1, figsize=(20, 10))
        # 使用二值掩膜上色：0(陆地)=浅灰，1(海洋)=白色
        from matplotlib.colors import ListedColormap
        mask_binary = (topo_data < 0).astype(float)
        land_ocean_cmap = ListedColormap(['lightgray', 'white'])
        ax2.pcolormesh(lon_grid, lat_grid, mask_binary, cmap=land_ocean_cmap, shading='auto')
        ax2.scatter(moved_lons, moved_lats, c='red', s=np.clip(concentrations/1000, 10, 200), alpha=0.7, edgecolors='white', linewidth=1)
        ax2.set_xlabel('经度', fontsize=14)
        ax2.set_ylabel('纬度', fontsize=14)
        ax2.set_title('河口位置与相对大小（按浓度缩放）', fontsize=16, fontweight='bold')
        ax2.set_xlim(0, 360)
        ax2.set_ylim(-80, 80)
        ax2.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(f'{output_dir}/river_locations.png', dpi=300, bbox_inches='tight')
        plt.show()
    
    def run_simulation(self):
        """运行完整的微塑料模拟"""
        print("=" * 60)
        print("微塑料全球海洋模拟")
        print("=" * 60)
        
        # 1. 加载地形并生成海洋掩膜
        print("\n1. 加载地形并生成海洋掩膜...")
        with open('input/ETOPO/topo.bin', 'rb') as f:
            topo_data = np.fromfile(f, dtype='>f4').reshape((self.ny, self.nx))
        ocean_mask = topo_data < 0

        # 2. 加载河口浓度数据
        print("\n2. 加载河口浓度数据...")
        rivers, lats, lons, concentrations = self.load_river_emissions()
        
        # 3. 初始化场(全0)，设置河口到最近海洋格点
        print("\n3. 初始化场并写入河口...")
        initial_field = np.zeros((self.nz, self.ny, self.nx))
        field_with_rivers, river_field_2d = self.add_river_emissions(initial_field, rivers, lats, lons, concentrations)

        # 4. 仅在海洋且为0的地方填充高斯背景
        print("\n4. 高斯填充海洋缺失区域...")
        final_field = self.fill_missing_with_gaussian(field_with_rivers, ocean_mask)

        # 5. 创建可视化（两张图）
        print("\n5. 创建可视化...")
        self.create_visualization(final_field, rivers, lats, lons, concentrations)
        
        # 6. 写入二进制文件
        print("\n6. 写入MITgcm输入文件...")
        self.write_binary_file(final_field, 'input/microplastic_initial.bin')
        # 生成 RBCS 目标与掩膜（表层河口处松弛，不影响深层）
        rbcs_target = np.zeros_like(final_field)
        rbcs_target[0, :, :] = river_field_2d
        rbcs_mask = np.zeros_like(final_field)
        rbcs_mask[0, :, :] = (river_field_2d > 0.0).astype(np.float32)
        self.write_binary_file(rbcs_target, 'input/microplastic_rbcs_target.bin')
        self.write_binary_file(rbcs_mask, 'input/microplastic_rbcs_mask.bin')
        
        print("\n" + "=" * 60)
        print("微塑料模拟完成!")
        print("=" * 60)
        
        return final_field

def main():
    """主函数"""
    sim = MicroplasticSimulation(nx=180, ny=80, nz=40)
    field_3d = sim.run_simulation()
    
    print(f"\n模拟完成! 生成的3D场形状: {field_3d.shape}")
    print(f"文件已保存到: input/microplastic_initial.bin")

if __name__ == "__main__":
    main()