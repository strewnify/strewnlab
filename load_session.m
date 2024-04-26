function load_session 
% LOAD_SESSION Load session data
% This function uses various methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Required Licenses
required_licenses = {'MAP_Toolbox' 'Curve_Fitting_Toolbox' 'Statistics_Toolbox'};

% Initialize global variable
% Don't overwrite userpresent value!
global ref_session
if isempty(ref_session)
    ref_session = struct;
end

% Log initialization
if isfield(ref_session,'loaded') && ref_session.loaded
    logformat('Reloading session data...','INFO')
else
    logformat('Loading session data...','INFO')
end
ref_session.loaded = false;

% If user presence is undefined, default to user present
if ~isfield(ref_session,'state') || ~isfield(ref_session.state,'userpresent')
    ref_session.state.userpresent = true;
end

% If exporting state is undefined, default to false 
if ~isfield(ref_session,'state') || ~isfield(ref_session.state,'exporting')
    ref_session.state.exporting = false;
end

% Get operating system
try
    ref_session.env.OS = strtrim(getenv('OS'));
catch
    ref_session.env.OS = 'unknown';
end
logformat(sprintf('Operating System: %s',ref_session.env.OS),'INFO')
try
    [~,temp_ver] = system('ver');
    ref_session.env.system_ver = strtrim(temp_ver);
catch
    ref_session.env.system_ver = 'unknown';
end
logformat(sprintf('System Version: %s',ref_session.env.system_ver),'INFO')

% Get Windows username
ref_session.user.winusername = getenv('USERNAME');
logformat(sprintf('System User: %s',ref_session.user.winusername),'INFO')

% Get username for export folder naming
if ispref('strewnlab','export_username')
    ref_session.user.export_username = getpref('strewnlab','export_username');
    logformat(sprintf('Export username loaded from matlab preferences as %s.',ref_session.user.export_username),'INFO')

% First time setup
else
    if ref_session.state.userpresent
        logformat('Export username not found in MATLAB preferences. User queried for first time setup.','INFO')
        
        % prompt the user for username
        usersuccess = false;
        while ~usersuccess
            export_username = char(inputdlg('Enter a username that will be used for folder export:'));
            if isvarname(export_username)
                usersuccess = true;
            else
                warning('Invalid username.  Please enter a username, with no spaces or special characters.')
            end
        end
                
        % save to matlab preferences
        setpref('strewnlab','export_username',export_username);
        ref_session.user.export_username = getpref('strewnlab','export_username');
        
        logformat(sprintf('Export username saved to MATLAB preferences as %s.',ref_session.user.export_username),'INFO')
    else
        ref_session.user.export_username = ref_session.user.winusername;
        logformat('No user present.  Export folders will be named with windows username','DEBUG')
    end
            
    

end

% Get timezone
ref_session.env.TimeZone = datetime.SystemTimeZone;
logformat(sprintf('System Time Zone: %s',ref_session.env.TimeZone),'INFO')

try
    % get IPv4 address
    [~, result] = system('ipconfig');
    ip_delimiter = 'IPv4 Address. . . . . . . . . . . : ';
    offset = length(ip_delimiter);
    start_idx = findstr(result,ip_delimiter)+offset;

    % line break after delimiter
    line_breaks = findstr(result(start_idx:end),char(10));

    end_idx = start_idx + line_breaks(1) - 2;

    ref_session.env.ip_address = result(start_idx:end_idx);
    logformat(sprintf('IP Address: %s',ref_session.env.ip_address),'INFO')
    
catch
    ref_session.env.ip_address = char.empty;
    logformat('IP Address: unknown','DEBUG')
end

% Get monitor size
try
    %Sets the units of your root object (screen) to pixels
    set(0,'units','pixels');

    %Obtains this pixel information
    Pix_SS = get(0,'screensize');
    Pix_SS = Pix_SS(Pix_SS > 1);
    
    %Sets the units of your root object (screen) to inches
    set(0,'units','inches');

    %Obtains this inch information
    Inch_SS = get(0,'screensize');
    Inch_SS = Inch_SS(Inch_SS > 1);
    
    % Store data to output
    ref_session.env.screen_w_pix = Pix_SS(1);
    ref_session.env.screen_h_pix = Pix_SS(2);
    ref_session.env.screen_w_in = Inch_SS(1);
    ref_session.env.screen_h_in = Inch_SS(2);
    
    % Log
    logformat(sprintf('Screen Size: %g x %g | %g x %g"', ref_session.env.screen_w_pix, ref_session.env.screen_h_pix, ref_session.env.screen_w_in,  ref_session.env.screen_h_in),'INFO')
catch
    ref_session.env.screen_w_pix = NaN;
    ref_session.env.screen_h_pix = NaN;
    ref_session.env.screen_w_in = NaN;
    ref_session.env.screen_h_in = NaN;
    logformat('Screen Size: unknown','DEBUG')
end

% Get MATLAB license and version info
ref_session.MATLAB.version = version;
logformat(sprintf('MATLAB version: %s',ref_session.MATLAB.version),'INFO');

ref_session.MATLAB.lic_num = license;
logformat(sprintf('MATLAB license number: %s',ref_session.MATLAB.lic_num),'INFO');
for lic_i = 1:numel(required_licenses)
    lic_status(lic_i) = license('test',required_licenses{lic_i});
end

% Report available licenses
ref_session.MATLAB.toolboxes = required_licenses(find(lic_status));
logformat(sprintf('MATLAB licensed products: %s',strjoin(ref_session.MATLAB.toolboxes,', ')),'INFO');

% Get the installation directory
ref_session.folders.mainfolder = getinstallpath('strewnlab');
logformat(sprintf('StrewnLAB is installed at %s', ref_session.folders.mainfolder),'INFO')

% Get the main prefix for the drive, where Documents and Downloads would be found
ref_session.folders.mainprefix = [extractBefore(ref_session.folders.mainfolder,ref_session.user.winusername) ref_session.user.winusername];

% Add working directory and subfolders to search path and go to the folder
addpath(genpath(ref_session.folders.mainfolder)) 
cd(ref_session.folders.mainfolder)

% Logging folder
ref_session.folders.logfolder = [ref_session.folders.mainfolder '\logs'];

% Remote data folders
ref_session.folders.weatherfolder = [ref_session.folders.mainfolder '\local_data\radiosonde'];
if ~(exist(ref_session.folders.weatherfolder,'dir')==7)
    mkdir(ref_session.folders.weatherfolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Weather data folder %s at %s',log_msg, ref_session.folders.weatherfolder),'INFO')

ref_session.folders.remotefolder = [ref_session.folders.mainfolder '\local_data\remote'];
if ~(exist(ref_session.folders.remotefolder,'dir')==7)
    mkdir(ref_session.folders.remotefolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Remote data folder %s at %s',log_msg, ref_session.folders.remotefolder),'INFO')

% Working folder
ref_session.folders.workingfolder = [ref_session.folders.mainfolder '\working'];
if ~(exist(ref_session.folders.workingfolder,'dir')==7)
    mkdir(ref_session.folders.workingfolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Working data folder %s at %s',log_msg, ref_session.folders.workingfolder),'INFO')

% Meteor events folder
ref_session.folders.meteoreventsfolder = [ref_session.folders.mainprefix '\Documents\NextCloud\StrewnifySync\Meteor Events'];
logformat(sprintf('Meteor events folder located at %s', ref_session.folders.meteoreventsfolder),'INFO')
ref_session.folders.secreteventsfolder = [ref_session.folders.mainprefix '\Documents\NextCloud\StrewnifySync\Meteor Events CONFIDENTIAL'];
logformat(sprintf('Confidential meteor events folder located at %s', ref_session.folders.secreteventsfolder),'INFO')

% Automated event script folder
ref_session.folders.scheduledfolder = [ref_session.folders.mainfolder '\scheduled'];
if ~(exist(ref_session.folders.scheduledfolder,'dir')==7)
    mkdir(ref_session.folders.scheduledfolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Automated data collection folder %s at %s',log_msg, ref_session.folders.scheduledfolder),'INFO')

% Backup folder
ref_session.folders.backupfolder = [ref_session.folders.mainfolder '\backup'];
if ~(exist(ref_session.folders.backupfolder,'dir')==7)
    mkdir(ref_session.folders.backupfolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Backup folder %s at %s',log_msg, ref_session.folders.backupfolder),'INFO')

% Data folder
ref_session.folders.datafolder = [ref_session.folders.mainfolder '\local_data'];
if ~(exist(ref_session.folders.datafolder,'dir')==7)
    mkdir(ref_session.folders.datafolder) % create folder
    log_msg = 'created';
else
    log_msg = 'found';
end
logformat(sprintf('Import data folder %s at %s',log_msg, ref_session.folders.datafolder),'INFO')

% Set default time & date format
time_format_config = 'yyyy-MM-dd HH:mm:ss z';
datetime.setDefaultFormats('default',time_format_config);
logformat(sprintf('Default date/time format set to %s',time_format_config),'INFO')

% Get user role
if ref_session.state.userpresent
    quest = ['Please Select a User Role:' newline newline 'Standard - Effortless success with the usual settings' newline ...
        'Advanced - Extra choices for users with understanding of physics and statistics' newline ...
        'Developer - Does not enhance simulation results, additional credentials required for website administration' newline newline];
    roles = ["Standard","Advanced","Developer"];

    % Get user role, saving preferences to matlab preferences
    logformat('User queried for role preference.','USER')
    [user_role,~] = uigetpref('strewnlab_uigetpref','role_pref','Choose User Role',quest,roles);
    
    
% if no userpresent, set to developor (for scheduled scripts)
else
    user_role = 'developer';
    logformat('User not present at console, user role defaulted to ''developer''.','USER')
end


% *** Credential Loading ***
% Check for saved credentials
% Sensitive information like passwords and API keys are saved to a
% preferences file called matlabprefs.mat, which is typically
% located in this folder:
% C:\Users\<username>\AppData\Roaming\MathWorks\MATLAB\R20xxx\

% load private preferences
logformat(['Loading credentials from ' prefdir '\matlabprefs.mat...'],'INFO');
strewnlab_private = getpref('strewnlab_private');

% If no credentials found, query user
if isempty(strewnlab_private) || isempty(fieldnames(strewnlab_private))
    logformat(['No credentials found at ' prefdir '\matlabprefs.mat.'],'WARN');
    get_creds = true;

    % Setup credential query, based on user role
    switch user_role
        case 'developer'
            creds = {'AMS_APIkey' 'Mailchimp_APIkey' 'Strewnify_APIkey' 'strewnlab_emailpassword' 'GoogleFormsCam_key' 'GoogleMapsAPIkey' 'GoogleDrive_NotifyResponses'};
        case 'advanced'
            creds = {'GoogleMapsAPIkey'};
        otherwise
            get_creds = false;
    end

    % Query user for credentials
    if get_creds
       for cred_i = 1:numel(creds)
           [~] = getPrivate(creds{cred_i}); % save value, do not log
       end

    % Load the new preferences
    strewnlab_private = getpref('strewnlab_private');

    else
       logformat([user_role ' user skipped credential setup.'],'USER')
    end   
else
    % Set environment variables
    private_var = fieldnames(strewnlab_private);
    for private_i = 1:numel(private_var)
        var_name = private_var{private_i};            
        var_value = strewnlab_private.(private_var{private_i}){1};
        logformat([var_name ' loaded from ' prefdir '\matlabprefs.mat.'],'INFO')
    end
end

% Session loading complete
ref_session.loaded = true;
logformat('Session data loaded successfully.','INFO')