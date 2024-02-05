% ANALYZE_NEARBY Locate nearby sensors
% This script is part of STREWNALYZE, but it can be re-run after sensor
% database updates to refresh the list

% Start logging
diary([getSession('folders','logfolder') '\strewnlab_log.txt'])        
diary on 

logformat('Analyzing nearby sensors','INFO')

% Print trajectory data
reportevents(sdb_Events(select_i,:))

if strcmp(sdb_Events(select_i,:).DataSource{1},'AMS')
    AMS_EventID = sdb_Events(select_i,:).AMS_event_id{1};
    AMS_EventID = [AMS_EventID(12:end) '-' AMS_EventID(7:10)];
    AMS_reports_json = getams_reportsforevent(AMS_EventID);
end

% Find nearby sensors
startSensors = nearbysensors(sdb_Events.start_lat(select_i),sdb_Events.start_long(select_i),sdb_Events.start_alt(select_i)/1000,sdb_Sensors);
endSensors = nearbysensors(sdb_Events.end_lat(select_i),sdb_Events.end_long(select_i),sdb_Events.end_alt(select_i)/1000,sdb_Sensors);

% merge start and end tables
SensorSummary = [endSensors; startSensors];
[C,IA,IC] = unique(SensorSummary.StationID,'first');
SensorSummary = SensorSummary(IA,:);

% Replace missing data
SensorSummary.City(ismissing(SensorSummary.City)) = "";

% Calculate score for each sensor
for sensor_i = 1:size(SensorSummary,1)
    
    % IMPORTANT: Locality must be provided to prevent excessive Google queries
    [SensorSummary.score(sensor_i), SensorSummary.data_name{sensor_i}] = scoresensor( SensorSummary.LAT(sensor_i), SensorSummary.LONG(sensor_i), SensorSummary.Altitude_m(sensor_i), sdb_Events.start_lat(select_i), sdb_Events.start_long(select_i), sdb_Events.start_alt(select_i), sdb_Events.end_lat(select_i), sdb_Events.end_long(select_i), sdb_Events.start_alt(select_i), convertStringsToChars(SensorSummary.City{sensor_i}), SimEventID, convertStringsToChars(SensorSummary.StationID{sensor_i}), SensorSummary.sensorAZ(sensor_i), SensorSummary.sensor_hor_FOV(sensor_i), SensorSummary.sensorELEV(sensor_i), SensorSummary.sensor_vert_FOV(sensor_i));
end

% Add a hyperlink in the command window
SensorSummary.Link1 = strcat('<a href="', SensorSummary.Hyperlink1, '">Link1</a>');
SensorSummary = movevars(SensorSummary, 'Link1', 'Before', 'Type');
SensorSummary.Link2 = strcat('<a href="', SensorSummary.Hyperlink2, '">Link2</a>');
SensorSummary = movevars(SensorSummary, 'Link2', 'Before', 'Type');

logformat('Sensor analysis complete.','INFO')

% Sort the data, ascending by sensor range, then by type
SensorSummary = sortrows(SensorSummary,["Type","score"],'descend')

% Stop logging
diary off
