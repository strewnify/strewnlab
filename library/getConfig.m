function [cfg_value] = getConfig(varname)
%GETREF Get config data, as defined at initialization
% The reference data is stored in a global struct, from the
% LOAD_CONFIG function.

% Import config data
global ref_config

% Check for missing initialization
if isempty(ref_config)      
    logformat('Configuration not loaded, run IMPORT_REF_DATA.','ERROR')    
else

    % Store output
    if nargin == 0
        cfg_value = ref_config;
    else
        cfg_value = ref_config.(varname);
    end
end