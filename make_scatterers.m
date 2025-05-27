[phantom_positions, phantom_amplitudes] = scatterers_phantom(N, x_size, z_size, y_size, z_start, liv_kid, filename);

%  Save the data

save pht_data.mat phantom_positions phantom_amplitudes
