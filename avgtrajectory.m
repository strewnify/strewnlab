% AVGTRAJECTORY  Generate average trajectory parameters, for meteors with
% unknown trajectory.

planet = getPlanet();
planet_rad_km = planet.radius_m / 1000;

% generate randomly distributed polar coordinate points inside a circle
% credit to aioobe on stack overflow, for his elegant solution
numpoints = 10000000;
r = planet_rad_km.*sqrt(rand(numpoints,1));
theta = 2.*pi.*(rand(numpoints,1));
x = r.*cos(theta);
y = r.*sin(theta);

incidence_angle = abs(rad2deg(asin(r/planet_rad_km)));
histogram(incidence_angle,100)
hold on

test_r = 90.*betarnd(2.15,2.15,numpoints,1);
histogram(test_r,100)
