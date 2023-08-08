function [data_disp] = nearbysensors(LAT,LONG,Height_km,data_tb)
%[DATA] = NEARBYSENSORS(LAT,LON, HEIGHT_KM, DATABASE) Find all sensors in range of a 3D location

% check database for errors
if ~isempty(find(data_tb.cam_hor_FOV < 0,1)) || ~isempty(find(data_tb.cam_hor_FOV > 360,1)) ||...
        ~isempty(find(data_tb.cam_vert_FOV < 0,1)) || ~isempty(find(data_tb.cam_vert_FOV > 360,1)) ||...
        ~isempty(find(data_tb.cam_AZ < 0,1)) || ~isempty(find(data_tb.cam_AZ > 360,1)) ||...
        ~isempty(find(data_tb.cam_ELEV < 0,1)) || ~isempty(find(data_tb.cam_ELEV > 360,1))
    logformat('Invalid FOV data in database','ERROR')
end

logformat('Input height not used','DEBUG')
planet = getPlanet();

[curveDistance_m, observed_AZ] = distance(data_tb.LAT,data_tb.LONG,LAT,LONG,planet.ellipsoid_m);
data_tb.observed_AZ = observed_AZ;
data_tb.curveDistance_km = curveDistance_m./1000;
data_tb.PctSensorRange = data_tb.curveDistance_km ./ data_tb.range_km .* 100;

% future feature - filter operational cameras at the time of the event

% TEMPORARY filter out seismic stations
data_tb = data_tb(data_tb.Type ~= "Seismic",:);

% TEMPORARY - filter sensors in range
% Need to calculate range for 3D view
data_tb = data_tb(data_tb.PctSensorRange < 100,:);

% calculate effective field of view, with defaulting for missing data
eff_hor_FOV = data_tb.cam_hor_FOV;  % copy database FOV
eff_hor_FOV(isnan(eff_hor_FOV)) = 180;  % replace missing FOV with 180
eff_vert_FOV = data_tb.cam_hor_FOV;  % copy database FOV
eff_vert_FOV(isnan(eff_hor_FOV)) = 180; % replace missing FOV with 180
cam_AZ = data_tb.cam_AZ; % copy database azimuth
data_tb.eff_minAZ = wrapTo360(cam_AZ - eff_hor_FOV./2);
data_tb.eff_maxAZ = wrapTo360(cam_AZ + eff_hor_FOV./2);

% Calculate the position of the event in the horizontal FOV of each camera
data_tb.pct_horFOV = pctFOV(data_tb.eff_minAZ,data_tb.eff_maxAZ,data_tb.observed_AZ);
data_tb.pct_horFOV(data_tb.cam_hor_FOV == 360) = 50; % 360 degree sensors, like NEXRAD
data_tb.pct_horFOV(data_tb.Type == "AllSky") = 50;

% filter cameras pointing in the correct direction
%data_tb = data_tb(data_tb.pct_horFOV > -2 & data_tb.pct_horFOV < 102,:);

% Sort the data, ascending by sensor range, then by type
data_disp = sortrows(data_tb,["Type","PctSensorRange"],'ascend');


