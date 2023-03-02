function [data] = nearbysensors(LAT,LONG,Height_km,database)
%[DATA] = NEARBYSENSORS(LAT,LON, HEIGHT_KM, DATABASE) Find all sensors in range of a 3D location

warning('input height not used')
planet = getPlanet();

database.curveDistance_km = distance(LAT,LONG,database.LAT,database.LONG,planet.ellipsoid_m)./1000;
database.PctSensorRange = database.curveDistance_km ./ database.range_km .* 100;

% filter sensors in range
data = database(database.PctSensorRange < 100,:);

% Sort the data, ascending by sensor range, then by type
data = sortrows(data,["Type","PctSensorRange"],'ascend');


