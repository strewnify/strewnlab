function [planet_data] = getPlanet(varname)
%GETPLANET Get planet data, as defined at initialization
% The planet data is stored in a global struct, from the
% STREWN_INITIALIZE function.

global ref_planet

% Check for missing initialization
if isempty(ref_planet)      
    logformat('Configuration not loaded, run IMPORT_REF_DATA.','ERROR')    
end

% Store output
if nargin == 0
    planet_data = ref_planet;
else
    planet_data = ref_planet.(varname);
end