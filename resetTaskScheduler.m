% RESETTASKSCHEDULER
% clears the last run for the task scheduler, to run all tasks at the next call

% If the taskfilename has not been specified, check for existing file 
% (to prevent mismatched filenames being created)
if ~exist('taskfilename','var') 
    taskfilename = 'TaskSchedulerData.mat';
    if exist(taskfilename,'file') ~= 2
        error(sprintf('%s not found.  Check filename specified in TaskScheduler.m',taskfilename))
    end
end

default_lastrun = datetime(1900,1,1,'TimeZone','UTC');
taskmaster.FrequentTask.lastrun_utc = default_lastrun;
taskmaster.DailyTask.lastrun_utc = default_lastrun;
taskmaster.OccaisionalTask.lastrun_utc = default_lastrun;
save(taskfilename,'taskmaster')