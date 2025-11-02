import xmitgcm
import numpy as np
import matplotlib.pyplot as plt
import xarray as xr
import cartopy.crs as ccrs
import cartopy.feature as cfeature

# === 加载MITgcm数据集 ===
ds = xmitgcm.open_mdsdataset(
    data_dir='./input/output/',
    grid_dir='./input/',
    prefix=['surf', 'state', 'microplastics'],
    delta_t=900
)

# === 字体设置 ===
plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False

# === 时间步与模型设置 ===
time_steps = [1, 50, 100, 150, 200, 239]  # 要绘制的时间步
dt = 1800  # 每步 1800 秒
seconds_per_day = 86400

# === 计算全局最大浓度 ===
max_conc = 0
for t_idx in time_steps:
    if t_idx <= len(ds.time):
        mp_data = ds.TRAC01.isel(time=t_idx - 1, Z=0)
        max_conc = max(max_conc, float(mp_data.max().compute()))

# === 地形掩膜 ===
land_mask = ds.hFacC.isel(Z=0)
land_mask = xr.where(land_mask > 0, np.nan, 1)

# === 创建图像与布局 ===
fig, axes = plt.subplots(
    2, 3,
    figsize=(18, 7),  # 调整比例更紧凑
    subplot_kw={'projection': ccrs.PlateCarree()}
)
axes = axes.flatten()

# === 绘制各时间步 ===
for i, t_idx in enumerate(time_steps):
    ax = axes[i]
    ax.set_global()
    ax.coastlines(linewidth=0.5, color='black')
    ax.add_feature(cfeature.LAND, facecolor='lightgray', zorder=1)
    ax.add_feature(cfeature.BORDERS, linewidth=0.2)

    if t_idx <= len(ds.time):
        mp_data = ds.TRAC01.isel(time=t_idx - 1, Z=0)
        im = mp_data.where(mp_data > 0).plot(
            ax=ax,
            transform=ccrs.PlateCarree(),
            cmap='viridis',
            add_colorbar=False,
            vmin=0,
            vmax=max_conc,
            zorder=2
        )

        # 计算物理时间（以天为单位）
        time_days = (t_idx - 1) * dt / seconds_per_day
        ax.set_title(f'时间步 {t_idx} (t={time_days:.2f} 天)', fontsize=12)
        ax.tick_params(labelsize=9)

# === 色条 ===
cbar_ax = fig.add_axes([0.25, 0.08, 0.5, 0.025])  # 贴近下方
cbar = fig.colorbar(im, cax=cbar_ax, orientation='horizontal')
cbar.set_label('微塑料浓度', fontsize=12)
cbar.ax.tick_params(labelsize=10)

# === 总标题与布局 ===
fig.suptitle('微塑料在河口扩散的时间序列', fontsize=18, y=0.96)
plt.subplots_adjust(left=0.05, right=0.95, top=0.90, bottom=0.15,
                    wspace=0.05, hspace=0.1)

# === 保存高分辨率图像 ===
plt.savefig('microplastic_diffusion_timeseries_compact.png',
            dpi=600, bbox_inches='tight')
plt.show()
