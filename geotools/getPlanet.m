function [planet_data] = getPlanet(varname)
%GETPLANET Get planet data, as defined at initialization
% The planet data is stored in a global struct, from the
% STREWN_INITIALIZE function.

global initialized
global ref_planet

% Initialize, if necessary
if isempty(initialized) || ~initialized
    strewn_initialize
    logformat('Unexpected StrewnLAB initialization.','DEBUG')
    
% Check for unknown initialization error
elseif isempty(ref_planet) ||...
        ~isfield(ref_planet,'mass_kg') ||...
        ~isfield(ref_planet,'ellipsoid_m')
    logformat('Unexpected missing planet data.','ERROR')    

% Check units
elseif ~strcmp(ref_planet.ellipsoid_m.LengthUnit,'meter')
    logformat('Unexpected units in planet data.','ERROR')    
end

% Store output
if nargin == 0
    planet_data = ref_planet;
else
    planet_data = ref_planet.(varname);
end