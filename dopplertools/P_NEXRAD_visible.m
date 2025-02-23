function probability = P_NEXRAD_visible(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown, VCPmode)
% This function calculates the probability that a NEXRAD radar beam will
% scan an object, based on it's instantaneous trajectory and operating mode
% This function DOES NOT calculate the probability that the object will be
% detected, only that it will be scanned.
% See Also
%   P_NEXRAD_detect, getNEXRAD

    spinrate_deg_s = getNEXRAD('spinrate_deg_s',VCPmode);
    elevations = getNEXRAD('elevations',VCPmode);
    n_sweeps = numel(elevations);     % Number of radar sweeps per volume scan
    sweep_time = 360 / spinrate_deg_s;
    volume_scan_time_s = sweep_time * n_sweeps;
    
    residence_time_s = beam_residence_time(slantRange_km, objAZ, objELEV, vNorth, vEast, vDown);
    
    probability = residence_time_s ./ volume_scan_time_s;
end

