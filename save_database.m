% SAVE_DATABASE Save the database

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
handleSaveDatabase = waitbar(0,'Saving Database...');

% Check for safe loading
if exist('database_loaded_safe','var') && database_loaded_safe
    save(DatabaseFilename,Database_prefix)
    logformat(sprintf('Database saved to %s.mat file.',DatabaseFilename),'DATABASE');
else
    logformat('Database file not loaded safely, save failed. Backup database before saving!', 'ERROR')
end

waitbar(1,handleSaveDatabase,'Saving database...');

% Close waitbar
close(handleSaveDatabase);

% Forced logging off
if exist('diaryforced_on','var') && diaryforced_on
    diary off
end