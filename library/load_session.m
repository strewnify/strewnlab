function load_session 
% LOAD_SESSION Load session data
% This function uses verious methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Log initialization
logformat('Loading session and user environment data...','INFO')

% Initialize global variable
% Any existing data will be overwritten
global ref_session
ref_session = struct;

% Get Windows username
ref_session.user.winusername = getenv('USERNAME');

% default user present
ref_session.user.userpresent = true;

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
end
ref_session.folders.remotefolder = [ref_session.folders.mainfolder '\local_data\remote'];
if ~(exist(ref_session.folders.remotefolder,'dir')==7)
    mkdir(ref_session.folders.remotefolder) % create folder
end

% Meteor events folder
ref_session.folders.meteoreventsfolder = [ref_session.folders.mainprefix '\Documents\NextCloud\StrewnifySync\Meteor Events'];
ref_session.folders.secreteventsfolder = [ref_session.folders.mainprefix '\Documents\NextCloud\StrewnifySync\Meteor Events CONFIDENTIAL'];

% Automated event script folder
ref_session.folders.scheduledfolder = [ref_session.folders.mainfolder '\scheduled'];
if ~(exist(ref_session.folders.scheduledfolder,'dir')==7)
    mkdir(ref_session.folders.scheduledfolder) % create folder
end

% Backup folder
ref_session.folders.backupfolder = [ref_session.folders.mainfolder '\backup'];
if ~(exist(ref_session.folders.backupfolder,'dir')==7)
    mkdir(ref_session.folders.backupfolder) % create folder
end

% Data folder
ref_session.folders.datafolder = [ref_session.folders.mainfolder '\local_data'];
if ~(exist(ref_session.folders.datafolder,'dir')==7)
    mkdir(ref_session.folders.datafolder) % create folder
end

% Get timezone
ref_session.env.TimeZone = datetime.SystemTimeZone;

% Get operating system
try
    ref_session.env.systeminfo.OS = getenv('OS');
catch
    ref_session.env.systeminfo.OS = 'unknown';
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
    ref_session.env.systeminfo.screen_w_pix = Pix_SS(1);
    ref_session.env.systeminfo.screen_h_pix = Pix_SS(2);
    ref_session.env.systeminfo.screen_w_in = Inch_SS(1);
    ref_session.env.systeminfo.screen_h_in = Inch_SS(2);
%     ref_session.env.systeminfo.
    
end

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
end

% Log temporary code fix, need to improve this function
% Need more logging of data in this function
logformat('Session data loaded from temporary file.  Need fix.','DEBUG')