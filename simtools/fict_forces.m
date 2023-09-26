function [force_N] = fict_forces(object_mass_kg,  position_m, velocity_mps)
%FICT_FORCES Calculate fictitious forces for an object on a rotating planet. 
%
% [FORCE_N] = fict_forces(OBJECT_MASS_KG,  POSITION_M, VELOCITY_MPS)
% calculates the vector sum of Coriolis and centrifugal forces.  The Euler 
% force is not included, because planetary rotation is constant. 

% FORCE_N - vector sum of the physical forces acting on the object.
% POSITION_M - position vector of the object relative to the rotating
% reference frame, in meters (ECEF coordinates for earth)
% VELOCITY_MPS - velocity of the object relative to the rotating reference 
% frame, in meters per second
%
% Angular velocity of the planet is derived from data defined at
% initialization by STREWNINITIALIZE

% Check mass input
if length(object_mass_kg) > 1 || object_mass_kg < 0
    logformat('Mass input must be a positive scalar input.','ERROR')
    
end

% Check array inputs
if ~(isvector(position_m) &&...
        isvector(velocity_mps) &&...
        length(position_m) == 3 &&...
        length(velocity_mps) == 3)
    
    logformat('Position and velocity inputs must be 3D vectors in the ECEF rotating reference frame.','ERROR')
end

% et rotational planet data
planet = getPlanet();
angular_vel_rps = [0 0 planet.angular_vel_rps]; % need to size same as input...

% Calculate and sum fictitious forces
% (The Euler force is not included, because planetary rotation is constant)
coriolis_force_N = -2 .* object_mass_kg .* cross(angular_vel_rps, velocity_mps);
centrifugal_force_N = -cross(object_mass_kg .* angular_vel_rps, cross(angular_vel_rps, position_m));
force_N = coriolis_force_N + centrifugal_force_N;

end

