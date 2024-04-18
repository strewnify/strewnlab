function [score, data_name] = scoresensor( sensorLAT, sensorLONG, sensorAlt_m, startLAT, startLONG, startAlt_m, endLAT, endLONG, endAlt_m, locality, event_id, station_id, sensorAZ, horFOV, sensorELEV, vertFOV, BaseScore)
%SCORESENSOR Scores a sensor observation and generates a data filename.

defaultFOV = 180;

% Input checking
if nargin < 9
    logformat('First 9 inputs are required.','ERROR')
elseif nargin == 9 || isempty(locality)
    [ location_string, locality, state, country, water_string, land_string ] = getlocation(sensorLAT,sensorLONG);
    if isempty(locality) && ~isempty(water_string)
        locality = water_string;
    end
    logformat(sprintf('Locality not provided, Google query returned %s',locality),'INFO')
end
if nargin <= 10
    logformat('EventID not provided.','INFO')
    event_id = '';    
end
if nargin <= 11
       logformat(sprintf('Unknown station reporting from %s.',locality),'INFO')
       station_id = ['SCX' encodelocation(sensorLAT,sensorLONG)];
end
if nargin <= 12
    logformat('Unknown sensor azimuth.','INFO')
    sensorAZ = NaN;
end
if nargin <= 13
    logformat(sprintf('Unknown sensor FOV, defaulting to %0.0f.',defaultFOV),'INFO')
    horFOV = defaultFOV;
end
if nargin <= 14
    logformat('Unknown sensor pointing ELEV.','INFO')
    sensorELEV = NaN;
end
if nargin <= 15
    logformat(sprintf('Unknown sensor vertical FOV, defaulting to %0.0f.',defaultFOV),'INFO')
    VertFOV = defaultFOV;
end

% Load ellipsoid
planet = getPlanet();

% Calculate vectors and field of view
[PathCurveDist_m, PathBearingAZ] = distance(startLAT,startLONG,endLAT,endLONG,getPlanet('ellipsoid_m'));
%[startCurveDist_m, startObservedAZ] = distance(sensorLAT,sensorLONG,startLAT,startLONG,getPlanet('ellipsoid_m'));
%[endCurveDist_m, endObservedAZ] = distance(sensorLAT,sensorLONG,endLAT,endLONG,getPlanet('ellipsoid_m'));
[startObservedAZ, startObservedELEV, startRange_m] = geodetic2aer(startLAT, startLONG, startAlt_m, sensorLAT, sensorLONG, sensorAlt_m, getPlanet('ellipsoid_m'));
[endObservedAZ, endObservedELEV, endRange_m] = geodetic2aer(endLAT, endLONG, endAlt_m, sensorLAT, sensorLONG, sensorAlt_m, getPlanet('ellipsoid_m'));

startCurveDist_km = startRange_m ./ 1000;
endCurveDist_km = endRange_m ./ 1000;
minAZ = wrapTo360(sensorAZ - horFOV./2);
maxAZ = wrapTo360(sensorAZ + horFOV./2);
minELEV = wrapTo180(sensorELEV - vertFOV./2);
maxELEV = wrapTo180(sensorELEV + vertFOV./2);
startHorFOVposition_pct = pctHorFOV(minAZ, maxAZ, startObservedAZ);
endHorFOVposition_pct = pctHorFOV(minAZ, maxAZ, endObservedAZ);
startVertFOVposition_pct = pctVertFOV(minELEV, maxELEV, startObservedELEV);
endVertFOVposition_pct = pctVertFOV(minELEV, maxELEV, endObservedELEV);

% default position for missing FOV
startHorFOVposition_pct(isnan(startHorFOVposition_pct)) = 25;
endHorFOVposition_pct(isnan(endHorFOVposition_pct)) = 25;
startVertFOVposition_pct(isnan(startVertFOVposition_pct)) = 25;
endVertFOVposition_pct(isnan(endVertFOVposition_pct)) = 25;

% Score sensor positioning for event
startScore = 70*exp(-0.006*startCurveDist_km);
endScore = 70*exp(-0.006*endCurveDist_km);
startHorMult = 38.14/(abs(startHorFOVposition_pct-50)+19.07);
endHorMult = 38.14/(abs(endHorFOVposition_pct-50)+19.07);
startVertMult = 38.14/(abs(startVertFOVposition_pct-50)+19.07);
endVertMult = 38.14/(abs(endVertFOVposition_pct-50)+19.07);

% Default invalid multipliers to 1
BaseScoreMult = BaseScore./50;
startHorMult(isnan(startHorMult)) = 1;
endHorMult(isnan(endHorMult)) = 1;
startVertMult(isnan(startHorMult)) = 1;
endVertMult(isnan(endHorMult)) = 1;

% Score sensor based on perspective view angle
startAngle = wrapTo180(startObservedAZ - PathBearingAZ);
endAngle = wrapTo180(endObservedAZ - PathBearingAZ);
startAngMult = 1 + abs(cosd(2*startAngle));
endAngMult = 1 + abs(cosd(2*endAngle));

% Calculate final sensor score
score = BaseScoreMult.*(startScore.*startHorMult.*startVertMult.*startAngMult + endScore.*endHorMult.*endVertMult.*endAngMult);
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

