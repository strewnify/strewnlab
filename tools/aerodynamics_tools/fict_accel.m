function [accel_mps2] = fict_accel(position_m, velocity_mps)
%FICT_ACCELERATION Calculate fictitious accelerations (Coriolis and centrifugal)
%  for an object on a rotating planet.
%
%  [ACCEL_MPS2] = fict_acceleration(POSITION_M, VELOCITY_MPS)
%  calculates the vector sum of Coriolis and centrifugal accelerations.
%  Euler acceleration is not included, assuming constant angular velocity.
%
%  POSITION_M - 3x1 position vector in rotating reference frame (meters)
%  VELOCITY_MPS - 3x1 velocity vector in rotating reference frame (m/s)
%
%  ACCEL_MPS2 - 3x1 acceleration vector in m/s^2

% Check inputs
if ~(isvector(position_m) && length(position_m) == 3 && isnumeric(position_m))
    error('Position input must be a numeric 3-element vector.');
end

if ~(isvector(velocity_mps) && length(velocity_mps) == 3 && isnumeric(velocity_mps))
    error('Velocity input must be a numeric 3-element vector.');
end

% Get planet angular velocity (rad/s), assumed along Z axis
omega = getPlanet('angular_vel_radps'); 
angular_vel_radps = [0 0 omega];

% Coriolis acceleration: -2 (omega x velocity)
coriolis_accel = -2 * cross(angular_vel_radps, velocity_mps);

% Centrifugal acceleration: - omega x (omega x position)
centrifugal_accel = -cross(angular_vel_radps, cross(angular_vel_radps, position_m));

% Total fictitious acceleration
accel_mps2 = coriolis_accel + centrifugal_accel;

end