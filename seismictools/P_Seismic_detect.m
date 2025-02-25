function [P_detect, magnitude_dB] = P_Seismic_detect(slantRange_km, altitude_km, mass_kg, airspeed_mps)
    % Estimates the probability of a seismic station detecting a meteor sonic boom.
    %
    % Inputs:
    %   slantRange_km - Distance from meteor airburst to seismic station (km), scalar or array
    %   mass_kg - Mass of the meteor (kg), scalar or array
    %   airspeed_mps - Velocity of the meteor (m/s), scalar or array
    %
    % Output:
    %   P_detect - Probability of seismic detection (0 to 1), same size as inputs

    % Constants
    KE_thresh = 1e9;  % Rough threshold for seismic detection (J)
    k = 1e-10;         % Steepness factor for KE influence
    c = 0.05;          % Attenuation factor for distance (1/km)
    p_ref = 20e-6; % Reference sound pressure (in Pascals, 20 µPa for air)
    
    slantRange_m = slantRange_km .* 1000;
    
    % Calculate atmosphere
    altitude_m = altitude_km .* 1000;
    ground = 0;
    pbaro = 101325;
    TrefC = 20;
    [ ~, air_temperature_C, rho_kg_m3] = barometric( pbaro, TrefC, ground, altitude_m);

    % Calculate local speed of sound
    speedsound_mps = 20.05 .* sqrt(air_temperature_C + 273.15);
       
    % Ensure element-wise calculations for array inputs
    kinetic_energy_J = 0.5 .* mass_kg .* (airspeed_mps .^ 2);
    
    % Compute probability using a sigmoid function
    P_detect = 1 ./ (1 + exp(-k .* (kinetic_energy_J - KE_thresh) + c .* slantRange_km));
    
    % Calculate received sound pressure level (SPL) in dB
    p_source = sqrt(2 .* rho_kg_m3 .* speedsound_mps.^2 .* kinetic_energy_J);
    magnitude_dB = 20 .* log10(p_source ./ (slantRange_m.^2 .* p_ref));

