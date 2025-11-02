#!/usr/bin/env python3
"""
MITgcm微塑料模拟结果后处理和可视化分析
"""

import numpy as np
import matplotlib.pyplot as plt
import os
import glob
from datetime import datetime, timedelta
import struct

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False

class MITgcmPostProcessor:
    def __init__(self, output_dir='input/output', nx=40, ny=80, nz=15):
        """初始化后处理器"""
        self.output_dir = output_dir
        self.nx = nx
        self.ny = ny
        self.nz = nz
        
        # 创建坐标网格
        self.lon = np.linspace(0, 360, nx, endpoint=False)
        self.lat = np.linspace(-80, 80, ny)
        self.depths = np.linspace(0, 5000, nz)
        
        print(f"后处理器初始化完成")
        print(f"网格设置: {nx} x {ny} x {nz}")
        print(f"经度范围: {self.lon[0]}° - {self.lon[-1]}°")
        print(f"纬度范围: {self.lat[0]}° - {self.lat[-1]}°")
    
    def read_binary_file(self, filename):
        """读取MITgcm二进制文件"""
        try:
            with open(filename, 'rb') as f:
                data = f.read()
            
            # 读取数据 (假设是float32格式)
            values = struct.unpack('>' + 'f' * (len(data) // 4), data)
            field_3d = np.array(values).reshape((self.nz, self.ny, self.nx))
            
            return field_3d
        except Exception as e:
            print(f"读取文件 {filename} 时出错: {e}")
            return None
    
    def get_time_steps(self):
        """获取所有时间步"""
        microplastic_files = glob.glob(os.path.join(self.output_dir, 'microplastics.*.data'))
        time_steps = []
        
        for file in microplastic_files:
            # 从文件名提取时间步
            basename = os.path.basename(file)
            time_str = basename.split('.')[1]
            time_step = int(time_str)
            time_steps.append(time_step)
        
        time_steps.sort()
        return time_steps
    
    def load_time_series(self):
        """加载时间序列数据"""
        print("加载时间序列数据...")
        
        time_steps = self.get_time_steps()
        print(f"找到 {len(time_steps)} 个时间步: {time_steps}")
        
        # 存储时间序列数据
        time_series = {}
        
        for time_step in time_steps:
            filename = os.path.join(self.output_dir, f'microplastics.{time_step:010d}.data')
            field_3d = self.read_binary_file(filename)
            
            if field_3d is not None:
                time_series[time_step] = field_3d
                print(f"  时间步 {time_step}: 加载成功")
            else:
                print(f"  时间步 {time_step}: 加载失败")
        
        return time_series
    
    def calculate_statistics(self, field_3d):
        """计算统计信息"""
        surface_field = field_3d[0, :, :]
        
        stats = {
            'total_mass': np.sum(field_3d),
            'surface_mean': np.mean(surface_field),
            'surface_max': np.max(surface_field),
            'surface_min': np.min(surface_field),
            'surface_std': np.std(surface_field),
            'non_zero_points': np.count_nonzero(surface_field),
            'total_points': surface_field.size,
            'non_zero_ratio': np.count_nonzero(surface_field) / surface_field.size
        }
        
        return stats
    
    def create_time_series_plots(self, time_series, output_dir='results'):
        """创建时间序列分析图"""
        print("创建时间序列分析图...")
        
        os.makedirs(output_dir, exist_ok=True)
        
        time_steps = sorted(time_series.keys())
        time_hours = [t * 0.5 for t in time_steps]  # 假设每时间步0.5小时
        
        # 计算时间序列统计
        total_mass = []
        surface_mean = []
        surface_max = []
        non_zero_ratio = []
        
        for time_step in time_steps:
            stats = self.calculate_statistics(time_series[time_step])
            total_mass.append(stats['total_mass'])
            surface_mean.append(stats['surface_mean'])
            surface_max.append(stats['surface_max'])
            non_zero_ratio.append(stats['non_zero_ratio'])
        
        # 创建时间序列图
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # 1. 总质量变化
        ax1.plot(time_hours, total_mass, 'b-o', linewidth=2, markersize=6)
        ax1.set_xlabel('时间 (小时)', fontsize=12)
        ax1.set_ylabel('总质量 (kg)', fontsize=12)
        ax1.set_title('微塑料总质量随时间变化', fontsize=14, fontweight='bold')
        ax1.grid(True, alpha=0.3)
        
        # 2. 表层平均浓度变化
        ax2.plot(time_hours, surface_mean, 'g-o', linewidth=2, markersize=6)
        ax2.set_xlabel('时间 (小时)', fontsize=12)
        ax2.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
        ax2.set_title('表层平均浓度随时间变化', fontsize=14, fontweight='bold')
        ax2.grid(True, alpha=0.3)
        
        # 3. 表层最大浓度变化
        ax3.plot(time_hours, surface_max, 'r-o', linewidth=2, markersize=6)
        ax3.set_xlabel('时间 (小时)', fontsize=12)
        ax3.set_ylabel('最大浓度 (kg/m³)', fontsize=12)
        ax3.set_title('表层最大浓度随时间变化', fontsize=14, fontweight='bold')
        ax3.grid(True, alpha=0.3)
        
        # 4. 非零网格点比例变化
        ax4.plot(time_hours, np.array(non_zero_ratio) * 100, 'm-o', linewidth=2, markersize=6)
        ax4.set_xlabel('时间 (小时)', fontsize=12)
        ax4.set_ylabel('非零网格点比例 (%)', fontsize=12)
        ax4.set_title('非零网格点比例随时间变化', fontsize=14, fontweight='bold')
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/time_series_analysis.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print(f"时间序列分析图已保存到: {output_dir}/time_series_analysis.png")
    
    def create_spatial_evolution(self, time_series, output_dir='results'):
        """创建空间演化图"""
        print("创建空间演化图...")
        
        os.makedirs(output_dir, exist_ok=True)
        
        time_steps = sorted(time_series.keys())
        lon_grid, lat_grid = np.meshgrid(self.lon, self.lat)
        
        # 选择几个关键时间步
        key_times = [time_steps[0], time_steps[len(time_steps)//2], time_steps[-1]]
        
        fig, axes = plt.subplots(1, 3, figsize=(24, 8))
        
        for i, time_step in enumerate(key_times):
            surface_field = time_series[time_step][0, :, :]
            
            im = axes[i].pcolormesh(lon_grid, lat_grid, surface_field, 
                                  cmap='viridis', shading='auto')
            
            axes[i].set_xlabel('经度', fontsize=12)
            axes[i].set_ylabel('纬度', fontsize=12)
            axes[i].set_title(f'时间步 {time_step} (t={time_step*0.5:.1f}h)', 
                            fontsize=14, fontweight='bold')
            axes[i].set_xlim(0, 360)
            axes[i].set_ylim(-80, 80)
            axes[i].grid(True, alpha=0.3)
            
            # 添加颜色条
            cbar = plt.colorbar(im, ax=axes[i], orientation='horizontal', 
                              shrink=0.8, pad=0.1)
            cbar.set_label('浓度 (kg/m³)', fontsize=10)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/spatial_evolution.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print(f"空间演化图已保存到: {output_dir}/spatial_evolution.png")
    
    def create_final_state_analysis(self, time_series, output_dir='results'):
        """创建最终状态详细分析"""
        print("创建最终状态分析...")
        
        os.makedirs(output_dir, exist_ok=True)
        
        # 获取最终时间步
        final_time = max(time_series.keys())
        final_field = time_series[final_time]
        surface_field = final_field[0, :, :]
        
        lon_grid, lat_grid = np.meshgrid(self.lon, self.lat)
        
        # 创建综合分析图
        fig = plt.figure(figsize=(20, 16))
        
        # 1. 表层浓度分布
        ax1 = plt.subplot(2, 3, (1, 2))
        im1 = ax1.pcolormesh(lon_grid, lat_grid, surface_field, 
                           cmap='viridis', shading='auto')
        ax1.set_xlabel('经度', fontsize=12)
        ax1.set_ylabel('纬度', fontsize=12)
        ax1.set_title(f'最终状态表层浓度分布 (t={final_time*0.5:.1f}h)', 
                     fontsize=14, fontweight='bold')
        ax1.set_xlim(0, 360)
        ax1.set_ylim(-80, 80)
        ax1.grid(True, alpha=0.3)
        
        cbar1 = plt.colorbar(im1, ax=ax1, orientation='horizontal', 
                           shrink=0.8, pad=0.1)
        cbar1.set_label('浓度 (kg/m³)', fontsize=12)
        
        # 2. 垂向剖面 (经向平均)
        ax2 = plt.subplot(2, 3, 3)
        zonal_mean = np.mean(final_field, axis=2)
        depth_grid, lat_grid_profile = np.meshgrid(self.depths, self.lat)
        
        im2 = ax2.pcolormesh(lat_grid_profile, depth_grid, zonal_mean, 
                           cmap='plasma', shading='auto')
        ax2.set_xlabel('纬度', fontsize=12)
        ax2.set_ylabel('深度 (m)', fontsize=12)
        ax2.set_title('经向平均垂向剖面', fontsize=14, fontweight='bold')
        ax2.set_ylim(5000, 0)  # 反转深度轴
        ax2.grid(True, alpha=0.3)
        
        cbar2 = plt.colorbar(im2, ax=ax2, orientation='vertical', 
                           shrink=0.8, pad=0.1)
        cbar2.set_label('浓度 (kg/m³)', fontsize=12)
        
        # 3. 浓度分布直方图
        ax3 = plt.subplot(2, 3, 4)
        valid_concentrations = surface_field[surface_field > 0]
        ax3.hist(valid_concentrations, bins=50, alpha=0.7, color='skyblue', 
                edgecolor='black')
        ax3.set_xlabel('浓度 (kg/m³)', fontsize=12)
        ax3.set_ylabel('网格点数量', fontsize=12)
        ax3.set_title('浓度分布直方图', fontsize=14, fontweight='bold')
        ax3.grid(True, alpha=0.3)
        
        # 4. 纬度分布
        ax4 = plt.subplot(2, 3, 5)
        lat_means = np.mean(surface_field, axis=1)
        ax4.plot(self.lat, lat_means, 'o-', linewidth=2, markersize=4, color='green')
        ax4.set_xlabel('纬度', fontsize=12)
        ax4.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
        ax4.set_title('浓度随纬度变化', fontsize=14, fontweight='bold')
        ax4.grid(True, alpha=0.3)
        
        # 5. 经度分布
        ax5 = plt.subplot(2, 3, 6)
        lon_means = np.mean(surface_field, axis=0)
        ax5.plot(self.lon, lon_means, 'o-', linewidth=2, markersize=4, color='purple')
        ax5.set_xlabel('经度', fontsize=12)
        ax5.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
        ax5.set_title('浓度随经度变化', fontsize=14, fontweight='bold')
        ax5.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/final_state_analysis.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print(f"最终状态分析图已保存到: {output_dir}/final_state_analysis.png")
        
        # 打印详细统计信息
        stats = self.calculate_statistics(final_field)
        print(f"\n=== 最终状态统计信息 ===")
        print(f"时间步: {final_time} (t={final_time*0.5:.1f}h)")
        print(f"总质量: {stats['total_mass']:.2e} kg")
        print(f"表层平均浓度: {stats['surface_mean']:.2f} kg/m³")
        print(f"表层最大浓度: {stats['surface_max']:.2f} kg/m³")
        print(f"表层最小浓度: {stats['surface_min']:.2f} kg/m³")
        print(f"表层标准差: {stats['surface_std']:.2f} kg/m³")
        print(f"非零网格点: {stats['non_zero_points']} / {stats['total_points']}")
        print(f"非零比例: {stats['non_zero_ratio']*100:.1f}%")
    
    def run_analysis(self):
        """运行完整的后处理分析"""
        print("=" * 60)
        print("MITgcm微塑料模拟结果后处理分析")
        print("=" * 60)
        
        # 1. 加载时间序列数据
        time_series = self.load_time_series()
        
        if not time_series:
            print("错误: 没有找到有效的时间序列数据")
            return
        
        # 2. 创建时间序列分析
        self.create_time_series_plots(time_series)
        
        # 3. 创建空间演化分析
        self.create_spatial_evolution(time_series)
        
        # 4. 创建最终状态分析
        self.create_final_state_analysis(time_series)
        
        print("\n" + "=" * 60)
        print("后处理分析完成！")
        print("=" * 60)

def main():
    """主函数"""
    # 创建后处理器
    processor = MITgcmPostProcessor()
    
    # 运行分析
    processor.run_analysis()

if __name__ == "__main__":
    main()
