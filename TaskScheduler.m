% TASKSCHEDULER Automated task scheduler, to be called by Windows Task Scheduler.
% Schedule this task in the Windows Task Scheduler
% Action:
% Program Script: "C:\Program Files\MATLAB\R2020b\bin\matlab.exe"
% Add arguments: -r "cd('C:\Users\james\Documents\GitHub\strewnlab'); TaskScheduler; exit" -logfile C:\Users\james\Documents\GitHub\strewnlab\logs\taskscheduler.log

temp solution
diary('C:\Users\james\Documents\GitHub\strewnlab\logs\strewnnotify_log.txt')
%diary([getSession('folders','logfolder') '\strewnnotify_log.txt'])        
diary on 
%RAII.diary = onCleanup(@() diary('off')); % turn the diary off after an error

% Configuration
FrequentTask_period = hours(2.5);
DailyTask_period = hours(23);
OccasionalTask_period = days(4);

% Get current time
nowtime_utc = datetime('now','TimeZone','UTC');

logformat('StrewnLAB scheduled task service started.')

% Set user NOT present
setUserPresent(false)

% Initialize session
import_ref_data

% Load settings
strewnconfig

% Load the task scheduler data
taskfilename = 'TaskSchedulerData.mat';
if exist(taskfilename,'file') == 2
    load(taskfilename)
    logformat(sprintf('Task scheduler data loaded from ''%s''',taskfilename),'INFO')

% Initialize the task scheduler (first time)
else
    resetTaskScheduler
    logformat(sprintf('''%s'' not found.  File created with defaults.',taskfilename),'DEBUG')
end

% Run FrequentTask
if nowtime_utc >= (taskmaster.FrequentTask.lastrun_utc + FrequentTask_period)
    
    logformat('StrewnLAB FrequentTask started.','INFO')
    
    % Strewnify notification task
    try
        %strewnnotify
    catch
        logformat('Unknown error in STREWNNOTIFY!','ERROR')
    end
    
    % Check mail queue
    try
        strewnmail
    catch
        logformat('Unknown error in STREWNMAIL!','ERROR')
    end
    
    % Record frequent task complete
    taskmaster.FrequentTask.lastrun_utc = nowtime_utc;
    
    logformat('StrewnLAB FrequentTask completed.','INFO') 
end


% Run DailyTask
if nowtime_utc >= (taskmaster.DailyTask.lastrun_utc + DailyTask_period)
    
    logformat('StrewnLAB DailyTask started.','INFO')
    
    % Import new StrewnNotify contacts from GoogleDrive
    try 
        importcontacts
    catch
        logformat('Error in IMPORTCONTACTS.','DEBUG')
    end
    
    % Import new cameras from GoogleDrive
    try 
        importcameras
    catch
        logformat('Error in IMPORTCAMERAS.','DEBUG')
    end
            
    % Record Daily task complete
    taskmaster.DailyTask.lastrun_utc = nowtime_utc;
    
    logformat('StrewnLAB DailyTask completed.','INFO') 
end


% Run OccasionalTask
if nowtime_utc >= (taskmaster.OccasionalTask.lastrun_utc + OccasionalTask_period)
    
    logformat('StrewnLAB OccasionalTask started.','INFO')
    
    % Get new events (new database method)
    try
        %getnew_test
    catch
        logformat('Unknown error in GETNEW_TEST.','DEBUG')
    end    
    
    % Record Occasional task complete
    taskmaster.OccasionalTask.lastrun_utc = nowtime_utc;
    
    logformat('StrewnLAB OccasionalTask completed.','INFO') 
end

% Save task scheduler data 
% DEBUG - need to create functions to get and save scheduler data, maybe part of IMPORT_REF_DATA?
save(taskfilename,'taskmaster')
logformat(sprintf('Task scheduler data saved to ''%s''',taskfilename),'INFO')

logformat('StrewnLAB scheduled task service complete.')

% Stop logging
diary off

% Exit MATLAB
%exit

