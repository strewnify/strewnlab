function load_config
% LOAD_SESSION Load session data
% This function uses verious methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Log initialization
logformat('Loading user configuration data...','INFO')

% Initialize global variable
% Any existing data will be overwritten
global ref_config
ref_config = struct;

% Load user data
ref_config = load('user_data.mat');

% Log temporary code fix, need to improve this function
logformat('User data loaded from temporary file.  Need fix.','DEBUG')