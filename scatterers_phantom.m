function [positions, amp] = scatterers_phantom(N, x_size, z_size, y_size, z_start, liv_kid, filename, cpositions, random_noise)

    % Extract x_target_index and z_target_index from the filename
    tokens = regexp(filename, '\((\d+),(\d+)\)', 'tokens');

    if ~isempty(tokens)
        x_target_index = str2double(tokens{1}{1}); % Extract x index
        z_target_index = str2double(tokens{1}{2}); % Extract z index
    else
        error('Filename does not contain valid (x,z) pixel coordinates.');
    end
    
    % Define image coordinates
    liv_kid = liv_kid';
    [Nl, Ml] = size(liv_kid);

    dx = x_size / Nl;  % Sampling interval in x direction [m]
    dz = z_size / Ml;  % Sampling interval in z direction [m]

    % Use precomputed positions
    x = cpositions(:,1);
    y = cpositions(:,2);
    z = cpositions(:,3);
    
    % Find the index for the amplitude value
    xindex = round((x + 0.5 * x_size) / dx + 1); % x pixel index
    zindex = round((z - z_start) / dz + 1);      % z pixel index
    inside = (xindex > 0) & (xindex <= Nl) & (zindex > 0) & (zindex <= Ml); % Valid range check
    index = (xindex + (zindex - 1) * Nl) .* inside + 1 * (1 - inside); % Pixel position in matrix

    % Assign amplitudes based on the image
    amp = exp(liv_kid(index) / 100); 
    amp = amp - min(amp);
    amp = 1e6 * amp / max(amp);
    
    % Use precomputed noise instead of generating new noise
    amp = amp .* random_noise .* inside; % Apply randomness and ensure scatterers inside the image

    % Convert pixel index to real-world coordinates for the target scatterer
    x_target = (x_target_index - 1) * dx - 0.5 * x_size;
    z_target = (z_target_index - 1) * dz + z_start;
    y_target = (rand - 0.5) * y_size; % Random y-coordinate within range

    % Add one high-amplitude scatterer
    x = [x; x_target];
    y = [y; y_target];
    z = [z; z_target];
    amp = [amp; 3e6]; % Assign high amplitude

    % Adjust z positions to maintain relative structure
    z = z - min(z) + z_start;

    % Store all positions
    positions = [x y z];

end
