function [ vx, vy, vz ] = windataltitude( z, windsurf, angledeg, ground, zref, exponent)
%force = WINDATALTITUDE( WINDSURF, WINDDIRECTION, ALTITUDE, GROUND, ZREF, WINDSHEAR )
%Provides 3-dimensional wind direction at any altitude, based on ground
%conditions.  Input parameters include:
%surface wind speed, in m/s
%wind direction, in counter-clockwise degrees from positive x vector
%altitude above sea level, in meters
%optional: ground elevation, in meters (default is 0)
%optional: zref is refence height for the given windspeed (default is 2)
% 
%   EXAMPLE, for projectile heading due west:
%   0 degrees is wind from the west (headwind)
%   90 degrees is wind from the south
%   180 degrees is a wind from the east (tailwind)
%   270 degrees is a wind from the north

if ~exist('zref','var')
    zref = 10;
end
    
if ~exist('ground','var')
    ground = 0;
end

if ~exist('exponent','var')
    exponent = 0.143;
end

if isnan(windsurf)||~isreal(windsurf)||(windsurf < 0)
     error('ERROR: Wind speed invalid, %d',windsurf)
elseif isnan(angledeg)||~isreal(angledeg)||(angledeg < -360)||(angledeg > 360)
     error('ERROR: Wind direction invalid, %d',angledeg)
elseif isnan(z)||~isreal(z)||(z < -430)
     error('ERROR: Altitude invalid, %d',z)
elseif isnan(ground)||~isreal(ground)||(ground < -430)
     error('ERROR: Ground elevation invalid, %d',ground)
elseif (z < ground)
     error('ERROR: Altitude must be above the ground.')
end

windspeed = windsurf * ((z-ground)/zref)^exponent;

vx = -windspeed * cos(degtorad(angledeg));
vy = -windspeed * sin(degtorad(angledeg));
vz = 0;  % this function does not currently support updrafts or downdrafts 

end

