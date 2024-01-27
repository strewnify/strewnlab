function load_planet(planet_name)
% LOAD_PLANET Load planet data to workspace

ellipsoid_unit = 'meters';

global ref_planet
ref_planet = struct;

switch lower(planet_name)
    case 'earth'
        ref_planet = load('earth_data.mat');
    otherwise
        logformat(['Planet data not found for ''' planet_name ''''],'ERROR')
end

% Calculate derived planet data
ref_planet.ellipsoid_m = referenceEllipsoid('earth',ellipsoid_unit);  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
ref_planet.angular_vel_radps = 2 * pi / ref_planet.sidereal_period_s; % angular velocity in radians per second
logformat(['Planet data loaded for ' TitleCase(planet_name) '.  Ellipsoid units are in ' ellipsoid_unit '.'],'INFO')