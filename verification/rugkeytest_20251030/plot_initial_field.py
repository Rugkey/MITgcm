import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
from matplotlib.colors import LogNorm
import os

def plot_initial_field():
    """
    Reads the generated pollutant initial field and topography, and creates
    a global map of the surface concentration using a simple, robust logic.
    """
    # --- 1. Define Model Grid ---
    nx = 180
    ny = 80
    nz = 40
    reso = 2.0
    
    lon = np.arange(0.0 + reso / 2.0, 360.0, reso)
    lat = np.arange(-80.0 + reso / 2.0, 80.0, reso)
    
    # --- 2. Read Binary Data ---
    initial_field_path = 'pollutant_initial.bin'
    topo_path = 'input/ETOPO/topo.bin'
    
    if not os.path.exists(initial_field_path) or not os.path.exists(topo_path):
        print(f"Error: Missing data file. Ensure '{initial_field_path}' and '{topo_path}' exist.")
        return

    try:
        initial_data = np.fromfile(initial_field_path, dtype='>f4').reshape(nz, ny, nx)
        surface_conc = initial_data[0, :, :]
        topo = np.fromfile(topo_path, dtype='>f4').reshape(ny, nx)
    except Exception as e:
        print(f"Error reading or reshaping data: {e}")
        return

    # --- 3. Prepare Data for Plotting ---
    # Create a masked array to hide land (topo >= 0) and zero/negative values
    # Use a small epsilon for log scale compatibility
    plot_data = np.ma.masked_where((topo >= 0) | (surface_conc <= 1e-12), surface_conc)

    # --- 4. Create the Plot ---
    print("Generating plot with PlateCarree projection and LogNorm...")
    fig, ax = plt.subplots(figsize=(12, 6), subplot_kw={'projection': ccrs.PlateCarree()})
    
    # Determine min/max for the color scale from the valid data range
    vmin = np.ma.min(plot_data)
    vmax = np.ma.max(plot_data)

    if vmin is np.ma.masked or vmax is np.ma.masked:
        print("Warning: No valid data to plot after masking.")
        vmin, vmax = 1e-9, 1e-6 # Fallback values
    
    pcm = ax.pcolormesh(lon, lat, plot_data, 
                        transform=ccrs.PlateCarree(),
                        norm=LogNorm(vmin=vmin, vmax=vmax),
                        cmap='viridis')

    ax.coastlines()
    ax.gridlines(draw_labels=True, linestyle='--', color='gray', alpha=0.5)
    
    cbar = fig.colorbar(pcm, ax=ax, orientation='vertical', shrink=0.8, pad=0.05)
    cbar.set_label('Pollutant Concentration (mol/m³)')
    
    plt.title('Initial Surface Pollutant Concentration')
    
    # --- 5. Save the Figure ---
    output_image_path = 'initial_concentration_map.png'
    try:
        plt.savefig(output_image_path, dpi=300, bbox_inches='tight')
        print(f"Successfully saved map to {output_image_path}")
    except Exception as e:
        print(f"Error saving plot: {e}")

if __name__ == '__main__':
    plot_initial_field()
