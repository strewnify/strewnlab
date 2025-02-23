function probability = P_NEXRAD_detect(frontalarea_m2, slantRange_km)
    % NEXRAD_detection_probability calculates the probability of detection using Rayleigh scattering.
    % This function assumes the radar beam passes over the object.
    %
    % Inputs:
    %   frontalarea_m2 - The frontal area of the object (m²) (can be a scalar or an array)
    %   slantRange_m - The slant range from the radar to the object (m) (can be a scalar or an array)
    %
    % Output:
    %   probability - The probability of detection (value between 0 and 1) for each input combination
    % See Also:
    %   P_NEXRAD_visible
    
    % Suggested improvements to this function:
    % Add object size classification to choose Rayleigh, Mie, or optical scattering method
    
    % Convert slant range to meters
    slantRange_m = slantRange_km .* 1000;
    
    % Assumptions
    lambda_m = getNEXRAD('lambda_m');     % Radar wavelength in meters (S-band ~ 3 GHz)
    TxPower_W = getNEXRAD('TxPower_W');    % Transmitted power in watts (750 kW)
    TxGain_dB = getNEXRAD('TxGain_dB');    % Transmitter antenna gain (dB)
    RxGain_dB = getNEXRAD('RxGain_dB');    % Receiver antenna gain (dB)
    system_losses_dB = getNEXRAD('system_losses_dB');  % System losses (dB)
    NoisePower_dBm = getNEXRAD('NoisePower_dBm');      % Noise power (dBm)
    
    % Detection threshold in dB
    % UNCERTAIN
    % Calibrated based on NEXRAD specs of Minimum Point target detection
    % 0.0004 m^2 (4cm^2; -34 dBsm) at 100 km  
    % Point Target References: A 0.5 meter sphere has an RCS of 0.785 m^2. 
    % Also, point target detection takes into account system characteristics: 
    % Bandwidth, Noise Temperature, Noise Figure, etc. 
    detection_threshold_dB = 47;
    
    % Convert gain and losses from dB to linear scale
    Gt_linear = 10^(TxGain_dB / 10);
    Gr_linear = 10^(RxGain_dB / 10);
    L_linear = 10^(system_losses_dB / 10);
    
    % Convert noise power from dBm to watts
    N_linear = 10^(NoisePower_dBm / 10) / 1000;
        
    % Scattering Regimes:
    %
    % Rayleigh Scattering (x ≪ 1):
    % - The object is much smaller than the wavelength.
    % - RCS follows σ ∝ D^6 / λ^4.
    % - Example: Small meteorites or raindrops in long-wavelength radar.
    %
    % Mie Scattering (0.1 ≤ x ≤ 10):
    % - The object is comparable in size to the wavelength.
    % - Complex interactions (resonances) affect RCS.
    % - Example: Large hailstones in weather radar.
    %
    % Optical (Geometric) Scattering (x ≫ 1):
    % - The object is much larger than the wavelength.
    % - RCS approximates the physical cross-sectional area: πD^2 / 4.
    % - Example: Large aircraft or space debris.

    % Calculate size parameter and choose RCS method
    Diameter_eq_m = 2 .* sqrt(frontalarea_m2 / pi);
    size_parameter = pi .* Diameter_eq_m ./ lambda_m;
    
    % Calculate RCS using Rayleigh approximation for a small sphere
    radius_m = sqrt(frontalarea_m2 ./ pi); % Compute radius from frontal area
    
    % Default to optical
    RCS = frontalarea_m2;

    % Rayleigh region: Assign Rayleigh RCS for small objects
    Rayleigh = size_parameter < 0.1;
    RCS(Rayleigh) = (pi^5 * radius_m(Rayleigh).^6) ./ (lambda_m.^4); % Rayleigh scattering formula;

    % Assign size parameter limits to the Mie region
    Mie_min_size = 0.1;
    Mie_max_size = 10;
    
    % Calculate range limits of the Mie region
    Mie_min_radius = (Mie_min_size * lambda_m) / (2 * pi); % minimum radius in the Mie region
    RCS_Rayleigh = (pi^5 * Mie_min_radius.^6) / (lambda_m^4); % Rayleigh scattering formula
        
    % Mie region: Assign RCS based on the element-wise interpolation between Rayleigh and Optical
    Mie = size_parameter >= Mie_min_size & size_parameter < Mie_max_size;
    RCS(Mie) = RCS_Rayleigh + ((size_parameter(Mie) - Mie_min_size) ./ (Mie_max_size - Mie_min_size)) .* (frontalarea_m2(Mie) - RCS_Rayleigh);

    % Calculate signal-to-noise ratio (SNR)
    SNR = (TxPower_W .* Gt_linear .* Gr_linear .* RCS) ./ (L_linear .* N_linear .* slantRange_m.^4);
    
    % Convert SNR to dB
    SNR_dB = 10 .* log10(SNR);
    
    % Calculate the probability of detection using a sigmoid function
    probability = 1 ./ (1 + exp(-(SNR_dB - detection_threshold_dB)));

