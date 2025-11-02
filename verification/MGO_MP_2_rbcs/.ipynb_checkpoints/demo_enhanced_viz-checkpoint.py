#!/usr/bin/env python3
"""
MITgcm微塑料模拟增强可视化演示脚本
展示增强版postprocess_analysis.py的主要功能
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import seaborn as sns
import os

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'

def create_demo_data():
    """创建演示数据"""
    print("创建演示数据...")
    
    # 网格设置
    nx, ny = 180, 80
    lon = np.linspace(0, 360, nx, endpoint=False)
    lat = np.linspace(-80, 80, ny)
    lon_grid, lat_grid = np.meshgrid(lon, lat)
    
    # 创建海洋掩膜（简化版）
    ocean_mask = np.ones((ny, nx), dtype=bool)
    # 模拟一些陆地区域
    for i in range(0, nx, 40):
        for j in range(0, ny, 30):
            if i < nx and j < ny:
                ocean_mask[j:j+8, i:i+8] = False
    
    # 创建初始微塑料浓度场
    initial_field = np.zeros((ny, nx))
    
    # 模拟河口排放
    river_positions = [
        (30, 120, 5000),   # 长江
        (20, 90, 3000),    # 恒河
        (-10, -50, 2000),  # 亚马逊
        (40, 280, 4000),   # 密西西比
        (-20, 150, 1500),  # 墨累河
    ]
    
    for lat_river, lon_river, conc in river_positions:
        lat_idx = int(np.argmin(np.abs(lat - lat_river)))
        lon_idx = int(np.argmin(np.abs(lon - lon_river)))
        
        # 高斯扩散
        for dy in range(-8, 9):
            for dx in range(-8, 9):
                j = lat_idx + dy
                i = lon_idx + dx
                if 0 <= j < ny and 0 <= i < nx and ocean_mask[j, i]:
                    r = np.hypot(dx, dy)
                    if r <= 8:
                        weight = np.exp(-0.5 * (r / 3.0) ** 2)
                        initial_field[j, i] += conc * weight
    
    # 添加背景噪声
    noise = np.random.normal(0, 200, (ny, nx))
    initial_field += np.maximum(noise, 0)
    initial_field = np.maximum(initial_field, 0)
    
    # 创建最终场（模拟传输后的状态）
    final_field = initial_field.copy()
    
    # 模拟一些传输和扩散
    from scipy import ndimage
    final_field = ndimage.gaussian_filter(final_field, sigma=2.0)
    
    # 添加一些新的热点
    new_hotspots = [(60, 200, 2000), (10, 300, 1500)]
    for lat_hs, lon_hs, conc in new_hotspots:
        lat_idx = int(np.argmin(np.abs(lat - lat_hs)))
        lon_idx = int(np.argmin(np.abs(lon - lon_hs)))
        
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                j = lat_idx + dy
                i = lon_idx + dx
                if 0 <= j < ny and 0 <= i < nx and ocean_mask[j, i]:
                    r = np.hypot(dx, dy)
                    if r <= 5:
                        weight = np.exp(-0.5 * (r / 2.0) ** 2)
                        final_field[j, i] += conc * weight
    
    return initial_field, final_field, ocean_mask, lon_grid, lat_grid, lon, lat

def demo_enhanced_colormap():
    """演示增强的色彩映射"""
    print("演示增强的色彩映射...")
    
    initial_field, final_field, ocean_mask, lon_grid, lat_grid, lon, lat = create_demo_data()
    
    # 创建自定义色彩映射
    colors = ['#000080', '#0000FF', '#00FFFF', '#00FF00', '#FFFF00', '#FF8000', '#FF0000', '#800000']
    cmap = mcolors.LinearSegmentedColormap.from_list('enhanced', colors, N=256)
    
    fig, axes = plt.subplots(1, 2, figsize=(20, 8))
    fig.suptitle('增强色彩映射对比演示', fontsize=18, fontweight='bold', y=0.95)
    
    # 原始viridis色彩映射
    ax1 = axes[0]
    masked_initial = np.ma.masked_where(~ocean_mask, initial_field)
    im1 = ax1.pcolormesh(lon_grid, lat_grid, masked_initial, 
                        cmap='viridis', shading='auto', vmin=0.0)
    ax1.set_title('原始viridis色彩映射', fontsize=14, fontweight='bold')
    ax1.set_xlim(0, 360)
    ax1.set_ylim(-80, 80)
    ax1.grid(True, alpha=0.3)
    
    # 增强色彩映射
    ax2 = axes[1]
    im2 = ax2.pcolormesh(lon_grid, lat_grid, masked_initial, 
                        cmap=cmap, shading='auto', vmin=0.0)
    
    # 添加等值线
    if np.any(masked_initial > 0):
        levels = np.linspace(0, np.max(masked_initial), 8)
        contour = ax2.contour(lon_grid, lat_grid, masked_initial, 
                            levels=levels, colors='white', alpha=0.7, linewidths=1.0)
        ax2.clabel(contour, inline=True, fontsize=8, fmt='%.0f')
    
    # 添加海岸线
    ax2.contour(lon_grid, lat_grid, ocean_mask.astype(float), 
               levels=[0.5], colors='black', linewidths=2, alpha=0.9)
    
    ax2.set_title('增强色彩映射 + 等值线 + 海岸线', fontsize=14, fontweight='bold')
    ax2.set_xlim(0, 360)
    ax2.set_ylim(-80, 80)
    ax2.grid(True, alpha=0.3)
    
    # 添加统计信息
    ocean_data = initial_field[ocean_mask]
    valid_data = ocean_data[ocean_data > 0]
    if len(valid_data) > 0:
        stats_text = f'最大值: {valid_data.max():.0f}\n平均值: {valid_data.mean():.0f}\n非零点: {len(valid_data)}'
        ax2.text(0.02, 0.98, stats_text, transform=ax2.transAxes, 
                verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                fontsize=10)
    
    # 添加颜色条
    cbar1 = plt.colorbar(im1, ax=ax1, orientation='horizontal', shrink=0.8, pad=0.1)
    cbar1.set_label('浓度 (kg/m³)', fontsize=12)
    
    cbar2 = plt.colorbar(im2, ax=ax2, orientation='horizontal', shrink=0.8, pad=0.1)
    cbar2.set_label('浓度 (kg/m³)', fontsize=12)
    
    plt.tight_layout()
    plt.subplots_adjust(top=0.9)
    plt.savefig('demo_enhanced_colormap.png', dpi=300, bbox_inches='tight', facecolor='white')
    plt.show()

def demo_comparison_analysis():
    """演示对比分析功能"""
    print("演示对比分析功能...")
    
    initial_field, final_field, ocean_mask, lon_grid, lat_grid, lon, lat = create_demo_data()
    
    # 计算差异
    diff_field = final_field - initial_field
    rel_diff_field = np.where(initial_field > 0, diff_field / initial_field * 100, 0)
    
    fig, axes = plt.subplots(2, 2, figsize=(20, 16))
    fig.suptitle('对比分析功能演示', fontsize=18, fontweight='bold', y=0.95)
    
    # 1. 初始状态
    ax1 = axes[0, 0]
    masked_initial = np.ma.masked_where(~ocean_mask, initial_field)
    colors = ['#000080', '#0000FF', '#00FFFF', '#00FF00', '#FFFF00', '#FF8000', '#FF0000', '#800000']
    cmap = mcolors.LinearSegmentedColormap.from_list('enhanced', colors, N=256)
    
    vmax = max(np.percentile(initial_field[ocean_mask], 95), 
              np.percentile(final_field[ocean_mask], 95))
    
    im1 = ax1.pcolormesh(lon_grid, lat_grid, masked_initial, 
                        cmap=cmap, shading='auto', vmin=0.0, vmax=vmax)
    ax1.contour(lon_grid, lat_grid, ocean_mask.astype(float), 
               levels=[0.5], colors='black', linewidths=1.5, alpha=0.8)
    ax1.set_title('初始状态', fontsize=14, fontweight='bold')
    ax1.set_xlim(0, 360)
    ax1.set_ylim(-80, 80)
    ax1.grid(True, alpha=0.3)
    
    # 2. 最终状态
    ax2 = axes[0, 1]
    masked_final = np.ma.masked_where(~ocean_mask, final_field)
    im2 = ax2.pcolormesh(lon_grid, lat_grid, masked_final, 
                        cmap=cmap, shading='auto', vmin=0.0, vmax=vmax)
    ax2.contour(lon_grid, lat_grid, ocean_mask.astype(float), 
               levels=[0.5], colors='black', linewidths=1.5, alpha=0.8)
    ax2.set_title('最终状态', fontsize=14, fontweight='bold')
    ax2.set_xlim(0, 360)
    ax2.set_ylim(-80, 80)
    ax2.grid(True, alpha=0.3)
    
    # 3. 绝对差异
    ax3 = axes[1, 0]
    masked_diff = np.ma.masked_where(~ocean_mask, diff_field)
    diff_max = np.percentile(np.abs(diff_field[ocean_mask]), 95)
    im3 = ax3.pcolormesh(lon_grid, lat_grid, masked_diff, 
                        cmap='RdBu_r', shading='auto', vmin=-diff_max, vmax=diff_max)
    ax3.contour(lon_grid, lat_grid, ocean_mask.astype(float), 
               levels=[0.5], colors='black', linewidths=1.5, alpha=0.8)
    ax3.set_title('绝对差异 (最终-初始)', fontsize=14, fontweight='bold')
    ax3.set_xlim(0, 360)
    ax3.set_ylim(-80, 80)
    ax3.grid(True, alpha=0.3)
    
    # 4. 统计对比
    ax4 = axes[1, 1]
    categories = ['总质量', '平均浓度', '最大浓度', '标准差']
    initial_stats = [
        np.sum(initial_field[ocean_mask]),
        np.mean(initial_field[ocean_mask]),
        np.max(initial_field[ocean_mask]),
        np.std(initial_field[ocean_mask])
    ]
    final_stats = [
        np.sum(final_field[ocean_mask]),
        np.mean(final_field[ocean_mask]),
        np.max(final_field[ocean_mask]),
        np.std(final_field[ocean_mask])
    ]
    
    x = np.arange(len(categories))
    width = 0.35
    
    bars1 = ax4.bar(x - width/2, initial_stats, width, label='初始', 
                   color='lightblue', alpha=0.8)
    bars2 = ax4.bar(x + width/2, final_stats, width, label='最终', 
                   color='lightcoral', alpha=0.8)
    
    ax4.set_xlabel('统计指标', fontsize=12)
    ax4.set_ylabel('数值', fontsize=12)
    ax4.set_title('统计指标对比', fontsize=14, fontweight='bold')
    ax4.set_xticks(x)
    ax4.set_xticklabels(categories, rotation=45)
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # 添加数值标签
    for bars in [bars1, bars2]:
        for bar in bars:
            height = bar.get_height()
            ax4.text(bar.get_x() + bar.get_width()/2., height + height*0.01,
                    f'{height:.0f}', ha='center', va='bottom', fontsize=8)
    
    # 添加颜色条
    cbar1 = plt.colorbar(im1, ax=axes[0, 0], orientation='horizontal', shrink=0.8, pad=0.1)
    cbar1.set_label('浓度 (kg/m³)', fontsize=10)
    
    cbar2 = plt.colorbar(im2, ax=axes[0, 1], orientation='horizontal', shrink=0.8, pad=0.1)
    cbar2.set_label('浓度 (kg/m³)', fontsize=10)
    
    cbar3 = plt.colorbar(im3, ax=axes[1, 0], orientation='horizontal', shrink=0.8, pad=0.1)
    cbar3.set_label('差异 (kg/m³)', fontsize=10)
    
    plt.tight_layout()
    plt.subplots_adjust(top=0.92)
    plt.savefig('demo_comparison_analysis.png', dpi=300, bbox_inches='tight', facecolor='white')
    plt.show()

def demo_statistical_plots():
    """演示统计图表功能"""
    print("演示统计图表功能...")
    
    initial_field, final_field, ocean_mask, lon_grid, lat_grid, lon, lat = create_demo_data()
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('统计图表功能演示', fontsize=18, fontweight='bold', y=0.95)
    
    # 1. 区域统计对比
    ax1 = axes[0, 0]
    regions = ['北太平洋', '南太平洋', '北大西洋', '南大西洋', '印度洋', '北冰洋']
    region_means = [
        np.mean(initial_field[(lat >= 20) & (lat <= 60), :]),
        np.mean(initial_field[(lat >= -60) & (lat <= -20), :]),
        np.mean(initial_field[(lat >= 20) & (lat <= 60), :]),
        np.mean(initial_field[(lat >= -60) & (lat <= -20), :]),
        np.mean(initial_field[(lat >= -20) & (lat <= 20), :]),
        np.mean(initial_field[lat >= 60, :])
    ]
    
    bars = ax1.bar(regions, region_means, color=['#FF6B6B', '#4ECDC4', '#45B7D1', 
                                                '#96CEB4', '#FFEAA7', '#DDA0DD'])
    ax1.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
    ax1.set_title('各区域平均浓度对比', fontsize=14, fontweight='bold')
    ax1.tick_params(axis='x', rotation=45)
    ax1.grid(True, alpha=0.3)
    
    # 添加数值标签
    for bar, value in zip(bars, region_means):
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height + height*0.01,
                f'{value:.0f}', ha='center', va='bottom', fontsize=9)
    
    # 2. 浓度分布直方图
    ax2 = axes[0, 1]
    valid_concentrations = initial_field[initial_field > 0]
    
    sns.histplot(valid_concentrations, bins=30, kde=True, alpha=0.7, 
                color='skyblue', edgecolor='black', ax=ax2)
    ax2.set_xlabel('浓度 (kg/m³)', fontsize=12)
    ax2.set_ylabel('网格点数量', fontsize=12)
    ax2.set_title('浓度分布直方图', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # 添加统计信息
    mean_conc = np.mean(valid_concentrations)
    ax2.axvline(mean_conc, color='red', linestyle='--', linewidth=2, 
               label=f'平均值: {mean_conc:.0f}')
    ax2.legend()
    
    # 3. 纬度分布
    ax3 = axes[1, 0]
    lat_means = np.mean(initial_field, axis=1)
    
    ax3.plot(lat, lat_means, 'o-', linewidth=3, markersize=6, 
            color='green', markerfacecolor='lightgreen', markeredgecolor='darkgreen')
    ax3.fill_between(lat, lat_means, alpha=0.3, color='green')
    ax3.set_xlabel('纬度 (°N)', fontsize=12)
    ax3.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
    ax3.set_title('浓度随纬度变化', fontsize=14, fontweight='bold')
    ax3.grid(True, alpha=0.3)
    
    # 4. 经度分布
    ax4 = axes[1, 1]
    lon_means = np.mean(initial_field, axis=0)
    
    ax4.plot(lon, lon_means, 'o-', linewidth=3, markersize=6, 
            color='purple', markerfacecolor='plum', markeredgecolor='indigo')
    ax4.fill_between(lon, lon_means, alpha=0.3, color='purple')
    ax4.set_xlabel('经度 (°E)', fontsize=12)
    ax4.set_ylabel('平均浓度 (kg/m³)', fontsize=12)
    ax4.set_title('浓度随经度变化', fontsize=14, fontweight='bold')
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.subplots_adjust(top=0.92)
    plt.savefig('demo_statistical_plots.png', dpi=300, bbox_inches='tight', facecolor='white')
    plt.show()

def main():
    """主演示函数"""
    print("=" * 60)
    print("MITgcm微塑料模拟增强可视化功能演示")
    print("=" * 60)
    
    # 创建演示结果目录
    os.makedirs('demo_results', exist_ok=True)
    os.chdir('demo_results')
    
    # 运行各个演示
    demo_enhanced_colormap()
    demo_comparison_analysis()
    demo_statistical_plots()
    
    print("\n" + "=" * 60)
    print("演示完成！")
    print("生成的演示图片保存在 demo_results/ 目录中")
    print("=" * 60)

if __name__ == "__main__":
    main()
