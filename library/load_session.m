function load_session 
% LOAD_SESSION Load session data
% This function uses verious methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Log initialization
logformat('Loading session data...','INFO')

% Initialize global variable
% Any existing data will be overwritten
global ref_session
ref_session = struct;

% default user present
ref_session.user.userpresent = true;

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
ref_session.license.lic_num = license;
logformat(sprintf('MATLAB license number: %s',ref_session.license.lic_num),'INFO');
temp_license_inuse = license('inuse');
ref_session.license.toolboxes = {temp_license_inuse.feature};
logformat(sprintf('MATLAB licensed products: %s',strjoin(ref_session.license.toolboxes,', ')),'INFO');


% Get the installation directory
ref_session.folders.mainfolder = getinstallpath('strewnlab');

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

% Log 
logformat('Session data loaded to global workspace.','INFO')