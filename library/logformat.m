function logformat(yourMsg, type)
%logformat Generates a log file prefix and display log message, if diary
%is turned on

% Default type
if nargin == 1
    type = 'INFO';
end

% Ignore case on type
type = upper(type);

% Check for error
iserror = strcmp(type,'ERROR');

% Only run this function if diary is on or if there is an error 
% (and crash is happening anyway, below)
if strcmp(get(0,'Diary'),'on') || ~exist('logging','var') || logging || iserror

    [ST, ~] = dbstack('-completenames', 1);
    if isempty(ST) % main console call
        callingfunction = char.empty;
    else
        callingfunction = upper([ST(1).name ' | ']);
    end
    
    % Convert strings to chars
    yourMsg = convertStringsToChars(yourMsg);
    
    yourMsg = [callingfunction yourMsg];

    % Capture current time
    nowstring = datestr(datetime('now','TimeZone','UTC'),'yyyy-mm-ddTHH:MM:ssZ');

    % Check log entry type
    validTypes = [{'ERROR'} {'WARN'} {'DEBUG'} {'EMAIL'} {'USER'} {'DATABASE'} {'DATA'} {'INFO'} {'SYSTEM'}];
    rank = find(matches(validTypes,type,'IgnoreCase',true));

    % Add debug log for unknown log type
    if isempty(rank)
        fprintf('%s | DEBUG | LOGFORMAT | Unknown log type %s. Logging output to DEBUG below.\n', nowstring, type );
        LogType = 'DEBUG';
    else
        LogType = validTypes{rank};
    end

    fprintf('%s | %s | %s\n', nowstring,LogType, yourMsg)
end

% If type is ERROR, crash
if iserror
    
    % Stop logging
    diary off
        
    % Close waitbars
    close(findall(0,'type','figure','tag','TMWWaitbar'))
    
    % Crash program with error
    error(yourMsg)
end

