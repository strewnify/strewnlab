function [planet] = getPlanet
%GETPLANET Get planet data, as defined at initialization
% The planet data is stored in a global struct, from the
% STREWN_INITIALIZE function.

global initialized
global planet_data

% Initialize, if necessary
if isempty(initialized) || ~initialized
    strewn_initialize
    logformat('Unexpected StrewnLAB initialization.','DEBUG')
    
% Check for unknown initialization error
elseif isempty(planet_data) ||...
        ~isfield(planet_data,'mass_kg') ||...
        ~isfield(planet_data,'radius_m') ||...
        ~isfield(planet_data,'G') ||...
        ~isfield(planet_data,'ellipsoid_m')
    logformat('Unexpected missing planet data.','ERROR')    

% Check units
elseif ~strcmp(planet_data.ellipsoid_m.LengthUnit,'meter')
    logformat('Unexpected units in planet data.','ERROR')    
end

% Store output
planet = planet_data;

end

