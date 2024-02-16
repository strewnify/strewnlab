% TASKSCHEDULER Automated task scheduler, to be called by Windows Task Scheduler.
% Schedule this task in the Windows Task Scheduler
% Action:
% Program Script: "C:\Program Files\MATLAB\R2020b\bin\matlab.exe"
% Add arguments: -r cd('C:\Users\james\Documents\GitHub\strewnlab'),TaskScheduler ,exit -logfile C:\Users\james\Documents\GitHub\strewnlab\logs\taskscheduler.log


% Set user NOT present
setUserPresent(false)

% Initialize session
import_ref_data

% Run notification script
strewnnotify
