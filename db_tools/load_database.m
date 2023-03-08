%LOAD_DATABASE Backup the database and load it into the workspace

% BEFORE INTEGRATING INTO SCHEDULED SCRIPT, REMOVE USER INPUT DIALOGS

% DO NOT RUN STREWNCONFIG IN THIS FILE, IT CAN OVERWRITE DEVELOPMENT DATABASE NAMES

% if strewnconfig has not been called, error
if ~exist('check_configloaded','var') || ~check_configloaded
    error('Config file not loaded')
end
    
% Logging option
if strcmp(get(0,'Diary'),'off')
    if exist('logfolder','var')
        diary([logfolder 'database_errorlog.txt'])
    else
        diary('database_errorlog.txt')
    end
    diary on
    diaryforced_on = true;
    logformat('Unexpected call, logging forced on','DEBUG')
else
    diaryforced_on = false;
end


% Open a waitbar
handleLoadDatabase = waitbar(0,'Loading Data...');

nowtime_utc = datetime('now','TimeZone','UTC'); 
now_datestring = datestr(nowtime_utc,'yyyymmddHHMM');

usefile = true;
if exist(Database_EventData_varname,'var')
    
    % Ask for user input
    if userpresent
        user_quest = 'There is a database already loaded in memory. Which would you like to use?  (Either way, a backup will be created and no data will be lost.)';
        logformat(user_quest,'USER')
        answer = questdlg(user_quest,'Warning: Database Already Loaded','Use Database From File','Use Already Loaded Database','Cancel','Use Database From File');
    else
        answer = 'Use Already Loaded Database';
    end
    % Handle response
    switch answer
        case 'Use Database From File'
            
            %Log
            logformat('Selected to use database from file.','USER') 
                        
            % Backup the loaded database
            cd(backupfolder)
            backup_filename = [DatabaseFilename '_BACKUPWS_' now_datestring];
            save(backup_filename,Database_prefix)
            logformat(sprintf('Workspace database backed up to %s.mat file.',backup_filename),'DATABASE');
            cd(mainfolder)
            
            % clear the loaded database
            clear sdb_*
                        
        case 'Use Already Loaded Database'
            
            %Log
            logformat('Selected to use already loaded database.','USER')        
            
            usefile = false;
            
        case 'Cancel'
            logformat('User cancelled data import.','USER')        
            return
    end
end

% if the database file exists, load it
if usefile
    if isfile([DatabaseFilename '.mat'])
        
        % Load the database
        load(DatabaseFilename)
        logformat(sprintf('Data loaded from %s.mat file.',DatabaseFilename),'DATABASE');
        
        % Check for correct content
        if ~exist(Database_EventData_varname,'var')
            logformat('Database content unexpected.  Contact developer.','ERROR')    
        end
        
    % Otherwise, warn the user and create a new database
    else
        logformat(sprintf('%s not found. Unsupported exception.',[DatabaseFilename '.mat']),'ERROR')
    end
end

% Backup the event database
cd(backupfolder)
backup_filename = [DatabaseFilename '_BACKUP_' now_datestring];
save(backup_filename,Database_prefix)
logformat(sprintf('Database backed up to %s.mat file.',backup_filename),'DATABASE');
cd(mainfolder)

% Generate a flag to confirm the database is backed up
database_loaded_safe = true;

% Close waitbar
close(handleLoadDatabase);

% Forced logging off
if exist('diaryforced_on','var') && diaryforced_on
    diary off
end

