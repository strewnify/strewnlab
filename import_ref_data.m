% IMPORT_REF_DATA Load reference data to the workspace
% If reference data is not available load it

% Get session data
global ref_session
if isempty(ref_session)
    load_session
end

% Get user config data
global ref_config
if isempty(ref_config)
    load_config
end

% Get planet data
global ref_planet
if isempty(ref_planet)
    
    % Load the planet specified by the user config
    load_planet(getConfig('planet'));
end


