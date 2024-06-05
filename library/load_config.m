function load_config
% LOAD_CONFIG Load configuration data
% This function uses verious methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.


% Initialize global variable
% Any existing data will be overwritten
global ref_config
if isempty(ref_config)
    ref_config = struct;
end

% Log initialization
if isfield(ref_config,'loaded') && ref_config.loaded
    logformat('Reloading configuration data...','INFO')
else
    logformat('Loading configuration data...','INFO')
end
ref_config.loaded = false;

% While loading, loading is incomplete
ref_config.loaded = false;

% Load user data
ref_config = load('user_data.mat');

% Log temporary code fix, need to improve this function
logformat('User data loaded from temporary file.  Need fix.','DEBUG')

% Configuration loading complete
ref_config.loaded = true;
logformat('Configuration data loaded successfully.','INFO')