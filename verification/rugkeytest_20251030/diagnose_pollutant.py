#!/usr/bin/env python3
"""
诊断 pollutant 包的源汇平衡
"""
import numpy as np
import xmitgcm
import matplotlib.pyplot as plt

# 加载数据
ds = xmitgcm.open_mdsdataset(
    data_dir='./input/output/', 
    grid_dir='./input', 
    prefix=['surf','state','pollutant_tendency','pollutant_state'], 
    delta_t=900
)

print("="*70)
print("POLLUTANT 诊断输出变量")
print("="*70)

# 检查变量是否存在
for var in ['POLLUT_S', 'POLLUT_K', 'POLLUT_T', 'POLLUT_M', 'POLLUT_F']:
    if var in ds:
        print(f"✓ {var} 存在")
    else:
        print(f"✗ {var} 不存在")

print("\n" + "="*70)
print("数值范围分析（最后时刻）")
print("="*70)

last_time = -1

if 'POLLUT_M' in ds:
    # POLLUT_M 是总质量 (mol)
    mass = ds.POLLUT_M.isel(time=last_time)
    print(f"\nPOLLUT_M (总质量, mol):")
    print(f"  范围: {mass.min().values:.3e} ~ {mass.max().values:.3e}")
    print(f"  平均: {mass.mean().values:.3e}")
    
    # 计算浓度 (mol/m³)
    # 需要除以网格体积
    # 体积 = rA * drF * hFacC
    # 但 xmitgcm 已经提供了网格信息
    
    if 'drF' in ds and 'rA' in ds and 'hFacC' in ds:
        # 计算实际浓度
        volume = ds.rA * ds.drF * ds.hFacC
        conc = mass / volume
        print(f"\n计算的浓度 (mol/m³):")
        print(f"  范围: {conc.min().values:.3e} ~ {conc.max().values:.3e}")
        print(f"  平均: {conc.mean().values:.3e}")
        
        # 与 TRAC01 对比
        if 'TRAC01' in ds:
            trac = ds.TRAC01.isel(time=last_time)
            print(f"\nTRAC01 (ptracer浓度, mol/m³):")
            print(f"  范围: {trac.min().values:.3e} ~ {trac.max().values:.3e}")
            print(f"  应该与计算的浓度一致！")

if 'POLLUT_S' in ds:
    source = ds.POLLUT_S.isel(time=last_time)
    print(f"\nPOLLUT_S (源项, mol/m³/s):")
    print(f"  范围: {source.min().values:.3e} ~ {source.max().values:.3e}")
    print(f"  平均: {source.mean().values:.3e}")

if 'POLLUT_K' in ds:
    sink = ds.POLLUT_K.isel(time=last_time)
    print(f"\nPOLLUT_K (汇项, mol/m³/s):")
    print(f"  范围: {sink.min().values:.3e} ~ {sink.max().values:.3e}")
    print(f"  平均: {sink.mean().values:.3e}")

if 'POLLUT_T' in ds:
    tend = ds.POLLUT_T.isel(time=last_time)
    print(f"\nPOLLUT_T (净趋势, mol/m³/s):")
    print(f"  范围: {tend.min().values:.3e} ~ {tend.max().values:.3e}")
    print(f"  平均: {tend.mean().values:.3e}")

if 'POLLUT_F' in ds:
    flux = ds.POLLUT_F.isel(time=last_time)
    print(f"\nPOLLUT_F (表面通量, mol/s):")
    print(f"  范围: {flux.min().values:.3e} ~ {flux.max().values:.3e}")
    print(f"  最大值位置: {np.unravel_index(flux.argmax().values, flux.shape)}")

print("\n" + "="*70)
print("源汇平衡分析")
print("="*70)

if 'POLLUT_S' in ds and 'POLLUT_K' in ds:
    source_total = ds.POLLUT_S.isel(time=last_time).sum().values
    sink_total = ds.POLLUT_K.isel(time=last_time).sum().values
    
    print(f"\n总源项: {source_total:.3e} mol/m³/s")
    print(f"总汇项: {sink_total:.3e} mol/m³/s")
    print(f"净平衡: {source_total - sink_total:.3e} mol/m³/s")
    print(f"源/汇比: {source_total/sink_total if sink_total > 0 else np.inf:.2f}")

print("\n" + "="*70)
print("温度场分析")
print("="*70)

if 'THETA' in ds:
    theta = ds.THETA.isel(time=last_time)
    print(f"\n温度范围: {theta.min().values:.2f} ~ {theta.max().values:.2f} °C")
    print(f"临界温度 Tc = 4.0 °C")
    
    # 计算温度小于4°C的比例
    below_tc = (theta < 4.0).sum().values / theta.size * 100
    print(f"温度 < 4°C 的网格占比: {below_tc:.1f}%")
    print(f"温度 >= 4°C 的网格占比: {100-below_tc:.1f}%")
    
    if below_tc > 50:
        print("\n⚠️  警告：超过50%的网格温度低于临界温度！")
        print("   降解过程可能被大面积抑制！")

print("\n" + "="*70)
print("时间演化分析")
print("="*70)

if 'POLLUT_M' in ds:
    # 全球总质量随时间变化
    global_mass = ds.POLLUT_M.sum(dim=['XC', 'YC', 'Z']).values
    times = np.arange(len(global_mass)) * 900 / 86400  # 转换为天
    
    print(f"\n全球总质量演化:")
    print(f"  初始: {global_mass[0]:.3e} mol")
    print(f"  最终: {global_mass[-1]:.3e} mol")
    print(f"  增长: {(global_mass[-1]/global_mass[0] if global_mass[0] > 0 else np.inf):.2e} 倍")
    
    # 绘图
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(times, global_mass, 'b-', linewidth=2)
    ax.set_xlabel('Time (days)', fontsize=12)
    ax.set_ylabel('Global Total Mass (mol)', fontsize=12)
    ax.set_title('Pollutant Global Mass Evolution', fontsize=14)
    ax.grid(True, alpha=0.3)
    ax.set_yscale('log')
    plt.tight_layout()
    plt.savefig('global_mass_evolution.png', dpi=300, bbox_inches='tight')
    print(f"\n✓ 保存图表: global_mass_evolution.png")

print("\n" + "="*70)
print("诊断完成")
print("="*70)
