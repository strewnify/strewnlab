function [score, data_name] = scoresensor( sensorLAT, sensorLONG, startLAT, startLONG, endLAT, endLONG, locality, event_id, station_id, sensorAZ, horFOV)
%SCORESENSOR Scores a sensor observation and generates a data filename.

defaultFOV = 180;

% Input checking
if nargin < 6
    logformat('First 6 inputs are required.','ERROR')
elseif nargin == 6 || isempty(locality)
    [ location_string, locality, state, country, water_string, land_string ] = getlocation(sensorLAT,sensorLONG);
    if isempty(locality) && ~isempty(water_string)
        locality = water_string;
    end
    logformat(sprintf('Locality not provided, Google query returned %s',locality),'INFO')
end
if nargin <= 7
    logformat('EventID not provided.','INFO')
    event_id = '';    
end
if nargin <= 8
       logformat(sprintf('Unknown station reporting from %s.',locality),'INFO')
       station_id = ['SCX' encodelocation(sensorLAT,sensorLONG)];
end
if nargin <= 9
    logformat('Unknown sensor azimuth.','INFO')
    sensorAZ = NaN;
end
if nargin <= 10
    logformat(sprintf('Unknown sensor FOV, defaulting to %0.0f.',defaultFOV),'INFO')
    horFOV = defaultFOV;
end

% Load ellipsoid
logformat('Input height not used','DEBUG')
logformat('Need to update to array function','DEBUG')
planet = getPlanet();

% Calculate vectors and field of view
[PathCurveDist_m, PathBearingAZ] = distance(startLAT,startLONG,endLAT,endLONG,planet.ellipsoid_m);
[startCurveDist_m, startObservedAZ] = distance(sensorLAT,sensorLONG,startLAT,startLONG,planet.ellipsoid_m);
[endCurveDist_m, endObservedAZ] = distance(sensorLAT,sensorLONG,endLAT,endLONG,planet.ellipsoid_m);
startCurveDist_km = startCurveDist_m ./ 1000;
endCurveDist_km = endCurveDist_m ./ 1000;
startAngle = wrapTo180(startObservedAZ - PathBearingAZ);
endAngle = wrapTo180(endObservedAZ - PathBearingAZ);
minAZ = wrapTo360(sensorAZ - horFOV./2);
maxAZ = wrapTo360(sensorAZ + horFOV./2);
startFOVposition_pct = pctHorFOV(minAZ, maxAZ, startObservedAZ);
endFOVposition_pct = pctHorFOV(minAZ, maxAZ, endObservedAZ);

% default position for missing FOV
startFOVposition_pct(isnan(startFOVposition_pct)) = 25;
endFOVposition_pct(isnan(endFOVposition_pct)) = 25;

% Score sensor positioning for event
startScore = 70*exp(-0.006*startCurveDist_km);
endScore = 70*exp(-0.006*endCurveDist_km);
startMult = 38.14/(abs(startFOVposition_pct-50)+19.07);
endMult = 38.14/(abs(endFOVposition_pct-50)+19.07);
startMult(isnan(startMult)) = 1;
endMult(isnan(endMult)) = 1;
startAngMult = 1 + abs(cosd(2*startAngle));
endAngMult = 1 + abs(cosd(2*endAngle));
score = startScore*startMult*startAngMult + endScore*endMult*endAngMult;
score_string = ['x' sprintf('%03.0f',score)];

% Create a MATLAB-friendly lat/long string suffix
formatting = '%0.8g';

% latitude string
if sensorLAT >= 0
    LATstring = [sprintf('%0.8g',round(sensorLAT,7)) 'N'];
else
    LATstring = [sprintf('%0.8g',round(abs(sensorLAT),7)) 'S'];
end

% formatting significant digits for longitude
if abs(sensorLONG) >= 100
    formatting = '%0.9g';
    offset = 1;
end

% longitude string
if sensorLONG >= 0
    LONGstring = [sprintf(formatting,round(sensorLONG,7)) 'N'];
else
    LONGstring = [sprintf(formatting,round(abs(sensorLONG),7)) 'S'];
end
coord_string = strrep([LATstring '_' LONGstring],'.','p');

% Concatenate filename
raw_cellarray = {event_id score_string station_id locality coord_string};
data_name = strjoin(raw_cellarray(~cellfun(@isempty,raw_cellarray)),'_');
data_name = matlab.lang.makeValidName(data_name);

end

