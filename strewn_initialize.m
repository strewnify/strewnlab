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
          
    % Initialize globals
    global ref_data
    global planet_data
    
    % Load reference data
    ref_data = load('ref_data.mat');
    planet_data = load('earth_data.mat');
    
    % Calculate derived planet data
    planet_data.ellipsoid_m = referenceEllipsoid('earth',ellipsoid_unit);  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
    planet_data.angular_vel_rps = 2 * pi / planet_data.sidereal_period_s;
    
    % Log output
    logformat(['Planet initialized to Earth.  Ellipsoid units are in ' ellipsoid_unit '.'],'INFO')
    logformat('StrewnLAB initialization complete.','INFO')
    
    % Set initialization complete
    initialized = true;
end

