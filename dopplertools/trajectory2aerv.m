function [v_rad, az_deg_per_s, elev_deg_per_s] = trajectory2aerv(AZ, ELEV, slantRange, vNorth, vEast, vDown)
    %TRAJECTORY2AERV Convert detected object velocity components from local ENU to AER coordinates, from the perspective of a radar station.
    
    %   Input:
    %       AZ        - object azimuth angle in degrees, (angle from North, measured clockwise).
    %       ELEV      - object elevation angle in degrees (angle above the horizon).
    %       slantRange - slant range to the object in meters (line-of-sight distance from radar to object).
    %       vNorth    - object North velocity component in meters per second (ENU frame).
    %       vEast     - object East velocity component in meters per second (ENU frame).
    %       vDown     - object Down velocity component in meters per second (ENU frame).
    
    %   Output:
    %       v_rad     - Radial velocity in meters per second (towards/away from the radar).
    %       az_deg_per_s - Azimuthal angular velocity in degrees per second (horizontal component, perpendicular to radial).
    %       elev_deg_per_s - Elevation angular velocity in degrees per second (vertical component, perpendicular to radial).
    
    % Convert AZ and ELEV angles from degrees to radians
    AZ = deg2rad(AZ);
    ELEV = deg2rad(ELEV);

    % Calculate radial velocity (v_rad) in meters per second
    v_rad = vEast * cos(ELEV) * sin(AZ) + vNorth * cos(ELEV) * cos(AZ) + vDown * sin(ELEV);

    % Calculate azimuthal velocity (v_az) in meters per second
    v_az = -vEast * sin(AZ) + vNorth * cos(AZ);

    % Calculate elevation velocity (v_elev) in meters per second
    v_elev = -vEast * cos(ELEV) * cos(AZ) - vNorth * cos(ELEV) * sin(AZ) + vDown * cos(ELEV);

    % Convert azimuthal and elevation velocities to angular velocity (degrees per second)
    az_deg_per_s = (v_az / slantRange) * (180 / pi);
    elev_deg_per_s = (v_elev / slantRange) * (180 / pi);
end
