function P_d = NEXRAD_detection_probability(object_area_m2, slantRange_m)
    % NEXRAD_detection_probability calculates the probability of detection for an object in a radar beam.
    %
    % Inputs:
    %   object_area_m2 - The effective area of the object (in m²) as seen by the radar
    %   slantRange_m - The slant range from the radar to the object (in meters)
    %
    % Output:
    %   P_d - The probability of detection (value between 0 and 1)
    
    % Assumptions (units are stated with each assumption):
    lambda = 0.1;    % Wavelength of radar in meters (S-band ~ 3 GHz)
    Pt = 750e3;      % Transmitted power in watts (750 kW)
    Gt = 45;         % Antenna gain (dB)
    Gr = 45;         % Receiver antenna gain (dB)
    L = 3;           % System losses (dB)
    N = -110;        % Noise power (dBm)
    B = 1e6;         % Bandwidth (1 MHz)
    beam_width_deg = 1; % NEXRAD beam width assumption in degrees
    
    % Convert gain and losses from dB to linear scale
    Gt_linear = 10^(Gt / 10);  % Dimensionless (linear)
    Gr_linear = 10^(Gr / 10);  % Dimensionless (linear)
    L_linear = 10^(L / 10);    % Dimensionless (linear)
    
    % Convert noise power from dBm to watts
    N_linear = 10^(N / 10) / 1000;  % Noise power in watts
    
    % Convert beam width from degrees to radians
    beam_width_rad = deg2rad(beam_width_deg);  % Beam width in radians
    
    % Calculate radar beam cross-sectional area at the slant range
    beam_area_m2 = pi * (slantRange_m^2) * beam_width_rad;  % Beam area in m²
    
    % Ensure the object area is within the beam cross-sectional area
    effective_area_m2 = min(object_area_m2, beam_area_m2);  % Effective area in m²
    
    % Calculate signal-to-noise ratio (SNR)
    SNR = (Pt * Gt_linear * Gr_linear * effective_area_m2) / (L_linear * N_linear * slantRange_m^4);
    
    % Convert SNR to dB
    SNR_dB = 10 * log10(SNR);  % SNR in dB
    
    % Set detection threshold (adjust as necessary for radar system characteristics)
    detection_threshold_dB = 6;  % Example threshold in dB for detection
    
    % Calculate the probability of detection using a sigmoidal function
    P_d = 1 / (1 + exp(-(SNR_dB - detection_threshold_dB)));  % Probability of detection
end
