% Linear Array B-mode Imaging with Adjusted Parameters
apodization_values = zeros(100, 2); % Columns: [N_pre, N_post]

% Set Sampling Frequency
set_sampling(fs);

% Create Transmit and Receive Apertures
xmit_aperture = xdc_linear_array(N_elements, width, element_height, kerf, 1, 1, focus);
receive_aperture = xdc_linear_array(N_elements, width, element_height, kerf, 1, 1, focus);

% Impulse Response and Excitation Signal
impulse_response = sin(2 * pi * f0 * (0:1/fs:2/f0));
impulse_response = impulse_response .* hanning(length(impulse_response))';
xdc_impulse(xmit_aperture, impulse_response);

excitation = sin(2 * pi * f0 * (0:1/fs:2/f0));
xdc_excitation(xmit_aperture, excitation);
xdc_impulse(receive_aperture, impulse_response);

% Load Scatterer Data
if ~exist('pht_data.mat', 'file')
    error('Scatterer data file "pht_data.mat" not found. ');
else
    load pht_data; % Load 'phantom_positions' and 'phantom_amplitudes'
end

% Set Focal Zones for Reception
focal_zones = linspace(z_start, z_start + z_size, 5)';
Nf = length(focal_zones);
focus_times = (focal_zones - z_start) / c;

% Set Apodization
apo = hanning(N_active)';

% Linear Array Imaging
for i = 1:no_lines
    % File for Storing RF Data
    file_name = sprintf('rf_data/rf_ln%d.mat', i);

    if ~exist(file_name, 'file')
        % Reserve the Calculation by Creating an Empty File
        save(file_name, 'i');

        disp(['Now calculating line ', num2str(i)]);

        % Calculate Imaging Direction
        x = -image_width / 2 + (i - 1) * d_x;

        % Set Focus for Current Direction
        xdc_center_focus(xmit_aperture, [x, 0, 0]);
        xdc_focus(xmit_aperture, 0, [x, 0, focal_zones(end)]);
        xdc_center_focus(receive_aperture, [x, 0, 0]);
        xdc_focus(receive_aperture, focus_times, [x * ones(Nf, 1), zeros(Nf, 1), focal_zones]);

        
        % Calculate the apodization vector for current line
        N_post = 208;
        

        N_pre = max(0, round(x / (width + kerf) + N_elements / 2 - N_active / 2));
        
        if N_pre == 0
            N_post = N_post - 3 * i; % Decrease by an additional 3 for each occurrence
        else
            N_post = max(0, N_elements - N_pre - N_active);
        end
        
        apodization_values(i, :) = [N_pre, N_post];


        apo_vector = [zeros(1, N_pre), apo, zeros(1, N_post)];

        % Ensure the apodization vector matches the number of elements
        if length(apo_vector) > N_elements
            apo_vector = apo_vector(1:N_elements); % Trim excess elements
        elseif length(apo_vector) < N_elements
            apo_vector = [apo_vector, zeros(1, N_elements - length(apo_vector))]; % Pad missing elements
        end

        % Set the apodization for transmit and receive apertures
        xdc_apodization(xmit_aperture, 0, apo_vector);
        xdc_apodization(receive_aperture, 0, apo_vector);


        % Simulate Scattering
        [rf_data, tstart] = calc_scat(xmit_aperture, receive_aperture, phantom_positions, phantom_amplitudes);

        % Save RF Data
        save(file_name, 'rf_data', 'tstart');
    else
        disp(['Line ', num2str(i), ' is being processed by another machine.']);
    end
end

% Free Apertures
xdc_free(xmit_aperture);
xdc_free(receive_aperture);

disp('Simulation completed. Run make_image to process and display the image.');