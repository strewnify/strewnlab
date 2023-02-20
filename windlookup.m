function [ vx, vy, vz ] = windlookup( z, windspeed_data, winddir_data, projectileheading, ground)
%force = WINDATALTITUDE( ALTITUDE, WINDSPEED, WINDDIR, PROJECTILEHEADING, GROUND)
%Provides 3-dimensional wind direction at any altitude, based on input data.  
%Input parameters include:
%altitude above sea level, in meters
%meteor direction of travel, in compass degrees
%optional: ground elevation, in meters (default is 0), purely for fault checking
    
if ~exist('ground','var')
    ground = 0;
end

if isnan(projectileheading)||~isreal(projectileheading)||(projectileheading < -360)||(projectileheading > 360)
     error('ERROR: Meteor direction invalid, %d',projectileheading)
elseif isnan(z)||~isreal(z)||(z < -430)
     error('ERROR: Altitude invalid, %d',z)
elseif isnan(ground)||~isreal(ground)||(ground < -430)
     error('ERROR: Ground elevation invalid, %d',ground)
elseif (z < ground)
     error('ERROR: Altitude must be above the ground.')
end

% Lookup data at input altitude
%windspeed = interp1(elevation_data,windspeed_data,z);
windspeed = windspeed_data(z);
if isnan(windspeed)
    error('ERROR: Wind speed invalid, %d', windspeed);
end

%winddir = interp1(elevation_data,winddir_data,z);
winddir = winddir_data(z);
if isnan(winddir)
    error('ERROR: Wind direction invalid, %d', winddir);
end

% Convert wind direction to angle from meteor bearing
angledeg = projectileheading - winddir;
    
vx = -windspeed * cos(degtorad(angledeg));
vy = -windspeed * sin(degtorad(angledeg));
vz = 0;  % this function does not currently support updrafts or downdrafts 

end

