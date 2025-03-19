function [v_rad, az_deg_per_s, elev_deg_per_s] = trajectory2aerv(AZ, ELEV, slantRange, vNorth_mps, vEast_mps, vDown_mps)
    % TRAJECTORY2AERV Convert detected object velocity components from local ENU to AER coordinates, from the perspective of a radar station.
    
    % Input:
    %   AZ        - object azimuth angle in degrees, (angle from North, measured clockwise).
    %   ELEV      - object elevation angle in degrees (angle above the horizon).
    %   slantRange - slant range to the object in meters (line-of-sight distance from radar to object).
    %   vNorth_mps    - object North velocity component in meters per second (ENU frame).
    %   vEast_mps     - object East velocity component in meters per second (ENU frame).
    %   vDown_mps     - object Down velocity component in meters per second (ENU frame).
    
    % Output:
    %   v_rad     - Radial velocity in meters per second (towards/away from the radar).
    %   az_deg_per_s - Azimuthal angular velocity in degrees per second (horizontal component, perpendicular to radial).
    %   elev_deg_per_s - Elevation angular velocity in degrees per second (vertical component, perpendicular to radial).
    
    % WARNING, THIS FUNCTION IS FLAT EARTH SIMPLIFIED
    % Calculations have been simplified WITH A FLAT EARTH assumption, and
    % results are not precise for long slantRanges
    
    % Ensure input arrays are column vectors
    AZ = deg2rad(AZ);     % Convert AZ angles to radians
    ELEV = deg2rad(ELEV); % Convert ELEV angles to radians

    % Calculate radial velocity (v_rad) in m/s
    v_rad = vNorth_mps .* cos(AZ) .* cos(ELEV) + vEast_mps .* sin(AZ) .* cos(ELEV) - vDown_mps .* sin(ELEV);

    % Calculate azimuthal angular velocity (v_az) in radians/second
    v_az = (vEast_mps .* cos(AZ) - vNorth_mps .* sin(AZ)) ./ slantRange; % rad/s

    % Convert azimuthal angular velocity to degrees per second
    az_deg_per_s = rad2deg(v_az); % Convert to degrees per second

    % Calculate elevation angular velocity (v_elev) in radians/second
    v_elev = -((vNorth_mps .* cos(AZ) .* sin(ELEV) + vEast_mps .* sin(ELEV) .* sin(AZ) + vDown_mps .* cos(ELEV)) ./ slantRange); % rad/s

    % Convert elevation angular velocity to degrees per second
    elev_deg_per_s = rad2deg(v_elev); % Convert to degrees per second
end
