function residence_time_s = beam_residence_time(slantRange_km, objAZ, objELEV, vNorth_mps, vEast_mps, vDown_mps)
% BEAM_RESIDENCE_TIME - Calculates the residence time of an object in the radar beam.
%
% Syntax:
%   residence_time_s = beam_residence_time(slantRange_m, objAZ, objELEV, vNorth_mps, vEast_mps, vDown_mps)
%
% Description:
%   This function calculates the residence time of an object within the radar beam based
%   on the object's motion and the radar beam width. The object’s motion is given in terms
%   of velocity components in the local East-North-Up (ENU) coordinate system. The residence
%   time is determined by the speed at which the object crosses the radar beam's elevation range.
%
% Inputs:
%   slantRange_m - Slant range to the object in meters.
%   objAZ        - Azimuth angle of the object's position (degrees).
%   objELEV      - Elevation angle of the object's position (degrees).
%   vNorth_mps       - Velocity component of the object in the North direction (m/s).
%   vEast_mps        - Velocity component of the object in the East direction (m/s).
%   vDown_mps        - Velocity component of the object in the Down direction (m/s).
%
% Outputs:
%   residence_time_s - Time in seconds the object remains within the radar beam's elevation range.
%
% Example:
%   residence_time = beam_residence_time(100, 45, 5, 20, 10, 5);
%   % Calculates the residence time for an object at 100 km, azimuth 45°, elevation 5°,
%   % and moving with velocities (20 m/s, 10 m/s, 5 m/s) in the North, East, and Down directions.
%
% See Also:
%   P_NEXRAD_detect, getNEXRAD, trajectory2aerv

    % Constants
    beam_width_deg = getNEXRAD('beamwidth_deg');  % Fixed radar beam width (in degrees)
    
    slantRange_m = slantRange_km .* 1000;
    
    % Convert object velocity components from local ENU to AER coordinates, 
    % from the perspective of the radar station
    [~, ~, ELEV_deg_per_s] = trajectory2aerv(objAZ, objELEV, slantRange_m, vNorth_mps, vEast_mps, vDown_mps);
    
    % Calculate time to cross the beam in elevation
    residence_time_s = abs(beam_width_deg ./ ELEV_deg_per_s);  % Time in seconds to cross the beam width
end
