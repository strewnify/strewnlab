function load_config
% LOAD_CONFIG Load configuration data
% This function loads user config from file.
% TBD - all config variables need to reviewed and updated to the new
% ref_config.XXX format, and then STREWNCONFIG can be removed from the
% code.

% Initialize global variable
% Any existing data will be overwritten
global ref_config
if isempty(ref_config)
    ref_config = struct;
end

% Log initialization
if isfield(ref_config,'loaded') && ref_config.loaded
    logformat('Reloading event data...','INFO')
else
    logformat('Loading configuration data...','INFO')
end
ref_config.loaded = false;

% While loading, loading is incomplete
ref_config.loaded = false;

% Load user data
ref_config = load('user_config.mat');

% Configuration loading complete
ref_config.loaded = true;
logformat('Configuration data loaded successfully.','INFO')