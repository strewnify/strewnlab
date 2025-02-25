function probability = P_NEXRAD_visible(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown, VCPmode)
% This function calculates the probability that a NEXRAD radar beam will
% scan an object, based on it's instantaneous trajectory and operating mode
% This function DOES NOT calculate the probability that the object will be
% detected, only that it will be scanned.
% See Also
%   P_NEXRAD_detect, getNEXRAD

    % Define accuracy of the objELEV input
    % If an object is between elevation sweeps, this margin of error will allow it to be seen by both
    % For example, if an object is at 1.2 degrees, with an error of +/- 0.5 degrees,
    % it will be considered to be anywhere between 0.7 and 1.7 degrees, so
    % it will be visible to both the 0.5 and 1.5 degrees elevation sweeps
    ELEV_data_error = 0.5;

    % Option to use only the reflectivity scans for probability calculation
    reflect_only = true;
    
    % Calculate elevation range of the observation
    objELEV_min = objELEV - ELEV_data_error;
    objELEV_max = objELEV + ELEV_data_error;
    
    % Get the radar beam width
    beamwidth_deg = getNEXRAD('beamwidth_deg',VCPmode);
    
    elevations = getNEXRAD('elevations',VCPmode); % get scan elevations
    spinrate_deg_s = getNEXRAD('spin_rates_deg_s',VCPmode); % get scan rates for each elevation
    reflectivity = getNEXRAD('reflectivity',VCPmode); % get the scan types
    
    % Decide which sweep types to include
    if reflect_only
        sweep_filter = reflectivity; % only reflectivity sweeps
    else
        sweep_filter = true(size(elevations)); % all sweeps
    end
    
    % Check visibilty for each elevation
    visible = sweep_filter & ...
        (elevations + beamwidth_deg/2) >= objELEV_min & ...
        (elevations - beamwidth_deg/2) <= objELEV_max;
    
    % Calculate sweep times from spin rate
    sweep_times_s = 360 ./ spinrate_deg_s;
    
    % Sum the sweep times where the object would be visible
    visible_sweep_time_s = sum(sweep_times_s(visible));
    volume_scan_time_s = getNEXRAD('VCP_duration_s',VCPmode);
    
    % Calculate the residence time of the object in the elevation range
    residence_time_s = beam_residence_time(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown);
    
    % Calculate the probability that the object will be scanned
    % meaning that residence will occur during a scan at that elevation.  
    % Probabilty cannot be greater than 1.  In
    % statistics this is known as an interval overlap problem.
    probability = min(1,(residence_time_s + visible_sweep_time_s) ./ volume_scan_time_s);
    

