function [ellipseLAT, ellipseLON] = strewnellipse(strewnLAT,strewnLON, AZ, percentile)
%STREWNELLIPSE fits an ellipse to cover a fractional percentile of the strewn data.

%draft, will be used to calculate strewn field area

lat0 = mean(LAT);
lon0 = mean(LON);
semimajor = 0.005;
numpoints = 

while numpoints 
[ellipseLAT,ellipseLON] = ellipse1(lat0,lon0,[semimajor,eccentricity],AZ);

% Find points inside ellipse
(strewnLAT-xo)^2/a + (y-yo)^2/b +(z-zo)^2/c < 1
scatter(ellipseLAT,ellipseLON)
area = areaint(ellipseLAT,ellipseLON,earthRadius)

end

