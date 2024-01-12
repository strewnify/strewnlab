% MAPALLEVENTS

Sources = [{'Goodall'} {'CNEOS'} {'AMS'} {'ASGARD'} {'GMN'} {'NEOB'} {'MetBull'} ];
num_sources = numel(Sources);

% Load the event database
%load_database

% Count Events
EventIDs = fieldnames(sdb_MeteorData)';
numevents = numel(EventIDs);

MeteorReport = table;
table_i = 1;

warning('off','MATLAB:table:RowsAddedExistingVars')
for event_i = 3:numevents
    good_loc = false;    
    
    for source_i = 1:num_sources
        if isfield(sdb_MeteorData.(EventIDs{event_i}).Trajectory,Sources{source_i})  % if the source exists
            
            temp_lat = sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i})(1).LAT;
            temp_lon = sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i})(1).LONG;
            
            % if location has already been found
            if good_loc
                MeteorReport.Source(table_i-1) = append(MeteorReport.Source(table_i-1), [', ' Sources{source_i}]);
            end
            
            % if location has not been found
            if ~good_loc && ~isnan(temp_lat) && ~isnan(temp_lon) && temp_lat ~= 0 && temp_lon ~=0
                good_loc = true;
                MeteorReport.idx(table_i) = event_i;
                MeteorReport.EventID(table_i) = strrep(EventIDs(event_i),'_','-');
                MeteorReport.LAT(table_i) = temp_lat;
                MeteorReport.LONG(table_i) = temp_lon;
                MeteorReport.Source(table_i) = Sources(source_i);
                if isfield(sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i}),'ImpactEnergyEst_kt')
                    MeteorReport.ImpactEnergyEst_kt(table_i) = sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i})(1).ImpactEnergyEst_kt;
                end
                
                if isfield(sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i}),'duration_s')
                    MeteorReport.Duration_s(table_i) = sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i})(1).duration_s;                    
                end
                
                switch Sources{source_i}
                    case 'NEOB'
                        MeteorReport.Duration_s(table_i) = sdb_MeteorData.(EventIDs{event_i}).Trajectory.(Sources{source_i})(1).attachments{1}.duration;
                        
                end
                
                
                table_i = table_i + 1;
                clear temp*
            end                        
        end
    end
end

MeteorReport