axis_x = [-x_size/2, x_size/2] * 1000; % Convert to mm
axis_z = [7.5/1000, 27.5/1000] * 1000; % Convert to mm


% Initialize variables
min_sample = 0;

% Read the RF data and adjust it in time
for i = 1:no_lines
    % Load the RF data for each line
    cmd = sprintf('load rf_data/rf_ln%d.mat', i);
    disp(cmd);
    eval(cmd);

    % Find the envelope using the Hilbert transform
    rf_env = abs(hilbert([zeros(round(tstart * fs - min_sample), 1); rf_data]));
    env(1:max(size(rf_env)), i) = rf_env;
end

% Perform logarithmic compression
D = 10;         % Decimation factor
dB_range = 45;  % Dynamic range for display in dB (adjusted to match phantom dynamics)

disp('Finding the envelope');
log_env = env(1:D:max(size(env)), :) / max(max(env));
log_env = 20 * log10(log_env);
log_env = 127 / dB_range * (log_env + dB_range);

% Perform interpolation to smooth the image
disp('Doing interpolation');
ID = 20; % Interpolation factor
[n, m] = size(log_env);
new_env = zeros(n, m * ID);

for i = 1:n
    new_env(i, :) = interp(log_env(i, :), ID);
end

[n, m] = size(new_env);

% Display the image
fn = fs / D; % New sampling frequency after decimation
clf;
image(((1:(ID * no_lines - 1)) * d_x / ID - no_lines * d_x / 2) * 1000, ...
      ((1:n) / fn + min_sample / fs) * c / 2 * 1000, new_env);
xlabel('Lateral distance [mm]');
ylabel('Axial distance [mm]');
colormap(gray(128));
axis('image');

% Adjust the axis range to match the kidney phantom
axis([axis_x(1), axis_x(2), axis_z(1), axis_z(2)]); % Adjusted based on x_size and z_size of the phantom
