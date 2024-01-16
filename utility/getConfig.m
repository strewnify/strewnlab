function [cfg_value] = getConfig(group, varname)
%GETREF Get config data, as defined at initialization
% The reference data is stored in a global struct, from the
% STREWN_INITIALIZE function.

global initialized
global ref_config

% Initialize, if necessary
if isempty(initialized) || ~initialized
    strewn_initialize
    logformat('Unexpected StrewnLAB initialization.','DEBUG')
    
% Check for unknown initialization error
elseif isempty(ref_config) || ~isfield(ref_config,'simulation')        
    logformat('Unexpected missing config data.','ERROR')    
end

% Store output
if nargin == 0
    cfg_value = ref_config;
else
    cfg_value = ref_data.(group).(varname);
end

