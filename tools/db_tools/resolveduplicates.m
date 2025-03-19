function [database] = resolveduplicates(database_in) 
% [DATABASE_OUT] = RESOLVEDUPLICATES(DATABASE)
% Resolve meteor database duplicates

% Copy database to output
database = database_in;

% list events
events = fields(database);
numevents = size(events,1);

% Initialize waitbar
waitbarhandle = waitbar(0,'Loading Data...');

% Prepare to update change log in the database
ChangeLog_idx = size(database.ChangeLog,1);
nowtime = datetime('now','TimeZone','UTC');

for event_i = 5500:numevents
    
    % Update waitbar
    waitbar(event_i/numevents,waitbarhandle,['Reviewing Events...  ' num2str(event_i) ' of ' num2str(numevents)]);
    
    % Get EventID
    EventID_nom = events{event_i};
        
    % If event was observed, check for duplicates
    if EventID_nom(1) == 'Y'

        % check the first data source
        sources = fields(database.(EventID_nom).Trajectory);
        datasource = sources{1};

        % Generate EventID and resolve duplicates
         PossibleEventIDs = alteventids(database.(EventID_nom).Trajectory.(datasource)(1).LAT,database.(EventID_nom).Trajectory.(datasource)(1).LONG,database.(EventID_nom).Trajectory.(datasource)(1).Datetime,database_in.(datasource).time_err_s,database_in.(datasource).location_err_km);
         EventID_matches = PossibleEventIDs(isfield(database,PossibleEventIDs));
         nummatches = numel(EventID_matches);

        % if multiple possible matches
        if nummatches > 1 || (nummatches == 1 && ~ismember(EventID_nom,PossibleEventIDs))
            % resolve duplicates
            datasource
            nummatches
            EventID_nom
            EventID_matches
            logformat(sprintf('Need to resolve duplicates for %s.Trajectory.%s',EventID_nom,datasource),'WARN')
            reportevents_test(database,EventID_matches)

            if nummatches == 2

                logformat(sprintf('User prompted for Event %0.0f of %f0.0: %s',event_i,numevents,events{event_i}),'USER')
                
                % Prompt user
                [SELECTION,OK] = listdlg('ListString',EventID_matches,'PromptString','Select Event to Keep','Name','Merge Events','ListSize',[250 75], 'SelectionMode', 'single');

                if OK
                    switch SELECTION
                        case 1
                            EventID_Keep = EventID_matches{1};
                            EventID_Delete = EventID_matches{2};

                        case 2
                            EventID_Keep = EventID_matches{2};
                            EventID_Delete = EventID_matches{1};
                    end
                end

                % if the user made a selection and the other selection has only one source
                if OK && numel(fields(database.(EventID_Delete).Trajectory)) == 1
                    % Merge Events
                    Source_Move = fields(database.(EventID_Delete).Trajectory);
                    Source_Move = Source_Move{1};
                    database.(EventID_Keep).Trajectory.(Source_Move) = database.(EventID_Delete).Trajectory.(Source_Move);
                    database = rmfield(database,EventID_Delete);
                    warning('Events merged')

                    % update event list
                    events = fields(database);
                    numevents = size(events,1);

                    % report updated event
                    ChangeLog_idx = ChangeLog_idx + 1;
                    database.ChangeLog.Datetime(ChangeLog_idx) = nowtime;
                    database.ChangeLog.ChangeType(ChangeLog_idx) = {'Event Merge'};
                    database.ChangeLog.EventID(ChangeLog_idx) = {EventID_Keep};
                    database.ChangeLog.datasource(ChangeLog_idx) = {Source_Move};
                    database.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Event Merge:' EventID_Delete ':' Source_Move ' moved into ' EventID_Keep '. ' EventID_Delete ' deleted.' ]};

                    
                else
                    warning('Merge failure')

                    % report merge failure
                    ChangeLog_idx = ChangeLog_idx + 1;
                    database.ChangeLog.Datetime(ChangeLog_idx) = nowtime;
                    database.ChangeLog.ChangeType(ChangeLog_idx) = {'Merge Failure'};
                    database.ChangeLog.EventID(ChangeLog_idx) = EventID_matches(1);
                    database.ChangeLog.ChangeSummary(ChangeLog_idx) = {['Failed to Merge: ' EventID_matches{1} ' and ' EventID_matches{2} '. ']};
                end
                clear EventID_Keep
                clear EventID_Delete
                clear Source_Move
            else
                logformat(sprintf('Multiple duplicates found for %s, no algorithm to handle',events{event_i}),'DEBUG')
                
            end
        end
    end
end

end


%     code from importevents
%     % if multiple possible matches remaining, ask for user selection
%     if num_possible > 1
%                 
%         % manually resolve duplicates
%         reportevents_test(database_out,PossibleEventIDs)
% 
%         % Display new event data
%         testimport.DatetimeUTC
%         testimport.SourceKey
%         testimport.Hyperlink1
% 
%         % Log activity
%         logformat([sprintf('Auto-merge failed, %s from %s matches ', import_data.(datasource).LatestData.SourceKey{event_i}, datasource) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})])
%         logformat('Requesting user input for manual merge.','USER')
% 
%         % Prompt user
%         %[SELECTION,OK] = listdlg('ListString',PossibleEventIDs,'PromptString','Select Matching Event','Name','Multiple Matching Events','ListSize',[250 75], 'SelectionMode', 'single');
%         OK = false; % DEBUG - need solution for automated merge
%         if OK
%             
%             msg = [sprintf('User selected %s from %s matches ', PossibleEventIDs{SELECTION}, datasource) sprintf('%s, ', PossibleEventIDs{1:(end-1)}) sprintf('%s', PossibleEventIDs{end})];
%             
%             % clear possible ID's and use selection from user
%             num_possible = 1;
%             PossibleEventIDs = PossibleEventIDs(SELECTION); % Remove all other options
%         else
%             msg = 'User cancelled merge.  Unresolved duplicate.';
%         end 
%         
%         % Logging
%         logformat(msg)
%         ChangeAddendum = [ChangeAddendum msg];
%     end
