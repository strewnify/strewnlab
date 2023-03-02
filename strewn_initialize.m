function strewn_initialize
% Initialize the  workspace

global initialized 

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
    planet_data.G = 6.674*10^-11; % gravitational constant in m^3 kg^-1 s^-2
    planet_data.radius_m = 6371000; % radius of Earth in meters
    planet_data.mass_kg = 5.972*10^24; % mass of Earth in kg
    planet_data.ellipsoid_m = referenceEllipsoid('earth','meters');  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
    
    % Set initialization complete
    initialized = true;
end

