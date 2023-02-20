% AVGTRAJECTORY  Generate average trajectory parameters, for meteors with
% unknown trajectory.

earth_rad = earthRadius('km');

% generate randomly distributed polar coordinate points inside a circle
% credit to aioobe on stack overflow, for his elegant solution
numpoints = 10000000;
r = earth_rad.*sqrt(rand(numpoints,1));
theta = 2.*pi.*(rand(numpoints,1));
x = r.*cos(theta);
y = r.*sin(theta);

incidence_angle = abs(rad2deg(asin(r/earth_rad)));
histogram(incidence_angle,100)
hold on

test_r = 90.*betarnd(2.15,2.15,numpoints,1);
histogram(test_r,100)
