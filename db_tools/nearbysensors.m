function [data_disp] = nearbysensors(LAT,LONG,Height_km,data_tb)
%[DATA] = NEARBYSENSORS(LAT,LON, HEIGHT_KM, DATABASE) Find all sensors in range of a 3D location

% Load config for default FOV settings
strewnconfig

% check database for errors
if ~isempty(find(data_tb.sensor_hor_FOV < 0,1)) || ~isempty(find(data_tb.sensor_hor_FOV > 360,1)) ||...
        ~isempty(find(data_tb.sensor_vert_FOV < 0,1)) || ~isempty(find(data_tb.sensor_vert_FOV > 360,1)) ||...
        ~isempty(find(data_tb.sensorAZ < 0,1)) || ~isempty(find(data_tb.sensorAZ > 360,1)) ||...
        ~isempty(find(data_tb.sensorELEV < -90,1)) || ~isempty(find(data_tb.sensorELEV > 90,1))
    logformat('Invalid FOV data in database','ERROR')
end

logformat('Input height not used','DEBUG')
planet = getPlanet();
Height_m = Height_km.*1000; % convert units

% Calculate angles and distances for each sensor
[curveDistance_m, observed_AZ] = distance(data_tb.LAT,data_tb.LONG,LAT,LONG,planet.ellipsoid_m);
[~, observed_ELEV, slantRange_m] = geodetic2aer(LAT,LONG, Height_m, data_tb.LAT,data_tb.LONG, data_tb.Altitude_m, planet.ellipsoid_m);

% Store data to table
data_tb.observed_AZ = observed_AZ;
data_tb.curveDistance_km = curveDistance_m./1000;
data_tb.observed_ELEV = observed_ELEV;
data_tb.slantRange_km = slantRange_m./1000;
data_tb.PctSensorRange = data_tb.curveDistance_km ./ data_tb.range_km .* 100;

% future feature - filter operational cameras at the time of the event

% TEMPORARY filter out seismic stations
data_tb = data_tb(data_tb.Type ~= "Seismic",:);

% TEMPORARY - filter sensors in range
% Need to calculate range for 3D view
data_tb = data_tb(data_tb.PctSensorRange < 100,:);

% calculate effective horizontal field of view, with defaulting for missing data
eff_hor_FOV = data_tb.sensor_hor_FOV;  % copy database FOV
eff_hor_FOV(isnan(eff_hor_FOV)) = 180;  % replace missing FOV with 180
sensorAZ = data_tb.sensorAZ; % copy database azimuth
data_tb.eff_minAZ = wrapTo360(sensorAZ - eff_hor_FOV./2);
data_tb.eff_maxAZ = wrapTo360(sensorAZ + eff_hor_FOV./2);

% Calculate the position of the event in the horizontal FOV of each camera
data_tb.pct_horFOV = pctHorFOV(data_tb.eff_minAZ,data_tb.eff_maxAZ,data_tb.observed_AZ);
data_tb.pct_horFOV(data_tb.sensor_hor_FOV == 360) = NaN; % 360 degree sensors, like NEXRAD
data_tb.pct_horFOV(data_tb.sensorELEV == 90) = NaN;

% calculate effective vertical field of view, with defaulting for missing data
eff_vert_FOV = data_tb.sensor_vert_FOV;  % copy database FOV
eff_vert_FOV(isnan(eff_vert_FOV)) = 180; % replace missing FOV with 180
data_tb.eff_minELEV = wrapTo180(data_tb.sensorELEV - eff_vert_FOV./2);
data_tb.eff_maxELEV = wrapTo180(data_tb.sensorELEV + eff_vert_FOV./2);

% Calculate the position of the event in the vertical FOV of each camera
data_tb.pct_vertFOV = pctVertFOV(data_tb.eff_minELEV,data_tb.eff_maxELEV,data_tb.observed_ELEV);
data_tb.pct_vertFOV(data_tb.sensorELEV == 90) = NaN;

% filter cameras pointing in the correct direction
data_tb = data_tb(isnan(data_tb.pct_horFOV) | (data_tb.pct_horFOV > -5 & data_tb.pct_horFOV < 105),:);

% Sort the data, ascending by sensor range, then by type
data_disp = sortrows(data_tb,["Type","PctSensorRange"],'ascend');


