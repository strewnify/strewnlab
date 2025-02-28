function [success] = setConfig(varname, value)
% SETCONFIG Set a config value
%
%   setConfig(varname, value) sets the configuration variable 'varname' to 'value'.
%
%   Inputs:
%       varname (string): The name of the configuration variable to set.
%       value (any): The value to assign to the configuration variable.
%
%   Outputs:
%       cfg_value (any): The previous value of the configuration variable, or empty if it didn't exist.
%
%   Behavior:
%       - Loads the configuration data from 'user_config.mat' if it exists, otherwise initializes an empty struct.
%       - Checks if the variable 'varname' already exists. If it does, it verifies that the new 'value' has the same class as the existing value.
%       - If 'varname' does not exist, it prompts the user to confirm creation of a new configuration variable.
%       - Updates the configuration struct with the new value.
%       - Saves the updated configuration to 'user_config.mat'.
%       - Logs messages for success, warnings, and errors.
%
%   Example:
%       setConfig('display_mode', 'full');
%       setConfig('threshold', 0.8);

% Initialize
import_ref_data;

% Import config data
global ref_config;

% Check for missing initialization
if isempty(ref_config)
    logformat('Configuration not loaded, UNKNOWN ERROR.','ERROR');
    return; % Exit if no config is loaded
end

if nargin < 2 || ~ischar(varname)
    logformat('Invalid input: varname must be a string and value must be provided.','ERROR');
    return; % Exit on invalid input
end

% Get the previous config value
try
    previous_value = ref_config.(varname);
    logformat(['Previous value of ' varname ': ' previous_value],'WARN');
    
catch
    logformat(['No value previously configured for ' varname '.'],'WARN');

    % Query the user to proceed with new config variable
    response = input(['Create new config variable ''' varname '''? (y/n): '], 's');
    if ~strcmpi(response, 'y')
        logformat(['Creation of ''' varname ''' cancelled by user.'],'INFO');
        cfg_value = [];
        return; % Exit if user cancels
    end
    previous_value = []; % Set previous_value to empty if it didn't exist.
end

% Compare class of previous value
if ~isempty(previous_value) && ~isa(value, class(previous_value))
    logformat(['Class mismatch for ''' varname '''. Expected ' class(previous_value) ', got ' class(value) '.'],'ERROR');
    cfg_value = previous_value; % return the previous value
    return; % Exit if class mismatch
end

% Review the change
logformat(['Proposed new value of ''' varname ''' is: ' value ' previous_value],'WARN');
response = input(['Proceed with change? (y/n): '], 's');
    if ~strcmpi(response, 'y')
        logformat(['Creation of ''' varname ''' cancelled by user.'],'USER');
        cfg_value = [];
        return; % Exit if user cancels
    end

% Update the local struct
ref_config.(varname) = value;

Save the config file
try
    % Unpack the ref_config struct and store each field as an independent variable in user_config.mat
    save('user_config.mat', '-struct', 'ref_config');
    
    % Log the success
    success = true;
    logformat([varname 'successfully updated.'],'INFO');

catch
    logformat('Configuration data update FAILED.','ERROR');
end