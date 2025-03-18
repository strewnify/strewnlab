function [observations] = simsensor(entry_time, sim_time, projectile, sensor_db, station_data, observations)
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
%       observations    - (Optional) Existing table to append new observations
%
%   Outputs:
%       observations - Table containing observed parameters:
%                      ObservationTime, SimulationTime, Lat, Lon, Alt_km,
%                      Mass_kg, Diameter_m, FrontalArea_m2, Ablation, 
%                      StationID, observed_Az, observed_ELEV, SlantRange_km, 
%                      P_detect
%
%   This function computes whether the object is visible to each station,
%   and records the observed azimuth, elevation, slant range, and detection probability if visible.

current = 1; % Do not change, defines current value in timestep arrays

% Initialize table if not provided
if nargin < 6 || isempty(observations)
    observations = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], 'VariableNames', ...
        {'rockID', 'sim_scenario', 'ObservationTime', 'SimulationTime', 'Lat', 'Long', 'Alt_km', ...
         'Mass_kg', 'Diameter_m', 'frontalarea_m2', 'ablation', 'StationID', 'sensorMode', ...
         'observed_AZ', 'observed_ELEV', 'slantRange_m', 'signal_delay_s', 'magnitude_dB', 'P_detect'});
end

% Compute the current observation time
obs_time = entry_time + seconds(sim_time);

for n = 1:size(projectile,2)
    if projectile(n).inflight > 0
        
        % Clear previous
        clear observed_AZ
        clear observed_ELEV
        clear slantRange_m
        clear slantRange_km
        clear P_detect
        clear signal_delay_s
        clear StationID
        clear sensorMode
        clear numrows
                
        % Get projectile data
        rockID = projectile(n).rockID;
        sim_scenario = projectile(n).sim_scenario;
        LAT = projectile(n).location(current,1);
        LONG = projectile(n).location(current,2);
        altitude_m = projectile(n).position(current,3);
        altitude_km = altitude_m ./ 1000;
        mass_kg = projectile(n).mass;
        diameter_m = projectile(n).diameter;
        frontalarea_m2 = projectile(n).frontalarea_m2;
        ablation = projectile(n).ablation;
        vNorth_mps = projectile(n).vNorth_mps;
        vEast_mps = projectile(n).vEast_mps;
        vDown_mps = projectile(n).vDown_mps;

        % Loop through specified stations
        for station_i = 1:size(station_data,2)
            % Find the index of the station in the table
            station_idx = find(strcmp(sensor_db.StationID, station_data(station_i).StationID), 1);

            % Skip if station not found
            if isempty(station_idx)
                continue;
            end

            % Get the station operating mode for the time of the same
            stationtime_i = max(1,find(station_data(station_i).Timestamps > obs_time,1)-1);
            if isempty(stationtime_i)
                stationtime_i = mode(station_data(station_i).sensorMode);
                logformat('Observation time outside expected window', 'WARN')
            end
            
            % Record the stationID data
            StationID(station_i) = {station_data(station_i).StationID};
            sensorMode(station_i) = station_data(station_i).sensorMode(stationtime_i);
            
            % Convert geodetic coordinates to AER (Azimuth, Elevation, Range)
            [observed_AZ(station_i), observed_ELEV(station_i), slantRange_m(station_i)] = geodetic2aer(LAT, LONG, altitude_m, ...
                sensor_db.LAT(station_idx), sensor_db.LONG(station_idx), sensor_db.Altitude_m(station_idx), ...
                getPlanet('ellipsoid_m'));

            slantRange_km(station_i) = slantRange_m(station_i) ./ 1000;

            % Check Sensor Type
            % Camera, Doppler, Geostationary, or Seismic
            switch sensor_db.Type(station_idx)
                case 'Camera'
                    % Not supported
                    % Once complete, this function will return probability of camera
                    % detection, based on ablation, camera FOV, and sensor score

                    % Compute min/max azimuth and elevation range
                    Az_min = wrapTo360(sensor_db.sensorAZ(station_idx) - sensor_db.sensor_hor_FOV(station_idx) / 2);
                    Az_max = wrapTo360(sensor_db.sensorAZ(station_idx) + sensor_db.sensor_hor_FOV(station_idx) / 2);
                    El_min = wrapTo180(sensor_db.sensorELEV(station_idx) - sensor_db.sensor_vert_FOV(station_idx) / 2);
                    El_max = wrapTo180(sensor_db.sensorELEV(station_idx) + sensor_db.sensor_vert_FOV(station_idx) / 2);

                    % Check visibility
                    if Az_min < Az_max
                        az_visible = (Az_min <= observed_AZ(station_i)) & (observed_AZ(station_i) <= Az_max);
                    else
                        az_visible = (observed_AZ(station_i) >= Az_min) | (observed_AZ(station_i) <= Az_max);
                    end

                    visible = (observed_ELEV(station_i) > 0) & az_visible & (El_min <= observed_ELEV(station_i)) & (observed_ELEV(station_i) <= El_max);

                    P_detect(station_i) = double(ablation); % convert logical array to 0 or 1

                    % Nearly zero, but light speed radar delay calculated for completeness
                    signal_delay_s(station_i) = slantRange_m(station_i) ./ getConstant('c_mps'); 
                    
                    magnitude_dB = NaN;

                case 'Doppler'
            
                    % Calculate the probability that the object will be visible to a radar sweep
                    P_visible = P_NEXRAD_visible(slantRange_km(station_i),observed_AZ(station_i),observed_ELEV(station_i),vNorth_mps,vEast_mps,vDown_mps,sensorMode(station_i));

                    % Calculate the probability that the object would be detected, if it was in the beam
                    [P_NEXRAD, magnitude_dB(station_i)] = P_NEXRAD_detect(frontalarea_m2, slantRange_km(station_i));

                    % Combine the probabilities to get overall probability of detection
                    P_detect(station_i) = P_visible .* P_NEXRAD;

                    % Nearly zero, but light speed radar delay calculated for completeness
                    signal_delay_s(station_i) = 2 .* slantRange_m(station_i) ./ getConstant('c_mps'); 

                case 'Geostationary'
                    % Not supported
                    % Once complete, this function will return probability of geostationary camera
                    % detection, based on ablation, camera FOV, and other factors

                    P_detect(station_i) = double(ablation); % convert logical array to 0 or 1

                    % Nearly zero, but light speed radar delay calculated for completeness
                    signal_delay_s(station_i) = slantRange_m(station_i) ./ getConstant('c_mps'); 
                    
                    magnitude_dB(station_i) = NaN;

                case 'Seismic'
                    % Not supported
                    % Once complete, this function will return probability of seismic
                    % detection, based on airspeed and range
                    % Need to review assumptions below

                    % Convert vector speed to scalar airspeed
                    % This is oversimplified slightly, because airspeed should include wind

                    % Calculate atmosphere
                    ground = 0;
                    pbaro = 101325;
                    TrefC = 20;
                    [ ~, air_temperature_C, ~] = barometric( pbaro, TrefC, ground, altitude_m);

                    % Calculate local speed of sound
                    speedsound = 20.05*sqrt(air_temperature_C + 273.15);

                    % Calculate airspeed
                    airspeed_mps = sqrt(vNorth_mps.^2 + vEast_mps.^2 + vDown_mps.^2);

                    % Estimate mass from frontal area
                    density_kg_m3 = 3380;
                    mass_kg = (4/3) * density_kg_m3 * pi^(1/2) * frontalarea_m2^(3/2);

                    % Calculate probability of sonic boom, based on sigmoid function, centered around mach 1
                    k = 0.13; % Estimated based on a transition range of ~30 m/s
                    P_Boom = 1 ./ (1 + exp(-k * (airspeed_mps - speedsound)));
                    [P_Boom_detect, magnitude_dB(station_i)] = P_Seismic_detect(slantRange_km(station_i), altitude_km, mass_kg, airspeed_mps);

                    %Calculate the probability of detection, based on distance from the seismic station
                    P_detect(station_i) = P_Boom .* P_Boom_detect;

                    % Calculate sonic delay 
                    signal_delay_s(station_i) = slantRange_m(station_i) ./ 333; 

                otherwise
                    logformat('Sensor type not supported', 'ERROR')
            end
        end
        
        % Count rows for repmat
        numrows = numel(P_detect)';
        
        % Create the new rows for the observations table
        new_rows = table( ...
            repmat(rockID, numrows,1), repmat(sim_scenario, numrows,1), repmat(obs_time, numrows,1), repmat(sim_time, numrows,1), repmat(LAT, numrows,1), ...
            repmat(LONG, numrows,1), repmat(altitude_km, numrows,1), repmat(mass_kg, numrows,1), repmat(diameter_m, numrows,1), ...
            repmat(frontalarea_m2, numrows,1), repmat(ablation, numrows,1), StationID', sensorMode', ...
            observed_AZ', observed_ELEV', slantRange_m', signal_delay_s', magnitude_dB', P_detect', 'VariableNames', observations.Properties.VariableNames);

        % Append to the observations table
        observations = [observations; new_rows];
    end
end




