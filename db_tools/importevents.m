function database_out = importevents(database_in, import_data, datasource, waitbarhandle)

database_out = database_in;

% Import config to assign data quality
strewnconfig

num_new = 0;
num_newsources = 0;
num_updated = 0;
%fields_donotimport = {'EventID' 'DateAccessed'};
fields_donotimport = {'EventID' 'source_record'};
fields_donotcompare = {'EventID' 'DateAccessed' 'source_record'};
fields_ignorenewfields = {'EventID' 'DateAdded' 'DateUpdated' 'DateAccessed' 'source_record' 'Location' 'Locality' 'State' 'Country'};

% Update log
warning('off','MATLAB:table:RowsAddedExistingVars');
ChangeLog_idx = size(database_out.ChangeLog,1) + 1;
nowtime = datetime('now','TimeZone','UTC');
database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'Import Log'};
database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Started importing ' datasource]};

% Update waitbar
waitbar(0,waitbarhandle,['Getting ' datasource ' Data...']);

% Initialize import data review
size_import = size(import_data.(datasource).LatestData,1);
numvar = numel(import_data.(datasource).LatestData.Properties.VariableNames);

% Turn off table warning
warning('off','MATLAB:table:RowsAddedExistingVars');

data_types = type_events(import_data.(datasource).LatestData);

% Check the new events against the database
for event_i = 1:size_import
    
    record_cmp = 1; % record to compare
    data_changed = false;
    new_event = false;
    new_source = false;
    
    % get datatypes
    datatype = data_types{event_i};
    
    % Update waitbar
    waitbar(event_i/size_import,waitbarhandle,['Reviewing ' datasource ' Events...  ' num2str(event_i) ' of ' num2str(size_import) newline num2str(num_new) ' Events Added,  ' num2str(num_updated+num_newsources), ' Events Updated']);
    
    if ~strcmp(datatype,'Trajectory')
        logformat(sprintf('Unhandled datatype in %s import: %s',datasource,datatype),'DEBUG')
    end

    % Generate possible EventID matches
    EventID_nom = eventid(import_data.(datasource).LatestData.LAT(event_i),import_data.(datasource).LatestData.LONG(event_i),import_data.(datasource).LatestData.DatetimeUTC(event_i));
    PossibleEventIDs = alteventids(import_data.(datasource).LatestData.LAT(event_i),import_data.(datasource).LatestData.LONG(event_i),import_data.(datasource).LatestData.DatetimeUTC(event_i),import_data.(datasource).time_err_s,import_data.(datasource).location_err_km);
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
                    if import_data.(EventSources{source_i}).rank < import_data.(CompSource).rank
                        CompSource = EventSources{source_i};
                    end
                end
            end

            % Calculate deltas
            dup_timedelta_s = abs(seconds(import_data.(datasource).LatestData.DatetimeUTC(event_i) - database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).DatetimeUTC));
            dup_dist_km = distance(import_data.(datasource).LatestData.LAT(event_i),import_data.(datasource).LatestData.LONG(event_i),database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).LAT,database_out.(PossibleEventIDs{dup_i}).(datatype).(CompSource)(1).LONG,planet.ellipsoid_m) / 1000;

            % Calculate thresholds as the sum of expected error for both sources
            max_timedelta_s = import_data.(datasource).time_err_s + import_data.(CompSource).time_err_s;
            max_dist_km = import_data.(datasource).location_err_km + import_data.(CompSource).location_err_km;

            % Compare events and prepare to remove non-matching events from the duplicate list
            if (dup_timedelta_s > max_timedelta_s) || (dup_dist_km > max_dist_km)
                delete_i(end+1,1) = dup_i; 
            end    
        end
    end
    
    % Remove non-matching events from the duplicate list
    PossibleEventIDs(delete_i) = []; 
    num_possible = numel(PossibleEventIDs);

    % Check for SourceKey matches
    % for each possible event id
    for dup_i = 1:num_possible
       try
           % check each source in the database for that ID 
           temp_sources = size({database_out.(PossibleEventIDs{dup_i}).(datatype).(datasource).SourceKey},2); 
           for source_i = 1:temp_sources
                try
                   if matches(database_out.(PossibleEventIDs{dup_i}).(datatype).(datasource)(source_i).SourceKey,import_data.(datasource).LatestData.SourceKey{event_i})  % try to access already imported data
                       PossibleEventIDs = PossibleEventIDs(dup_i); % delete all other options
                       record_cmp = source_i;
                       dup_i = num_possible + 1; % break outer loop
                       source_i = temp_sources + 1; % break loop
                       %logformat(sprintf('Source Key %s from %s found in %s. Previously matched event.',import_data.(datasource).LatestData.SourceKey{event_i},datasource,PossibleEventIDs{dup_i}),'DATABASE')                   
                   end
                end
           end
        end
    end
    % Init change summary addendum
    ChangeAddendum = char.empty;
    
    % import the data for compare
    testimport =  table2struct(import_data.(datasource).LatestData(event_i,:));
    
    % Update num possible
    num_possible = numel(PossibleEventIDs);
    
    % if multiple possible matches still remain, move event to manual merge
    if num_possible > 1
        
        % Increment the EventID
        EventID_nom(13:14) = EventIDidx{nom_increment};
        
        % Import the data into Manual Merge
        database_out.ManualMerge.(EventID_nom).(datatype).(datasource) = table2struct(import_data.(datasource).LatestData(event_i,:));
        
        % report merge failure
        logformat([sprintf('Merge failure, %s from %s matches. Imported to ManualMerge.%s', EventID_nom, datasource, EventID_nom) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})],'DEBUG')
        
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
            %logformat(sprintf('Source key %s from %s is a match for Event %s in database.', import_data.(datasource).LatestData.SourceKey{event_i}, datasource, PossibleEventIDs{1}),'DATABASE')
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
            fields_import = setdiff(import_data.(datasource).LatestData.Properties.VariableNames',fields_donotimport); % get imported fields
            fields_compare = setdiff(import_data.(datasource).LatestData.Properties.VariableNames',fields_donotcompare); % get imported fields
            fields_new = setdiff(setdiff(fields_import, fields_database),fields_ignorenewfields); % get new fields
            num_fields = numel(fields_compare);
            fields_numnew = numel(fields_new);
            
            % if new fields exist, skip to adding a new record
            if fields_numnew > 0
                data_changed = true;     
            
            % otherwise, check each field for differences
            else
                for v = 1:num_fields
                    data_old = database_out.(EventID_nom).(datatype).(datasource)(record_cmp).(fields_compare{v});
                    
                    data_new = testimport.(fields_compare{v});
                    
                    % if data changed
                    try
                        datamatch =  isequaln(data_old, data_new) || (or(iscell(data_old),iscell(data_new)) && matches(data_old,data_new));
                    catch
                        data_new = {data_new};
                        try
                            datamatch =  isequaln(data_old, data_new) || (or(iscell(data_old),iscell(data_new)) && matches(data_old,data_new));
                        catch
                            datamatch =  isequaln(data_old, data_new);
                        end
                    end

                    if ~datamatch
                          data_changed = true;
                          EventID_nom
                          fields_compare{v}
                          data_old
%                           data_2old
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
                     database_out.(EventID_nom).(datatype).(datasource)(1).(fields_import{f}) = import_data.(datasource).LatestData.(fields_import{f})(event_i);
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
        database_out.(EventID_nom).(datatype).(datasource) = table2struct(import_data.(datasource).LatestData(event_i,:));
        
        new_event = true;
        num_new = num_new + 1;
        
        logformat(sprintf('New event added, duplicate index incremented: %s.%s.%s',EventID_nom, datatype, datasource),'DATABASE')
        
        % Turn off table warning
        warning('off','MATLAB:table:RowsAddedExistingVars');
        
        % Add change log record
        %database_out = dbChangeLog(database_out,'New Event', EventID_nom, datasource, datatype, ... add function?
        ChangeLog_idx = ChangeLog_idx + 1;
        database_out.ChangeLog.DatetimeUTC(ChangeLog_idx) = nowtime;
        database_out.ChangeLog.ChangeType(ChangeLog_idx) = {'New Event'};
        database_out.ChangeLog.EventID(ChangeLog_idx) = {EventID_nom};
        database_out.ChangeLog.datasource(ChangeLog_idx) = {datasource};
        database_out.ChangeLog.datatype(ChangeLog_idx) = {datatype};
        database_out.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Event Added:' EventID_nom ' - ID increment ' EventIDidx{nom_increment}]};
        
    % unknown error handling
    else
        logformat('Unknown error.','ERROR')
    end
   
    % Post-processing and logging for modified records
    if data_changed || new_event || new_source
        
        % Add event location description
        if ~isnan(database_out.(EventID_nom).(datatype).(datasource)(1).ref_Lat) && ~isnan(database_out.(EventID_nom).(datatype).(datasource)(1).ref_Long)
            
            % coordinates didn't change, just copy location data
            if data_changed && isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Location') && ...
                database_out.(EventID_nom).(datatype).(datasource)(1).ref_Lat == database_out.(EventID_nom).(datatype).(datasource)(1).ref_Lat

                try
                    database_out.(EventID_nom).(datatype).(datasource)(1).Location = database_out.(EventID_nom).(datatype).(datasource)(2).Location;
                    database_out.(EventID_nom).(datatype).(datasource)(1).Locality = database_out.(EventID_nom).(datatype).(datasource)(2).Locality;
                    database_out.(EventID_nom).(datatype).(datasource)(1).State = database_out.(EventID_nom).(datatype).(datasource)(2).State;
                    database_out.(EventID_nom).(datatype).(datasource)(1).Country = database_out.(EventID_nom).(datatype).(datasource)(2).Country;
                    update_location = false;
                catch
                    update_location = true;
                end
            else
                update_location = true;
            end
            
            % coordinates changed or copy failed, update location
            if update_location
                [ location_string, locality, state, country, ~, ~ ] = getlocation(database_out.(EventID_nom).(datatype).(datasource)(1).ref_Lat,database_out.(EventID_nom).(datatype).(datasource)(1).ref_Long,column_width-3);
                if ~isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Location') ||...
                        (isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Location') && isempty(database_out.(EventID_nom).(datatype).(datasource)(1).Location))                        
                    database_out.(EventID_nom).(datatype).(datasource)(1).Location = location_string;
                end
                if ~isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Locality') ||...
                        (isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Locality') && isempty(database_out.(EventID_nom).(datatype).(datasource)(1).Locality))                        
                    database_out.(EventID_nom).(datatype).(datasource)(1).Locality = locality;
                end
                if ~isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'State') ||...
                        (isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'State') && isempty(database_out.(EventID_nom).(datatype).(datasource)(1).State))                        
                    database_out.(EventID_nom).(datatype).(datasource)(1).State = state;
                end
                if ~isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Country') ||...
                        (isfield( database_out.(EventID_nom).(datatype).(datasource)(1), 'Country') && isempty(database_out.(EventID_nom).(datatype).(datasource)(1).Country))                        
                    database_out.(EventID_nom).(datatype).(datasource)(1).Country = country;
                end
                clear location_string
                clear locality
                clear state
                clear country
            end
        end
        
        % log problems
        if ~strcmp(datasource,'NEOB') && ~strcmp(datasource,'ASGARD') && (import_data.(datasource).LatestData.LAT(event_i) == import_data.(datasource).LatestData.ref_Lat(event_i)) && (import_data.(datasource).LatestData.LONG(event_i) == import_data.(datasource).LatestData.ref_Long(event_i))
            logformat(sprintf('Nominal coordinate extrapolation failed for %s from %s.', EventID_nom, datasource))
        elseif contains(EventID_nom,'X')
            logformat(sprintf('EventID defaulted for %s from %s.', EventID_nom, datasource))
        end
    end
    
    % Clear temp variables
    clear testimport
    clear new_event
    clear new_source
    clear record_cmp
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

