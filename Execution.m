%% ==================== 1️⃣ Set Global Parameters ====================
disp('Setting global parameters...');

% Field II Path (Update with your own)
addpath('F:\matlab\r2023b\field_2');

% Initialize Field II
field_init;

% Model: L3-12-D Linear Array
% Transducer Parameters
f0 = 6.5e6;                % Transducer center frequency [Hz]
fs = 100e6;                % Sampling frequency [Hz]
c = 1540;                  % Speed of sound [m/s]
lambda = c / f0;           % Wavelength [m]

pitch = 0.20 / 1000;       % Element pitch [m]
kerf = 0.05 / 1000;        % Gap between elements [m]
width = pitch - kerf;      % Width of transducer element [m]
element_height = 5 / 1000; % Height of transducer element [m]
focus = [0, 0, 0.035];     % Fixed focal point [m]
N_elements = 256;          % Total number of physical elements
N_active = 128;            % Number of active elements

% Phantom Dimensions
x_size = 27/1000;         % Width [m]
z_size = 20/1000;         % Depth [m]
y_size = 0.01/1000;       % Thickness [m]
z_start = 2/1000;         % Start of the phantom in the z-direction [m]

% Image Parameters
no_lines = 100;           % Number of lines in the image
image_width = x_size;     % Width of the image [m]
d_x = image_width / no_lines; % Distance between adjacent lines [m]

N = 20000;  % Number of scatterers

% Display Completed Parameter Setup
disp('All parameters are set!');

%% ==================== 2️⃣ Generate Scatterer Positions and Noise (Only Once) ====================
disp('Generating scatterer positions and random noise...');

% Generate scatterer positions once
positions = zeros(N, 3);
positions(:,1) = (rand(N,1) - 0.5) * x_size; % x
positions(:,2) = (rand(N,1) - 0.5) * y_size; % y
positions(:,3) = rand(N,1) * z_size + z_start; % z

% Generate noise once for amplitude calculations
random_noise = randn(N,1);

% Save positions and noise so they remain fixed across all images
save('scatterer_positions.mat', 'positions', 'random_noise');
disp('Scatterer positions and random noise generated and saved!');


%% ==================== 3️⃣ Process Each BMP File Sequentially ====================

% Define the folders
image_folder = 'BubbleImages_60';
output_folder = 'ProcessedImages';  % Folder to save processed images
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Define log file for processed images
log_file = 'processed_files.txt';

% Load processed files log
if isfile(log_file)
    fid = fopen(log_file, 'r');
    processed_files = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    processed_files = processed_files{1};
else
    processed_files = {};
end

% Get list of all BMP files
bmp_files = dir(fullfile(image_folder, '*.bmp'));
bmp_filenames = {bmp_files.name};

% Identify new files (not processed)
new_files = setdiff(bmp_filenames, processed_files);

% Process each new BMP file
for i = 1:length(new_files)
    bmp_filename = new_files{i};
    disp(['Processing: ', bmp_filename]);

    % Load the BMP Image
    bmp_path = fullfile(image_folder, bmp_filename);
    [liv_kid, ~] = bmpread(bmp_path);

    % Clean rf_data folder before processing
    folderPath = 'rf_data'; % Change to your folder name
    delete(fullfile(folderPath, '*.*')); % Deletes all files inside
    disp('Folder cleaned: All files removed.');
    
    filename = bmp_filename;

    % Load fixed scatterer positions
    load('scatterer_positions.mat', 'positions');

    % Assign new amplitudes based on the current image
    [phantom_positions, phantom_amplitudes] = scatterers_phantom(N, x_size, z_size, y_size, z_start, liv_kid, filename,positions, random_noise);
    
    % Save Phantom Data (Only updating amplitudes)
    save('pht_data.mat', 'positions', 'phantom_amplitudes');
    disp('Phantom Data saved!');

    % Run B-mode Imaging
    disp('Running B-mode Imaging...');
    run('train_image.m');

    figure();
    % Process and Display RF Data
    disp('Processing RF Data and Displaying Image...');
    run('make_image.m');

    % Save the figure
    output_filename = strrep(bmp_filename, '.bmp', '_processed.png'); % Rename file
    save_path = fullfile(output_folder, output_filename);
    saveas(gcf, save_path);
    disp(['Image saved: ', save_path]);

    % Close figure to save memory
    close(gcf);

    % Append to processed files log
    fid = fopen(log_file, 'a');
    fprintf(fid, '%s\n', bmp_filename);
    fclose(fid);
end

disp('All new BMP files processed and saved!');
