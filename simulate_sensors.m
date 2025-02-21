function observations = simulate_sensors(entry_time, sim_time, lat, lon, alt_m, mass_kg, diameter_m, frontal_area_m2, ablation, sensor_db, station_list, observations)
% SIMULATE_SENSORS Simulates observations of an object from a list of sensor stations.
%
%   obs_table = simulate_sensors(entry_time, sim_time, lat, lon, alt_m, mass_kg, diameter_m, frontal_area_m2, ablation, sensor_db, station_list, obs_table)
%
%   Inputs:
%       entry_time   - Datetime of object entry
%       sim_time     - Simulation time in seconds since entry_time
%       lat, lon     - Geodetic latitude and longitude of object (degrees)
%       alt_m        - Altitude(s) of object (meters) (scalar or array)
%       mass_kg      - Object mass (kg)
%       diameter_m   - Object diameter (meters)
%       frontal_area_m2 - Frontal area of the object (square meters)
%       ablation     - Boolean flag indicating if object is ablating
%       sensor_db    - Table containing sensor station data
%       station_list - Cell array of station IDs to consider
%       obs_table    - (Optional) Existing table to append new observations
%
%   Outputs:
%       obs_table    - Table containing observed parameters:
%                      ObservationTime, SimulationTime, Lat, Lon, Alt_km,
%                      Mass_kg, Diameter_m, FrontalArea_m2, Ablation, 
%                      StationID, observed_Az, observed_ELEV, SlantRange_km, 
%                      P_detect
%
%   This function computes whether the object is visible to each station,
%   and records the observed azimuth, elevation, slant range, and detection probability if visible.

    % Ensure altitude is a column vector
    alt_m = alt_m(:);

    % Initialize table if not provided
    if nargin < 12 || isempty(observations)
        observations = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', ...
            {'ObservationTime', 'SimulationTime', 'Lat', 'Lon', 'Alt_km', ...
             'Mass_kg', 'Diameter_m', 'frontalarea_m2', 'ablation', 'StationID', ...
             'observed_AZ', 'observed_ELEV', 'slantRange_m', 'P_detect'});
    end

    % Compute the current observation time
    obs_time = entry_time + seconds(sim_time);

    % Loop through specified stations
    for i = 1:numel(station_list)
        % Find the index of the station in the table
        station_idx = find(strcmp(sensor_db.StationID, station_list{i}), 1);

        % Skip if station not found
        if isempty(station_idx)
            continue;
        end

        % Compute min/max azimuth and elevation range
        Az_min = wrapTo360(sensor_db.sensorAZ(station_idx) - sensor_db.sensor_hor_FOV(station_idx) / 2);
        Az_max = wrapTo360(sensor_db.sensorAZ(station_idx) + sensor_db.sensor_hor_FOV(station_idx) / 2);
        El_min = wrapTo180(sensor_db.sensorELEV(station_idx) - sensor_db.sensor_vert_FOV(station_idx) / 2);
        El_max = wrapTo180(sensor_db.sensorELEV(station_idx) + sensor_db.sensor_vert_FOV(station_idx) / 2);

        % Convert geodetic coordinates to AER (Azimuth, Elevation, Range)
        [observed_AZ, observed_ELEV, slantRange_m] = geodetic2aer(lat, lon, alt_m, ...
            sensor_db.LAT(station_idx), sensor_db.LONG(station_idx), sensor_db.Altitude_m(station_idx), ...
            getPlanet('ellipsoid_m'));

        % Wrap azimuth and elevation
        observed_AZ = wrapTo360(observed_AZ);
        observed_ELEV = wrapTo180(observed_ELEV);

        % Check visibility
        if Az_min < Az_max
            az_visible = (Az_min <= observed_AZ) & (observed_AZ <= Az_max);
        else
            az_visible = (observed_AZ >= Az_min) | (observed_AZ <= Az_max);
        end

        visible = (observed_ELEV > 0) & az_visible & (El_min <= observed_ELEV) & (observed_ELEV <= El_max);

        % If visible, append the observation
        if any(visible)
            % Compute the detection probability
            P_detect = NEXRAD_detection_probability(frontal_area_m2, slantRange_m); % Convert slant range to meters

            % Create the new rows for the observations table
            new_rows = table( ...
                repmat(obs_time, size(alt_m)), repmat(sim_time, size(alt_m)), lat * ones(size(alt_m)), ...
                lon * ones(size(alt_m)), alt_m / 1000, repmat(mass_kg, size(alt_m)), repmat(diameter_m, size(alt_m)), ...
                repmat(frontal_area_m2, size(alt_m)), repmat(ablation, size(alt_m)), repmat({sensor_db.StationID{station_idx}}, size(alt_m)), ...
                observed_AZ, observed_ELEV, slantRange_m, repmat(P_detect, size(alt_m)), 'VariableNames', observations.Properties.VariableNames);

            % Append to the observations table
            observations = [observations; new_rows];
        end
    end
end
