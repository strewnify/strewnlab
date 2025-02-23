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
    % spin rate was estimated by ChatGPT, it is unclear if these rates are constants.
    mode_data = struct( ...
        'VCP31', struct('name', 'VCP 31', 'spinrate_deg_s',9 , 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5], 'duration', 10, 'mode_type', 'Clear-air'), ...
        'VCP34', struct('name', 'VCP 34', 'spinrate_deg_s',9, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5], 'duration', 11, 'mode_type', 'Clear-air'), ...
        'VCP35', struct('name', 'VCP 35', 'spinrate_deg_s',12, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], 'duration', 7, 'mode_type', 'Clear-air'), ...
        'VCP12', struct('name', 'VCP 12', 'spinrate_deg_s',18, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5], 'duration', 4.3, 'mode_type', 'Precipitation'), ...
        'VCP112', struct('name', 'VCP 112', 'spinrate_deg_s',18, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5], 'duration', 5.5, 'mode_type', 'Precipitation'), ...
        'VCP212', struct('name', 'VCP 212', 'spinrate_deg_s',18, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5], 'duration', 4.6, 'mode_type', 'Precipitation'), ...
        'VCP215', struct('name', 'VCP 215', 'spinrate_deg_s',15, 'elevations', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5], 'duration', 6, 'mode_type', 'Precipitation') ...
    );

    % Radar system constants
    lambda_m = 0.1;           % Radar wavelength (m) (S-band ~ 3 GHz)
    TxPower_W = 750e3;     % Transmitted power (W) (750 kW)
    TxGain_dB = 45.5;             % Transmitter antenna gain (dB)
    RxGain_dB = 45.5;             % Receiver antenna gain (dB)
    system_losses_dB = 2.7;   % System losses (dB)
    NoisePower_dBm = -112;             % Noise power (dBm)
    beamwidth_deg = 0.925;   % Beam width (degrees)
    
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
            
        case 'beamwidth_deg'
            value = beamwidth_deg;
        
        case 'elevations'
            mode_needed = true;
            value = mode_data.(mode).elevations;
            
        case 'spinrate_deg_s'
            mode_needed = true;
            value = mode_data.(mode).spinrate_deg_s;
        
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