function strewn_initialize
% Initialize the  workspace

global initialized 

ellipsoid_unit = 'meters';

% if the variable is new, init to false
if isempty(initialized)
    initialized = false;
end

% Only initialize, if not done this session
if ~initialized

    % Initialize settings
    datetime.setDefaultFormats('defaultdate','yyyy-MM-dd HH:mm:ss');
          
    % Define planet data
    global planet_data
    planet_data = struct;
    planet_data.mass_kg = 5.972*10^24; % mass of Earth in kg
    planet_data.min_ground_m = -420; % lowest ground elevation on earth
    planet_data.max_ground_m = 8849; % highest ground elevation on earth
    planet_data.sidereal_period_s = 86164.0905; % sidereal period of earth, in seconds (23 h 56 min 4.0905 s or 23.9344696 h)
    planet_data.ellipsoid_m = referenceEllipsoid('earth',ellipsoid_unit);  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units

    % Log output
    logformat(['Planet initialized to Earth.  Ellipsoid units are in ' ellipsoid_unit '.'],'INFO')
    logformat('StrewnLAB initialization complete.','INFO')
    
    % Set initialization complete
    initialized = true;
end

