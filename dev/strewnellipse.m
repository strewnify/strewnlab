function [ellipseLAT, ellipseLON] = strewnellipse(strewnLAT,strewnLON, AZ, percentile)
%STREWNELLIPSE fits an ellipse to cover a fractional percentile of the strewn data.

% This function is in development...

% Define planet
planet = getPlanet();

%draft, will be used to calculate strewn field area

lat0 = mean(strewnLAT);
lon0 = mean(strewnLON);
lat_min = min(strewnLAT);
lat_max = max(strewnLAT);
lon_min = min(strewnLON);
lon_max = max(strewnLON);

semimajor = distance(lat_min,lon_min,lat_max,lon_max,planet.ellipsoid_m)/2;
eccentricity = 0.99;

gx = geoaxes('Basemap','satellite');
hold on

numpoints = zeros(1,359);

% Rotate the ellipse for initial solution
for AZ = 1:359
[ellipseLAT,ellipseLON] = ellipse1(lat0,lon0,[semimajor,eccentricity],AZ,360,planet.ellipsoid_m);

numpoints(AZ) = nnz(inpolygon(strewnLAT,strewnLON,ellipseLAT,ellipseLON));

end

AZ = find(numpoints == max(numpoints),1);
[ellipseLAT,ellipseLON] = ellipse1(lat0,lon0,[semimajor,eccentricity],AZ,360,planet.ellipsoid_m);

% Plot the ellipse
geoplot(gx,ellipseLAT,ellipseLON)
geoscatter(gx,strewnLAT,strewnLON,'.y')

%area = areaint(ellipseLAT,ellipseLON,planet.ellipsoid_m.MeanRadius)

