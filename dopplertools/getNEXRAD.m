function [value] = getNEXRAD(parameter, mode)
    % getNEXRAD retrieves various system parameters or scan modes for NEXRAD radar.
    %
    % Usage:
    % value = getNEXRAD('parameter') - Returns a specific parameter of the NEXRAD system.
    % value = getNEXRAD('parameter', 'mode') - Returns the parameters for a specific VCP (Volume Coverage Pattern) mode.
    %
    % Inputs:
    % parameter: A string specifying the desired parameter to retrieve (e.g., 'lambda', 'P_transmit', 'vcp').
    % mode: Optional string specifying the VCP mode (e.g., 'VCP31', 'VCP35'). If omitted, defaults to 'VCP31'.
    %
    % Outputs:
    % value: The requested value based on the parameter and mode.
    %
    % Available parameters:
    % 'lambda_m'      - Radar wavelength (m) [S-band ~ 3 GHz]
    % 'TxPower_W'     - Transmitted power (W) [750 kW]
    % 'Gt'            - Transmitter antenna gain (dB)
    % 'Gr'            - Receiver antenna gain (dB)
    % 'system_losses' - System losses (dB)
    % 'N'             - Noise power (dBm)
    % 'beamwidth'     - Beam width (m) at 100 km slant range
    % 'receivedpower' - Received power at 100 km slant range (W)
    % 'snr'           - Signal-to-noise ratio at 100 km slant range (dB)
    % 'rangemax'      - Maximum detection range (m)
    % 'vcp'           - VCP mode (e.g., 'VCP31', 'VCP34', 'VCP35') and its characteristics
    %  
    % Volume Coverage Patterns (VCP) 
    % Major Characteristics:
    %
    % VCP 31: Original long pulse VCP used for "clear-air". 
    %   - Duration: Approximately 10 minutes
    %   - Elevations: 5 (ranging from 0.5 to 4.5 degrees)
    %   - Algorithms allowed/Notes: None specified.
    %
    % VCP 34: Long pulse VCP used for "clear-air".
    %   - Duration: Approximately 11 minutes
    %   - Elevations: 10 (ranging from 0.5 to 4.5 degrees)
    %   - Algorithms allowed/Notes: SAILSx1
    %
    % VCP 35: Default "clear-air" VCP.
    %   - Duration: Approximately 7 minutes
    %   - Elevations: 9 (ranging from 0.5 to 6.4 degrees)
    %   - Algorithms allowed/Notes: SAILSx1, SZ-2
    %
    % VCP 12: "Precipitation" VCP used for rapidly evolving events (e.g., supercells, squall lines).
    %   - Duration: Approximately 4.3 minutes
    %   - Elevations: 14 (ranging from 0.5 to 19.5 degrees)
    %   - Algorithms allowed/Notes: SAILSx3, AVSET, MRLEx4
    %
    % VCP 112: "Precipitation" VCP used for large-scale systems with high velocity (e.g., hurricanes, long squall lines).
    %   - Duration: Approximately 5.5 minutes
    %   - Elevations: 14 (ranging from 0.5 to 19.5 degrees)
    %   - Algorithms allowed/Notes: SAILSx1, AVSET, SZ-2
    %
    % VCP 212: "Precipitation" VCP used for rapidly evolving events (e.g., supercells, squall lines).
    %   - Duration: Approximately 4.6 minutes
    %   - Elevations: 14 (ranging from 0.5 to 19.5 degrees)
    %   - Algorithms allowed/Notes: SAILSx3, AVSET, MRLEx4, SZ-2
    %
    % VCP 215: Default "precipitation" VCP with lower SNR compared to other "precipitation" VCPs and better vertical coverage at the expense of scan time.
    %   - Duration: Approximately 6 minutes
    %   - Elevations: 15 (ranging from 0.5 to 19.5 degrees)
    %   - Algorithms allowed/Notes: SAILSx1, AVSET, MRLEx4, SZ-2

    % Define VCP modes
    % spin_rate is the rotation rate of the reflectivity scan only
    % detailed spin rate is available for some modes
    mode_data = struct( ...
    'VCP21', struct('name', 'VCP 21', 'elevations', [0.5, 0.5, 1.45, 1.45, 2.4, 3.35, 4.3, 6, 9, 14.6, 19.5], 'spin_rates_deg_s', [11.339, 11.360, 11.339, 11.360, 11.180, 11.182, 11.185, 11.189, 14.260, 14.322, 14.415], 'reflectivity', [true false true false true true true true true true true], 'mode_type', 'Clear-air'), ...
    'VCP31', struct('name', 'VCP 31', 'elevations', [0.5, 0.5, 1.5, 1.5, 2.5, 2.5, 3.5, 4.5], 'spin_rates_deg_s', [5.039, 5.039, 5.040, 5.062, 5.041, 5.062, 5.063, 5.065], 'reflectivity', [true false true false true false true true], 'mode_type', 'Clear-air'), ...
    'VCP32', struct('name', 'VCP 32', 'elevations', [0.5, 0.5, 1.5, 1.5, 2.5, 3.5, 4.5], 'spin_rates_deg_s', [4.961, 4.544, 4.961, 4.544, 4.060, 4.061, 4.063], 'reflectivity', [true false true false true true true], 'mode_type', 'Clear-air'), ...
    'VCP34', struct('name', 'VCP 34', 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5], 'spin_rates_deg_s', [5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5], 'reflectivity', [true true true true true true true true true true], 'mode_type', 'Clear-air'), ...
    'VCP35', struct('name', 'VCP 35', 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], 'spin_rates_deg_s', [12, 12, 12, 12, 12, 12, 12, 12, 12], 'reflectivity', [true true true true true true true true true], 'mode_type', 'Clear-air'), ...
    'VCP11', struct('name', 'VCP 11', 'elevations', [0.5, 0.5, 1.45, 1.45, 2.4, 3.35, 4.3, 5.25, 6.2, 7.5, 8.7, 10, 12, 14, 16.7, 19.5], 'spin_rates_deg_s', [18.675, 19.224, 19.854, 19.225, 16.166, 17.893, 17.898, 17.459, 17.466, 25.168, 25.398, 25.421, 25.464, 25.515, 25.596, 25.696], 'reflectivity', [true false true false true true true true true true true true true true true true], 'mode_type', 'Precipitation'), ...
    'VCP12', struct('name', 'VCP 12', 'elevations', [0.5, 0.5, 0.9, 1.3, 1.8, 2.4, 3.1, 3.1, 4, 5.1, 6.4, 8, 10, 12.5, 15.6, 19.5], 'spin_rates_deg_s', [21.150, 25.000, 21.150, 25.000, 26.640, 26.400, 26.400, 26.400, 28.010, 28.010, 28.010, 28.400, 28.884, 28.741, 28.741, 28.741],'reflectivity', [true false true true true true true false true true true true true true true true], 'mode_type', 'Precipitation'), ...
    'VCP112', struct('name', 'VCP 112', 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5], 'spin_rates_deg_s', [18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18], 'reflectivity', [true true true true true true true true true true true true true true], 'mode_type', 'Precipitation'), ...
    'VCP121', struct('name', 'VCP 121', 'elevations', [0.5, 0.5, 0.5, 0.5, 1.45, 1.45, 1.45, 1.45, 2.4, 2.4, 2.4, 3.5, 3.5, 3.5, 4.3, 4.3, 6, 9.9, 14.6, 19.5], 'spin_rates_deg_s', [29.301, 29.795, 27.400, 21.402, 29.300, 29.795, 27.400, 21.402, 19.205, 27.400, 21.402, 21.600, 27.400, 21.402, 16.304, 29.499, 20.204, 29.499, 29.795, 29.795], 'reflectivity', [true false false false true false false false true false false true false false true false true true true true], 'mode_type', 'Precipitation'), ...
    'VCP212', struct('name', 'VCP 212', 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5], 'spin_rates_deg_s', [18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18],'reflectivity', [true true true true true true true true true true true true true true], 'mode_type', 'Precipitation'), ...
    'VCP215', struct('name', 'VCP 215', 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5], 'spin_rates_deg_s', [15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15], 'reflectivity', [true true true true true true true true true true true true true true true true], 'mode_type', 'Precipitation') ...
);

    % Radar system constants
    lambda_m = 0.1;           % Radar wavelength (m) (S-band ~ 3 GHz)
    TxPower_W = 750e3;     % Transmitted power (W) (750 kW)
    TxGain_dB = 45.5;             % Transmitter antenna gain (dB)
    RxGain_dB = 45.5;             % Receiver antenna gain (dB)
    system_losses_dB = 2.7;   % System losses (dB)
    NoisePower_dBm = -112;             % Noise power (dBm)
    beamwidth_deg = 0.925;   % Beam width (degrees)
    
    % Limits
    % Need to better comprehend the velocity limit
    % Does the velocity scan ignore everything past the limit?
    range_reflectivity_km = 467;
    range_velocity_km = 116;
    
    % Default mode: 'VCP 31' if no mode is provided
    if nargin < 2
        mode = 'VCP31';  % Default to 'VCP 31'
    end
    mode_needed = false;
    
    % Switch case to handle different requested parameters
    switch lower(parameter)
        
        case 'lambda_m'
            value = lambda_m;  % Radar wavelength (m)
            
        case 'txpower_w'
            value = TxPower_W;  % Transmitted power (W)
            
        case 'txgain_db'
            value = TxGain_dB;  % Transmitter antenna gain (dB)
            
        case 'rxgain_db'
            value = RxGain_dB;  % Receiver antenna gain (dB)
            
        case 'system_losses_db'
            value = system_losses_dB;  % System losses (dB)
            
        case 'noisepower_dbm'
            value = NoisePower_dBm;  % Noise power (dBm)
        
        case 'range_reflectivity_km'
            value = range_reflectivity_km;
            
        case 'range_velocity_km'
            value = range_velocity_km;
            
        case 'beamwidth_deg'
            value = beamwidth_deg;

        case 'name'
            mode_needed = true;
            value =  mode_data.(mode).name; % Name of the VCP mode 
            
        case 'mode_type'
            mode_needed = true;
            value =  mode_data.(mode).mode_type; % Name of the VCP mode 
            
        case 'vcp_duration_s'
            mode_needed = true;
            value =  numel(mode_data.(mode).spin_rates_deg_s) * 360 * (1/mean(mode_data.(mode).spin_rates_deg_s));
            
        case 'elevations'
            mode_needed = true;
            value = mode_data.(mode).elevations;
            
        case 'reflectivity'
            mode_needed = true;
            value = mode_data.(mode).reflectivity;
            
        case 'spin_rates_deg_s'
            mode_needed = true;
            value = mode_data.(mode).spin_rates_deg_s;
                    
        case 'mode_type'
            mode_needed = true;
            value = mode_data.(mode).mode_type;
            
        otherwise
            error('Unknown parameter requested.');
    end

    % Warning message for defaulted mode
    if mode_needed && nargin < 2
        logformat('Volume Coverage Pattern (VCP) mode not specified, defaulted to VCP31','WARN')
    end