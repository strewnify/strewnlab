function load_planet(planet_name)
% LOAD_PLANET Load planet data to workspace

% DO NOT change units
ellipsoid_unit = 'meters';

% Initialize global variable
global ref_planet
if isempty(ref_planet)
    ref_planet = struct;
end

% Log initialization
if isfield(ref_planet,'loaded') && ref_planet.loaded
    logformat('Loading new planet data...','INFO')
else
    logformat('Loading planet data...','INFO')
end
ref_planet.loaded = false;

% While loading, loading is incomplete
ref_planet.loaded = false;

switch lower(planet_name)
    case 'earth'
        ref_planet = load('earth_data.mat');
    otherwise
        logformat(['Planet data not found for ''' planet_name ''''],'ERROR')
end

% Calculate derived planet data
ref_planet.ellipsoid_m = referenceEllipsoid('earth',ellipsoid_unit);  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
ref_planet.angular_vel_radps = 2 * pi / ref_planet.sidereal_period_s; % angular velocity in radians per second

% Planet loading complete
ref_planet.loaded = true;
logformat(['Planet data loaded for ' TitleCase(planet_name) '.  Ellipsoid units are in ' ellipsoid_unit '.'],'INFO')