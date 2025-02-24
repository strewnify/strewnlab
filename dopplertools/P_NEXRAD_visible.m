function probability = P_NEXRAD_visible(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown, VCPmode)
% This function calculates the probability that a NEXRAD radar beam will
% scan an object, based on it's instantaneous trajectory and operating mode
% This function DOES NOT calculate the probability that the object will be
% detected, only that it will be scanned.
% See Also
%   P_NEXRAD_detect, getNEXRAD

    spinrate_deg_s = getNEXRAD('spinrate_deg_s',VCPmode); % get reflectivity scan rate NEED to lookup ELEV... fix
    elevations = getNEXRAD('elevations',VCPmode);
    %n_sweeps = numel(elevations);     % Number of radar sweeps per volume scan
    sweep_time_s = 360 / spinrate_deg_s;
    volume_scan_time_s = getNEXRAD('VCP_duration_s',VCPmode);
    
    residence_time_s = beam_residence_time(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown);
    
    % Calculate the probability that the object will be scanned
    % meaning that residence will occur during a scan at that elevation.  
    % Probabilty cannot be greater than 1.  In
    % statistics this is known as an interval overlap problem.
    probability = min(1,(residence_time_s + sweep_time_s) ./ volume_scan_time_s);
    
end

