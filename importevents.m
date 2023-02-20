function database_out = importevents(database_in,datasource,import_data,waitbarhandle)

database_out = database_in;

% Import config to assign data quality
strewnconfig

% Duplicate event identification thresholds
location_err_km = database_out.Metadata.(datasource).location_err_km; 
time_err_s = database_out.Metadata.(datasource).time_err_s;
time_err_min = ceil(time_err_s/60);

num_new = 0;
num_newsources = 0;
num_updated = 0;
%fields_donotimport = {'EventID' 'DateAccessed'};
fields_donotimport = {'EventID'};
fields_donotcompare = {'EventID' 'DateAccessed'};
fields_ignorenewfields = {'EventID' 'DateAdded' 'DateUpdated' 'DateAccessed'};

% Update log
ChangeLog_idx = size(database_out.ChangeLog,1) + 1;
nowtime = datetime('now','TimeZone','UTC');
database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'Import Log'};
database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Started importing ' datasource]};

% Update waitbar
waitbar(0,waitbarhandle,['Getting ' datasource ' Data...']);

% Initialize import data review
size_import = size(import_data,1);
numvar = numel(import_data.Properties.VariableNames);

% Turn off table warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Check the new events against the database
for event_i = 1:size_import
    
    data_changed = false;
    new_event = false;
    new_source = false;
    
    % Update waitbar
    waitbar(event_i/size_import,waitbarhandle,['Reviewing ' datasource ' Events...  ' num2str(event_i) ' of ' num2str(size_import) newline num2str(num_new) ' Events Added,  ' num2str(num_updated+num_newsources), ' Events Updated']);
    
    % Determine data type for import
    if ismember('EventName',fieldnames(import_data)) && contains(import_data.EventName(event_i),'Doppler')
         datatype = 'Doppler';
    else
         datatype = 'Trajectory';
    end
    
    switch datatype
        case 'Trajectory'

            % Assign reference point for EventID calculation
            % if no reference point is defined, define it as end point
            if ~strcmp(datasource,'NEOB') && ~strcmp(datasource,'ASGARD')&&...
                ~(ismember('ref_Lat',fieldnames(import_data)) && ismember('ref_Long',fieldnames(import_data)) && ismember('ref_Height_km',fieldnames(import_data)) && ismember('ref_Description',fieldnames(import_data)))
                
                % if any critical inputs are missing
                if ismember('ref_Lat',fieldnames(import_data)), ismember('ref_Long',fieldnames(import_data)),ismember('ref_Height_km',fieldnames(import_data)),ismember('ref_Description',fieldnames(import_data))
                    error('Invalid input data.  Resolve reference point values for ref_Lat, ref_Long, and ref_Height_km')
                end
                
                % Assign end point as reference point
                try
                    importdata.ref_Lat = importdata.end_Lat;
                    importdata.ref_Long = importdata.end_Long;
                    importdata.ref_Height_km = importdata.end_Height_km;
                    importdata.ref_Description(:) = {'end'};
                catch
                    logformat(sprintf('Reference point not found for %s.%s.%s, updated record created.',import_data.EventID_nom{event_i}, datatype, datasource),'WARN')
                end
            end

            if ~strcmp(datasource,'NEOB') && ~strcmp(datasource,'ASGARD')
                nomcalc = true;
                [import_data.LAT(event_i), import_data.LONG(event_i)] =...
                    nomlatlong(import_data.Bearing_deg(event_i),import_data.ZenithAngle_deg(event_i),import_data.ref_Lat(event_i),import_data.ref_Long(event_i),import_data.ref_Height_km(event_i));
            else
                nomcalc = false;
                import_data.LAT(event_i) = import_data.ref_Lat(event_i);
                import_data.LONG(event_i) = import_data.ref_Long(event_i);
            end

            % Post processing - complex functions for each record
            if ~ismember('Timezone',fieldnames(import_data)) && ~isnan(import_data.LONG(event_i))
                import_data.Timezone(event_i) = {timezonecalc(import_data.LONG(event_i))};
                import_data.Datetime_local(event_i) = datetime(import_data.DatetimeUTC(event_i),'TimeZone',import_data.Timezone{event_i});
                %import_data.HyperMap(event_i) = {['https://maps.google.com/?q=' num2str(import_data.LAT(event_i),'%f') '%20' num2str(import_data.LONG(event_i),'%f')]};
            else
                import_data.Timezone(event_i) = {'+00:00'};
                %import_data.HyperMap(event_i) = {''};
            end

        otherwise
            warning('unhandled datatype')
    end

    % Generate possible EventID matches
    EventID_nom = eventid(import_data.LAT(event_i),import_data.LONG(event_i),import_data.DatetimeUTC(event_i));
    PossibleEventIDs = alteventids(import_data.LAT(event_i),import_data.LONG(event_i),import_data.DatetimeUTC(event_i),time_err_min,location_err_km);
    PossibleEventIDs = PossibleEventIDs(isfield(database_out,PossibleEventIDs) | strcmp(PossibleEventIDs,EventID_nom)); % ID's in the database or the nominal ID
    
    % Issue: some unique ID's may not be listed, due to incorrect source data
    % Possible solution: Add to the possible list, a list of database ID's with unique Source key matches?
    % Downside is increased import time, due to checking every unique ID for every imported item
    % How many could there be?
    
    % Check for EventID increment matches,
    % such as Y20211201_13Z_11M, Y20211201_13Z111M, Y20211201_13Z211M, etc.
    num_possible = numel(PossibleEventIDs); % additional IDs added inside loop, don't check
    for dup_i = 1:num_possible
               
        % Incrementing for multiple events in one hour
        for increment_i = 1:numel(EventIDidx)
            testID = [PossibleEventIDs{dup_i}(1:12) EventIDidx{increment_i} PossibleEventIDs{dup_i}(15:17)];
             
            % if the modified ID exists, add it to the end of the match list
            if isfield(database_out,testID)
                PossibleEventIDs(end+1,1) = {testID};
                
                % Reached end of possible increments
                if increment_i == numel(EventIDidx) && strcmp(EventID_nom,PossibleEventIDs{dup_i})
                    error('Unhandled exception: maximum EventID increments is 1296!')
                end
             
            % if no more matches, no need to check the rest
            else
                % this is the last increment of the nominal ID, save the digit
                % if no other event matches, the nominal ID will be incremented
                if strcmp(EventID_nom,PossibleEventIDs{dup_i})
                    nom_increment = increment_i;
                end
                break
            end
        end
    end
        
    % Rule out mis-matches, based on time and location
    delete_i = int16.empty;
    for dup_i = 1:numel(PossibleEventIDs)
        if isfield(database_out,PossibleEventIDs{dup_i}) && isfield(database_out.(PossibleEventIDs{dup_i}),datatype)
            % Choose compare source for the event
            EventSources = fieldnames(database_out.(PossibleEventIDs{dup_i}).(datatype));

            % if same source exists, use that to compare
            if any(contains(EventSources,datasource))
                CompSource = datasource;

            % otherwise, compare to the best source
            else
                CompSource = EventSources{1};
                for source_i = 2:numel(EventSources)
                    if database_out.Metadata.(EventSources{source_i}).rank < database_out.Metadata.(CompSource).rank
                        CompSource = EventSources{source_i};
                    end
                end
            end

            % Calculate deltas
            dup_timedelta_s = abs(seconds(import_data.DatetimeUTC(event_i) - database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).DatetimeUTC));
            dup_dist_km = distance(import_data.LAT(event_i),import_data.LONG(event_i),database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).LAT,database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).LONG,planet) / 1000;

            % Calculate thresholds as the sum of expected error for both sources
            max_timedelta_s = database_out.Metadata.(datasource).time_err_s + database_out.Metadata.(CompSource).time_err_s;
            max_dist_km = database_out.Metadata.(datasource).location_err_km + database_out.Metadata.(CompSource).location_err_km;

            % Compare events and prepare to remove non-matching events from the duplicate list
            if (dup_timedelta_s > max_timedelta_s) || (dup_dist_km > max_dist_km)
                delete_i(end+1,1) = dup_i; 
            end    
        end
    end
    
    % Remove non-matching events from the duplicate list
    PossibleEventIDs(delete_i) = []; 
    num_possible = numel(PossibleEventIDs);
    
    % Check for previous matches
    if num_possible > 1
        % for each possible event id
        for dup_i = 1:num_possible
           try
               % check each source in the database for that ID 
               temp_sources = size({database_out.(PossibleEventIDs{dup_i}).(datatype).(datasource).SourceKey},2); 
               for source_i = 1:temp_sources
                    try
                       if matches(database_out.(PossibleEventIDs{dup_i}).(datatype).(datasource)(source_i).SourceKey,import_data.SourceKey{event_i})  % try to access already imported data
                           PossibleEventIDs = PossibleEventIDs(dup_i); % delete all other options
                           dup_i = num_possible + 1; % break loop
                           source_i = temp_sources + 1; % break loop
                           %logformat(sprintf('Source Key %s from %s found in %s. Previously matched event.',import_data.SourceKey{event_i},datasource,PossibleEventIDs{dup_i}),'DATABASE')                   
                       end
                    end
               end
            end
        end
    end
    % Init change summary addendum
    ChangeAddendum = char.empty;
    
    % import the data for compare
    testimport =  table2struct(import_data(event_i,:));
    
    % Update num possible
    num_possible = numel(PossibleEventIDs);
    
    % if multiple possible matches remaining, ask for user selection
    if num_possible > 1
                
        % manually resolve duplicates
        reportevents_test(database_out,PossibleEventIDs)

        % Display new event data
        testimport.DatetimeUTC
        testimport.SourceKey
        testimport.Hyperlink1

        % Log activity
        logformat([sprintf('Auto-merge failed, %s from %s matches ', import_data.SourceKey{event_i}, datasource) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})])
        logformat('Requesting user input for manual merge.','USER')

        % Prompt user
        [SELECTION,OK] = listdlg('ListString',PossibleEventIDs,'PromptString','Select Matching Event','Name','Multiple Matching Events','ListSize',[250 75], 'SelectionMode', 'single');
        if OK
            
            msg = [sprintf('User selected %s from %s matches ', PossibleEventIDs{SELECTION}, datasource) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})];
            
            % clear possible ID's and use selection from user
            num_possible = 1;
            PossibleEventIDs = PossibleEventIDs(SELECTION); % Remove all other options
        else
            msg = 'User cancelled merge.  Unresolved duplicate.';
        end 
        
        % Logging
        logformat(msg)
        ChangeAddendum = [ChangeAddendum msg];
    end
    
    % if multiple possible matches still remain after user selection, merge has failed
    if num_possible > 1
                
        % report merge failure
        logformat([sprintf('Merge failure, %s from %s matches ', EventID_nom, datasource) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})],'DEBUG')
        
        warning('off','MATLAB:table:RowsAddedExistingVars');
        ChangeLog_idx = ChangeLog_idx + 1;
        database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
        database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'Merge Failure'};
        database_out.ChangeLog.EventID(ChangeLog_idx) = PossibleEventIDs(1);
        database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
        database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Failed to Merge: ' PossibleEventIDs{1} ' and ' PossibleEventIDs{2} '. ' ChangeAddendum]};
           
    % one possible ID and it exists in the database - update it
    elseif num_possible == 1 && isfield(database_out, PossibleEventIDs{1})
        
        % alternate EventID matched
        if ~strcmp(EventID_nom, PossibleEventIDs{1})
            %logformat(sprintf('Source key %s from %s is a match for Event %s in database.', import_data.SourceKey{event_i}, datasource, PossibleEventIDs{1}),'DATABASE')
            ChangeAddendum = 'alternate EventID used';
            EventID_nom = PossibleEventIDs{1};
        end
        
        % create new datatype, if necessary
        if ~isfield(database_out.(EventID_nom),datatype)
            database_out.(EventID_nom).(datatype) = struct;
        end
        
        % if the source exists
        if isfield(database_out.(EventID_nom).(datatype),datasource)
            
            % Check for differences
            fields_database = fieldnames(database_out.(EventID_nom).(datatype).(datasource)); % get database field names for this event
            fields_import = setdiff(import_data.Properties.VariableNames',fields_donotimport); % get imported fields
            fields_compare = setdiff(import_data.Properties.VariableNames',fields_donotcompare); % get imported fields
            fields_new = setdiff(setdiff(fields_import, fields_database),fields_ignorenewfields); % get new fields
            num_fields = numel(fields_compare);
            fields_numnew = numel(fields_new);
            
            % if new fields exist, skip to adding a new record
            if fields_numnew > 0
                data_changed = true;     
            
            % otherwise, check each field for differences
            else
                
                % compare each field
                for v = 1:num_fields
                    eval(['data_old = database_out.(EventID_nom).(datatype).(datasource)(1).' fields_compare{v} ';'])
                    
                    % test
                    if size(database_out.(EventID_nom).(datatype).(datasource),2) > 1
                        eval(['data_2old = database_out.(EventID_nom).(datatype).(datasource)(2).' fields_compare{v} ';'])
                    else
                        data_2old = data_old;
                    end
                    
                    %eval(['data_new = import_data.' fields_compare{v} '(' num2str(event_i) ');' ])
                    eval(['data_new = testimport.' fields_compare{v} ';'])
                    
                    % if data changed
                    try
                        old_datamatch =  isequaln(data_old, data_new) || (or(iscell(data_old),iscell(data_new)) && matches(data_old,data_new));
                    catch
                        data_new = {data_new};
                        try
                            old_datamatch =  isequaln(data_old, data_new) || (or(iscell(data_old),iscell(data_new)) && matches(data_old,data_new));
                        catch
                            old_datamatch =  isequaln(data_old, data_new);
                        end
                    end
                    
                    try
                        old2_datamatch =  isequaln(data_2old, data_new) || (or(iscell(data_2old),iscell(data_new)) && matches(data_2old,data_new));
                    catch
                        old2_datamatch =  isequaln(data_2old, data_new);
                    end

                    if ~old_datamatch && ~old2_datamatch
                          data_changed = true;
                          EventID_nom
                          fields_compare{v}
                          data_old
                          data_2old
                          data_new
                          %error('test')
                        break;
                    end                
                end
            end
            
            % if the data changed, add a new record at index 1, shifting
            % the old data to a higher index
            if data_changed
                
                % shift data to previous and add new record
                for r = numel(database_out.(EventID_nom).(datatype).(datasource)):-1:1
                    database_out.(EventID_nom).(datatype).(datasource)(r+1) = database_out.(EventID_nom).(datatype).(datasource)(r);
                end

                % Add new record
                 for f = 1:numel(fields_import)
                     database_out.(EventID_nom).(datatype).(datasource)(1).(fields_import{f}) = import_data.(fields_import{f})(event_i);
                 end
                 
                 % this method failed for dissimilar structures error
                 %database_out.(EventID_nom).(datatype).(datasource)(1) = testimport;
                
                % Log
                logformat(sprintf('Data changed for %s.%s.%s, updated record created.',EventID_nom, datatype, datasource),'DATABASE')
                
                num_updated = num_updated + 1;
                % Add change log record
                ChangeLog_idx = ChangeLog_idx + 1;
                warning('off','MATLAB:table:RowsAddedExistingVars');
                database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
                database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'Data Updated'};
                database_out.ChangeLog.EventID(ChangeLog_idx) = {EventID_nom};
                database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
                database_out.ChangeLog.datatype(ChangeLog_idx) = {datatype};
                database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {[datasource 'data changed for ' EventID_nom ChangeAddendum]};                

            end

            % Clear data compares
            clear testimport
            clear fields_database
            clear fields_import
            clear fields_new
            clear fields_numnew
            clear data_2old
            clear data_old
            clear data_new
            
        % new source record for this event
        else
            database_out.(EventID_nom).(datatype).(datasource) = testimport;
            num_newsources = num_newsources + 1;
            new_source = true;
            
            logformat(sprintf('Event %s %s was imported from a new source: %s',EventID_nom, datatype, datasource),'DATABASE')
            
            % Add change log record
            warning('off','MATLAB:table:RowsAddedExistingVars');
            ChangeLog_idx = ChangeLog_idx + 1;
            database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
            database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'New Source'};
            database_out.ChangeLog.EventID(ChangeLog_idx) = {EventID_nom};
            database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
            database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {[datasource ' data source added for ' EventID_nom ChangeAddendum]};
        end
        
    % No match found, add new event record
    elseif num_possible == 1 && ~isfield(database_out, PossibleEventIDs{1})
                
        database_out.(EventID_nom).(datatype).(datasource) = testimport;
        
        new_event = true;
        num_new = num_new + 1;
        
        logformat(sprintf('New event added: %s.%s.%s',EventID_nom, datatype, datasource),'DATABASE')
        
        % Add change log record
        warning('off','MATLAB:table:RowsAddedExistingVars');
        ChangeLog_idx = ChangeLog_idx + 1;
        database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
        database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'New Event'};
        database_out.ChangeLog.EventID(ChangeLog_idx) = {EventID_nom};
        database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
        database_out.ChangeLog.datatype(ChangeLog_idx) = {datatype};
        database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Event Added:' EventID_nom]};
        
        
    % The ID already existed in the database, but not a matching event
    elseif num_possible == 0 && isfield(database_out, EventID_nom)
                
        % Increment the EventID
        EventID_nom(13:14) = EventIDidx{nom_increment};
        
        % Import the data into the new event
        database_out.(EventID_nom).(datatype).(datasource) = table2struct(import_data(event_i,:));
        
        new_event = true;
        num_new = num_new + 1;
        
        logformat(sprintf('New event added, duplicate index incremented: %s.%s.%s',EventID_nom, datatype, datasource),'DATABASEBASE')
        
        % Add change log record
        ChangeLog_idx = ChangeLog_idx + 1;
        database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
        database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'New Event'};
        database_out.ChangeLog.EventID(ChangeLog_idx) = {EventID_nom};
        database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
        database_out.ChangeLog.datatype(ChangeLog_idx) = {datatype};
        database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Event Added:' EventID_nom ' - ID increment ' EventIDidx{nom_increment}]};
        
    % unknown error handling
    else
        error('Unknown error!')
    end
   
    % Log event id for problem events
    if data_changed || new_event || new_source
        if nomcalc && (import_data.LAT(event_i) == import_data.ref_Lat(event_i)) && (import_data.LONG(event_i) == import_data.ref_Long(event_i))
            logformat(sprintf('Nominal coordinate extrapolation failed for %s from %s.', EventID_nom, datasource))
        elseif contains(EventID_nom,'X')
            logformat(sprintf('EventID defaulted for %s from %s.', EventID_nom, datasource))
        end
    end
    
    % Clear temp variables
    clear testimport
    clear new_event
    clear new_source
    clear data_changed
end

% Update Log
ChangeLog_idx = ChangeLog_idx + 1;
warning('off','MATLAB:table:RowsAddedExistingVars');
database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'Import Log'};
database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Finished importing ' datasource ]};

% Sort fields
database_out = orderfields(database_out);

% Update waitbar (to include last added/updated event)
waitbar(event_i/size_import,waitbarhandle,['Reviewing ' datasource ' Events...  ' num2str(event_i) ' of ' num2str(size_import) newline num2str(num_new) ' Events Added,  ' num2str(num_updated+num_newsources), ' Events Updated']);

