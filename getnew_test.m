%function [ NewEvents, output_filename, num_new, num_updated ] = getnew_test( dayhistory )
% [NEW_EVENTS] =  GETNEW (DAYHISTORY)   Download event data from
% online sources, from the last x days (specified by DAYHISTORY), compare 
% to the database, and add new events.

% Data source config
getsources = {'GMN'}

% Load settings
strewnconfig
[~,codefilename,~] = fileparts(mfilename('fullpath'));
diary([logfolder codefilename '_log.txt'])  
diary on
logformat('Getting new events.')

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

dayhistory = 3041;
%dayhistory = 30;

% Config
GetCNEOS = false;
GetNEOB = false;
GetGoodall = false;
GetAMS = false;
GetMetBull = false;
GetASGARD = false;
GetGMN = true;

% Temporary
DatabaseFilename = 'MeteorDatabase'; %.mat filename OVERWRITES DATABASE FILENAME FROM STREWNCONFIG
Database_check = 'sdb_MeteorData';
logformat('Database in development, temporary name ''MeteorDatabase'' used to overwrite strewnconfig.','DEBUG')

%Load the database
load_database

nowtime_utc = datetime('now','TimeZone','UTC'); 
startyear = year(nowtime_utc-days(dayhistory));
endyear = year(nowtime_utc);

% Initialize counters
num_reviewed = 0;
num_new = 0;
num_newsources = 0;
num_updated = 0;

% Open a waitbar
handleNewEvents = waitbar(0,'Loading Data...');
pause(0.2)

% Get data from the CNEOS fireball database
if GetCNEOS
    if ~exist('CNEOS_data','var')
        CNEOS_data = getcneos_test();
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'CNEOS',CNEOS_data,handleNewEvents);
end

% Get NEO Bolide Data
if GetNEOB
    if ~exist('NEOB_data','var')
        NEOB_data = getneob_test();
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'NEOB',NEOB_data,handleNewEvents);
end

% Get data from the AllEventData spreadsheet
if GetGoodall
    if ~exist('User_data','var')
        Goodall_data = getuserdata('AllEventData.xlsx');
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'Goodall',Goodall_data,handleNewEvents);
end

% Get data from AMS
if GetAMS
    if ~exist('AMS_data','var')
        AMS_data = getams_test(dayhistory);
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'AMS',AMS_data,handleNewEvents);
end

% All Landings MetBull Database
if GetMetBull
    if ~exist('MetBull_data','var')
        MetBull_data = getuserdata('AllLandings.xlsx');
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'MetBull',MetBull_data,handleNewEvents);
end

% Get data from the ASGARD site
if GetASGARD
    if ~exist('ASGARD_data','var')
        dayhistory = 428;
        ASGARD_data = getasgard_test(dayhistory);
    end
    sdb_MeteorData = importevents(sdb_MeteorData,'ASGARD',ASGARD_data,handleNewEvents);
end

% Get data from the Global Meteor Network
if GetGMN
    if ~exist('GMN_data','var')
        GMN_data = getgmn_test();
    end
    warning('off','MATLAB:table:RowsAddedExistingVars');
    sdb_MeteorData = importevents(sdb_MeteorData,'GMN',GMN_data,handleNewEvents);
end


% % If events found, summarize and generate report
% if num_new > 0
%     
%     for i = 1:num_new
%         % Update waitbar
%         waitbar(i/num_new,handleNewEvents,'Populating Location Data...');
%         try
%             Merge_data.Location(new(i),1) = {getlocation(Merge_data.LAT(new(i)),Merge_data.LONG(new(i)))};
%         catch
%             Merge_data.Location(new(i),1) = {'-'};
%         end
%     end
% 
%     % Get current time
%     ProcessDatetime = datetime('now','TimeZone','UTC');
%     
%     % This code can provide specific variables to the database, to limit size
%     % Variables = {'EventID';'DataSource';'Datetime';'Location';'NumReports';'LAT';'LONG';'RadiatedEnergy';'ImpactEnergy';'vx';'vy';'vz';'Mass';'Speed';'Bearing_deg';'Incidence';'Altitude';'ProcessDate';'Hyperlink1';'Hyperlink2'};
%     % NewEvents = Merge_data(new,Variables);
%     
%     % Filter new events and sort
%     NewEvents = Merge_data(new,:);
%     NewEvents = sortrows(NewEvents,'EventID');
%     
%     % Set dates (feature TBD)
%     NewEvents.AddDate(:) = ProcessDatetime;
%     NewEvents.UpdateDate(:) = ProcessDatetime;
%     
%     % Records without a processing time are assigned current time
%     NewEvents.ProcessDate(isnat(NewEvents.ProcessDate)) = ProcessDatetime;
% 
%     % Write data to Excel file
%     temporary = NewEvents;
%     temporary.Datetime = datestr(temporary.Datetime,'mm/dd/yyyy HH:MM:SS UTC');
%     NewEvents_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
%     output_filename = [scheduledfolder '\' now_datestring '_NewEventData.csv'];
%     
%     cd(scheduledfolder)
%     writecell(NewEvents_xlsdata, output_filename)
%     % xlswrite(output_filename_short,NewEvents_xlsdata)
%     % open file in Excel
%     % winopen(output_filename)
%     cd(mainfolder)
%     
%     
% % otherwise, report no events
% else
%     disp('No new events found.')
%     output_filename = 'NA';
%     NewEvents = array2table(zeros(0,0)); % empty table to satify function return
% end

% Save the database
save_database

% Standardize output data
NEOB_data = standardize_tbdata(NEOB_data);

% Re-enable table warnings
warning ('on','MATLAB:table:RowsAddedExistingVars')

% close program
close(handleNewEvents)
logformat([newline num2str(num_reviewed) ' Meteor Events Reviewed.  ' newline num2str(num_new) ' Events Added.' newline num2str(num_updated), ' Events Updated.'])
[~,codefilename,~] = fileparts(mfilename('fullpath'));
logformat([upper(codefilename) ' completed.'])
diary off
warning('Diary disabled after GETNEW_TEST');


