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
%       success (logical): True if the configuration was successfully updated, false otherwise.
%
%   Behavior:
%       - Loads the configuration data from 'user_config.mat' if it exists, otherwise initializes an empty struct.
%       - Checks if the variable 'varname' already exists. If it does, it verifies that the new 'value' has the same class as the existing value.
%       - If 'varname' does not exist, it prompts the user to confirm creation of a new configuration variable.
%       - Updates the configuration struct with the new value.
%       - Saves a backup of the original configuration file before saving the updated configuration to 'user_config.mat'.
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
    success = false;
    return; % Exit if no config is loaded
end

if nargin < 2 || ~ischar(varname)
    logformat('Invalid input: varname must be a string and value must be provided.','ERROR');
    success = false;
    return; % Exit on invalid input
end

% Get the previous config value
try
    previous_value = ref_config.(varname);
    logformat(['Previous value of ' varname ': ' mat2str(previous_value)],'WARN'); % Display previous value

catch
    logformat(['No value previously configured for ' varname '.'],'WARN');

    % Query the user to proceed with new config variable
    response = input(['Create new config variable ''' varname '''? (y/n): '], 's');
    if ~strcmpi(response, 'y')
        logformat(['Creation of ''' varname ''' cancelled by user.'],'INFO');
        success = false;
        return; % Exit if user cancels
    end
    previous_value = []; % Set previous_value to empty if it didn't exist.
end

% Compare class of previous value
if ~isempty(previous_value) && ~isa(value, class(previous_value))
    logformat(['Class mismatch for ''' varname '''. Expected ' class(previous_value) ', got ' class(value) '.'],'ERROR');
    success = false;
    return; % Exit if class mismatch
end

% Check if new value is the same as previous value.
if ~isempty(previous_value) && isequal(previous_value, value)
    logformat(['New value is the same as the previous value for ''' varname '''. No changes made.'],'WARN');
    success = true; % No change
    return;
end

% Review the change
logformat(['Proposed new value of ''' varname ''' is: ' mat2str(value)],'WARN'); % Display proposed value

response = input(['Proceed with change? (y/n): '], 's');
if ~strcmpi(response, 'y')
    logformat(['Change to ''' varname ''' cancelled by user.'],'USER');
    success = false;
    return; % Exit if user cancels
end

% Update the local struct
ref_config.(varname) = value;

% Save the config file
try
    % Create backup file
    config_file = [getSession('folders','mainfolder') filesep 'user' filesep 'user_config.mat'];
    [filepath, filename, ext] = fileparts(config_file);
    backup_file = [filepath filesep filename '_backup' datestr(now, 'YYYYMMDD') ext]; % Corrected line
    if exist(config_file, 'file')
        copyfile(config_file, backup_file);
        logformat(['Backup of ' config_file ' created as ' backup_file],'INFO');
    else
        success = false;
        logformat('Could not create backup. No changes made.','ERROR');
        return; % Exit if backup fails
    end

    % Save the changes to the config file
    % Unpack the ref_config struct and store each field as an independent variable in user_config.mat
    save(config_file, '-struct', 'ref_config');

    % Log the success
    success = true;
    logformat([varname ' successfully updated.'],'INFO');

catch
    logformat('Configuration data update FAILED.','ERROR');
    success = false;
end
end