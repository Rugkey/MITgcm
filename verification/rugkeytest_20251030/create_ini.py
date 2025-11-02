import numpy as np
import pandas as pd
import os

def create_initial_field():
    """
    Reads pollutant concentration data, maps it to a grid using max value,
    sets a minimum background concentration for other ocean cells, and saves
    the result as a binary file.
    """
    # --- 1. Define Model Grid ---
    nx = 180
    ny = 80
    nz = 40
    topo_path = 'input/ETOPO/topo.bin'
    csv_path = 'MP_ini.csv'
    background_conc = 1e-6
    
    # --- 2. Read and Process CSV Data ---
    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found.")
        return

    try:
        df = pd.read_csv(csv_path, header=None, usecols=[1, 2, 3])
        df.columns = ['lon', 'lat', 'log10_conc']
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return

    df['lon'] = pd.to_numeric(df['lon'], errors='coerce')
    df['lat'] = pd.to_numeric(df['lat'], errors='coerce')
    df['log10_conc'] = pd.to_numeric(df['log10_conc'], errors='coerce')
    df.dropna(subset=['lon', 'lat', 'log10_conc'], inplace=True)

    df['conc'] = 10**df['log10_conc']

    # --- 3. Create and Map Data to 3D Grid ---
    initial_field = np.zeros((nz, ny, nx), dtype='>f4')
    
    print(f"Mapping {len(df)} data points to the grid using max value logic...")
    for _, row in df.iterrows():
        lon, lat, conc = row['lon'], row['lat'], row['conc']
        if lon < 0: lon += 360
        i = int(lon * nx / 360)
        j = int((lat + 90) * ny / 180)
        if 0 <= i < nx and 0 <= j < ny:
            initial_field[0, j, i] = max(initial_field[0, j, i], conc)

    # --- 4. Set Background Concentration for Ocean Cells ---
    if not os.path.exists(topo_path):
        print(f"Warning: Topography file '{topo_path}' not found. Cannot set background concentration.")
    else:
        print(f"Setting background concentration of {background_conc:.1e} for empty ocean cells...")
        topo = np.fromfile(topo_path, dtype='>f4').reshape(ny, nx)
        ocean_mask = (topo < 0)
        zero_conc_mask = (initial_field[0, :, :] == 0)
        
        # Apply background concentration where it's ocean AND concentration is currently zero
        initial_field[0, ocean_mask & zero_conc_mask] = background_conc

    # --- 5. Write to Binary File ---
    output_filename = 'pollutant_initial.bin'
    try:
        with open(output_filename, "wb") as f:
            initial_field.tofile(f)
        print(f"Successfully wrote initial field to {output_filename}")
        print(f"  - Dimensions (nz, ny, nx): {initial_field.shape}")
        print(f"  - Max value: {initial_field.max():.2e}")
        print(f"  - Min non-zero value: {initial_field[initial_field>0].min():.2e}")

    except Exception as e:
        print(f"Error writing binary file: {e}")

if __name__ == '__main__':
    create_initial_field()
