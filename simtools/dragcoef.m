function [ CD ] = dragcoef( machspeed, cubicity )
%CD = DRAGCOEF(Mach, cubicity)    Calculate the drag coefficient as a function of Mach number and
%projectile shape.  Projectile shape is characterized as "cubicity", a
%number between zero and one, where zero is a perfect sphere and one is a 
%perfect  cube.

if isnan(machspeed)||~isreal(machspeed)|| (machspeed < 0)
     error('ERROR: Mach number invalid, %d',machspeed)
elseif isnan(cubicity)||~isreal(cubicity)||(cubicity < 0)||(cubicity > 1)
     error('ERROR: Cubicity invalid, %d',cubicity)
end

% coefficient of drag estimation - sphere
if machspeed > 0.722
    CD_sphere = 2.1*exp(-1.2*(machspeed+0.35))-8.9*exp(-2.2*(machspeed+0.35))+0.92;
else
    CD_sphere = 0.45*machspeed^2+0.424;
end

% coefficient of drag estimation - cube
if machspeed > 1.15
    CD_cube = 2.1*exp(-1.16*(machspeed+0.35))-6.5*exp(-2.23*(machspeed+0.35))+1.67;
else
    CD_cube = 0.6*machspeed^2+1.04;
end
CD = cubicity*CD_cube+(1-cubicity)*CD_sphere;


end

