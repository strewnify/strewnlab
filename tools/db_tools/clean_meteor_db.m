function [database_out] = clean_meteor_db(database_in, override)
%CLEAN_METEOR_DB Clean the meteor database.
%   Sorts fields, selects a reference trajectory, populates master location,
%   and optionally overrides existing reference data.

% Default override
if nargin < 2
    override = false;
end

override_reftrajectory = override;
override_location = override;
override_eventname = override;

% Check each override individually
if override_reftrajectory
    choice = questdlg('Are you sure you want to reset all reference trajectories in the database?', ...
        'Override Confirmation', 'Yes','No','No');
    if ~strcmp(choice,'Yes')
        error('Operation cancelled by user. Database unchanged.');
    end
end

if override_location
    choice = questdlg('Are you sure you want to reset all locations in the database?', ...
        'Override Confirmation', 'Yes','No','No');
    if ~strcmp(choice,'Yes')
        error('Operation cancelled by user. Database unchanged.');
    end
end

if override_eventname
    choice = questdlg('Are you sure you want to reset all Event Names in the database?', ...
        'Override Confirmation', 'Yes','No','No');
    if ~strcmp(choice,'Yes')
        error('Operation cancelled by user. Database unchanged.');
    end
end

% Copy input database to output
database_out = database_in;

% Sort top-level fields alphabetically
database_out = orderfields(database_out);

% Get all event IDs and remove metadata fields
AllEventIDs = fieldnames(database_out);
metadata_fields = {'ChangeLog', 'ManualMerge'};
AllEventIDs(ismember(AllEventIDs, metadata_fields)) = [];

% Identify Manual Merge items
if isfield(database_out, 'ManualMerge')
    ManualMergeIDs = fieldnames(database_out.ManualMerge);
else
    ManualMergeIDs = {};
end

% Define trajectory priority for selecting reference
SourcePriority = {'Goodall', 'NEOB', 'GMN', 'CNEOS', 'AMS', 'ASGARD'};

% --- Process each event ---
for idx = 1:10 %numel(AllEventIDs)
    eventID = AllEventIDs{idx};
    event = database_out.(eventID);

    % All sources present for this event
    sources_present = fieldnames(event.Trajectory);

    % Create search list: priority sources first, then any others
    search_list = [SourcePriority, setdiff(sources_present, SourcePriority, 'stable')];
    
    % --- Find Event Name ----
    if override_eventname || ~isfield(event, 'EventName')
        
        ref_eventname = '';  % Initialize empty

        % Loop through search_list once
        for s = 1:numel(search_list)
            source = search_list{s};
            if isfield(event.Trajectory, source)
                traj_records = event.Trajectory.(source);
                if isfield(traj_records(1), 'EventName') && ~isempty(traj_records(1).EventName)
                    ref_eventname = traj_records(1).EventName;
                    break;  % Stop at first valid name
                end
            end
        end

        % Assign reference EventName
        if ~isempty(ref_eventname)
            database_out.(eventID).EventName = ref_eventname;
        else
            database_out.(eventID).EventName = 'Unknown';
        end
    end
        
    % --- Select reference trajectory ---
    if override_reftrajectory || ~isfield(event, 'RefTrajectory')
        if isfield(event, 'Trajectory')
    
            ref_source = '';  % Initialize empty

            % Loop through search_list once
            for s = 1:numel(search_list)
                if ismember(search_list{s}, sources_present)
                    ref_source = search_list{s};
                    break;  % Stop at first valid source
                end
            end

            % Assign reference trajectory
            if ~isempty(ref_source)
                database_out.(eventID).RefTrajectory = ref_source;
            end
        end
    end

    
    % --- Populate location from reference trajectory ---
    if override_location || ~isfield(event, 'RefLocation')
        
        ref_source = database_out.(eventID).RefTrajectory;
        % Take the first record as reference
        ref_record = event.Trajectory.(ref_source)(1);

        % Call getlocation with latitude/longitude
        [location_string, locality, state, country, water_string, land_string] = getlocation(ref_record.LAT, ref_record.LONG, getConfig('column_width')-3); 
        
        % Populate RefLocation
        database_out.(eventID).RefLocation.location_string = location_string;
        database_out.(eventID).RefLocation.locality = locality;
        database_out.(eventID).RefLocation.state = state;
        database_out.(eventID).RefLocation.country = country;
        database_out.(eventID).RefLocation.water_string = water_string;
        database_out.(eventID).RefLocation.land_string = land_string;

    end
end

% --- Generate brief database summary ---
num_events = numel(AllEventIDs);

% Superset of all sources
all_sources = {};
for i = 1:num_events
    eventID = AllEventIDs{i};
    if isfield(database_out.(eventID), 'Trajectory')
        all_sources = union(all_sources, fieldnames(database_out.(eventID).Trajectory));
    end
end

% Oldest and most recent events
oldest_event = AllEventIDs{1};
most_recent_event = AllEventIDs{end};

fprintf('--- Meteor Database Summary ---\n');
fprintf('Total Events: %d\n', num_events);
fprintf('Sources Present: %s\n', strjoin(all_sources, ', '));
fprintf('Oldest Event: %s\n', oldest_event);
fprintf('Most Recent Event: %s\n', most_recent_event);
fprintf('Manual Merge Count: %d\n', numel(ManualMergeIDs));
fprintf('--------------------------------\n');

