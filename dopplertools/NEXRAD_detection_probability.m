function P_d = NEXRAD_detection_probability(frontalarea_m2, slantRange_m)
    % NEXRAD_detection_probability calculates the probability of detection using Rayleigh scattering.
    %
    % Inputs:
    %   frontalarea_m2 - The frontal area of the object (m²) (can be a scalar or an array)
    %   slantRange_m - The slant range from the radar to the object (m) (can be a scalar or an array)
    %
    % Output:
    %   P_d - The probability of detection (value between 0 and 1) for each input combination
    
    % Assumptions
    lambda = 0.1; % Radar wavelength in meters (S-band ~ 3 GHz)
    Pt = 750e3;   % Transmitted power in watts (750 kW)
    Gt = 45.5;    % Transmitter antenna gain (dB)
    Gr = 45.5;    % Receiver antenna gain (dB)
    L = 2.7;      % System losses (dB)
    N = -112;     % Noise power (dBm)
    beam_width_deg = 0.925; % NEXRAD beam width in degrees
    detection_threshold_dB = -9.5; % Detection threshold in dB
    
    % Convert gain and losses from dB to linear scale
    Gt_linear = 10^(Gt / 10);
    Gr_linear = 10^(Gr / 10);
    L_linear = 10^(L / 10);
    
    % Convert noise power from dBm to watts
    N_linear = 10^(N / 10) / 1000;
    
    % Convert beam width to radians and calculate beam area at slant range
    beam_width_rad = deg2rad(beam_width_deg);
    
    % Calculate RCS using Rayleigh approximation for a small sphere
    radius_m = sqrt(frontalarea_m2 / pi); % Compute radius from frontal area
    RCS = (pi^5 * radius_m.^6) / (lambda^4); % Rayleigh scattering formula
    
    % Calculate signal-to-noise ratio (SNR)
    SNR = (Pt * Gt_linear * Gr_linear .* RCS) ./ (L_linear * N_linear * slantRange_m.^4);
    
    % Convert SNR to dB
    SNR_dB = 10 * log10(SNR);
    
    % Calculate the probability of detection using a sigmoid function
    P_d = 1 ./ (1 + exp(-(SNR_dB - detection_threshold_dB)));
end
