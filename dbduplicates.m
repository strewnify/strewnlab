% RESOLVEDUPLICATES  Resolve meteor database duplicates

% Temporary
DatabaseFilename = 'MeteorDatabase'; %.mat filename OVERWRITES DATABASE FILENAME FROM STREWNCONFIG
Database_EventData_varname = 'sdb_MeteorData';
logformat('Database in development, temporary name ''MeteorDatabase'' used to overwrite strewnconfig.','DEBUG')

% Load the database
load_database
 
% Open a waitbar
handleDuplicates = waitbar(0,'Loading Data...');
 
% % if the database file exists, load it
% if usefile
%     if isfile([DatabaseFilename '.mat'])
%         load(DatabaseFilename)
%         % Check for correct content
%         if ~exist('MeteorData','var')
%             error('Database content unexpected.  Contact developer.')
%         else
%             disp(['Data loaded from ' DatabaseFilename '.mat file.']);
%         end
%     % Otherwise, warn the user and create a new database
%     else
%         warning('Database not found, creating new empty database.')
%         MeteorData = struct;
%     end
% end
% 
% % Backup the event database
% cd(backupfolder)
% save([DatabaseFilename '_BACKUP_' now_datestring],'MeteorData')
% cd(mainfolder)
devwarning('resolveduplicates')

% Initialize counters
num_reviewed = 0;
num_new = 0;
num_newsources = 0;
num_updated = 0;

% Get database event list
eventids = fieldnames(MeteorData);
eventids = eventids(startsWith(eventids,'Y'));
numevents = size(eventids,1);

% Resolve duplicates
duplicate_i = 1;
duplicates = {};
for event_i = 1:numevents
    
    % Update waitbar
    waitbar(i/numevents,handleDuplicates,['Reviewing Database Events...  ' num2str(event_i) ' of ' num2str(numevents) newline num2str(num_new) ' Events Added,  ' num2str(num_updated), ' Events Updated']);
    
    % Check for duplicates
    sources = fieldnames(MeteorData.(eventids{event_i}).Trajectory);
    numsources = size(sources,1);
    for source_i = 1:numsources
        numrecords = size(MeteorData.(eventids{event_i}).Trajectory.(sources{source_i}),2);
        if numrecords > 1
            duplicates(duplicate_i) = eventids(event_i);
            duplicate_i = duplicate_i + 1;
        end
    end    
end

reportevents_test(MeteorData, duplicates);  

% Sort events and save the database
MeteorData = orderfields(MeteorData);
% save_database
devwarning('resolveduplicates')

% Re-enable table warnings
warning ('on','MATLAB:table:RowsAddedExistingVars')

% close waitbar
close(handleDuplicates)
disp([newline num2str(num_reviewed) ' Meteor Events Reviewed.  ' newline num2str(num_new) ' Events Added.' newline num2str(num_updated), ' Events Updated.'])

