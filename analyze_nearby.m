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
SensorSummary.StationName(ismissing(SensorSummary.StationName)) = "";
SensorSummary.Operator(ismissing(SensorSummary.Operator)) = "";
SensorSummary.City(ismissing(SensorSummary.City)) = "";
SensorSummary.cam_Model(ismissing(SensorSummary.cam_Model)) = "";
SensorSummary.Hyperlink1(ismissing(SensorSummary.Hyperlink1)) = "";
SensorSummary.Hyperlink2(ismissing(SensorSummary.Hyperlink2)) = "";
SensorSummary.Address(ismissing(SensorSummary.Address)) = "";
SensorSummary.Email(ismissing(SensorSummary.Email)) = "";
SensorSummary.Twitter(ismissing(SensorSummary.Twitter)) = "";
SensorSummary.Notes(ismissing(SensorSummary.Notes)) = "";

% Calculate score for each sensor
for sensor_i = 1:size(SensorSummary,1)
    
    % IMPORTANT: Locality must be provided to prevent excessive Google queries
    [SensorSummary.score(sensor_i), SensorSummary.data_name{sensor_i}] = scoresensor( SensorSummary.LAT(sensor_i), SensorSummary.LONG(sensor_i), SensorSummary.Altitude_m(sensor_i), sdb_Events.start_lat(select_i), sdb_Events.start_long(select_i), sdb_Events.start_alt(select_i), sdb_Events.end_lat(select_i), sdb_Events.end_long(select_i), sdb_Events.start_alt(select_i), convertStringsToChars(SensorSummary.City{sensor_i}), SimEventID, convertStringsToChars(SensorSummary.StationID{sensor_i}), SensorSummary.sensorAZ(sensor_i), SensorSummary.sensor_hor_FOV(sensor_i), SensorSummary.sensorELEV(sensor_i), SensorSummary.sensor_vert_FOV(sensor_i), SensorSummary.BaseScore(sensor_i));
end

% Sort the data, ascending by sensor range, then by type
if isempty(SensorSummary)
    logformat('Sensor analysis complete.  No sensors found!','INFO')
else
    SensorSummary = sortrows(SensorSummary,["Type","score"],'descend');
    logformat('Sensor analysis complete.','INFO')
end

% Write data to Excel file
output_filenameSensorSummary = ['testxls_' datestr(now,'yyyymmddHH') '.xlsx'];
temporary = SensorSummary;
temporary.Type = cellstr(temporary.Type);
temporary.Network = cellstr(temporary.Network);
SensorSummary_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
xlswrite(output_filenameSensorSummary,SensorSummary_xlsdata)
logformat(sprintf('Sensor summary exported to %s',output_filenameSensorSummary),'INFO')

% Add a hyperlink in the command window
SensorSummary.Link1 = strcat('<a href="', SensorSummary.Hyperlink1, '">Link1</a>');
SensorSummary = movevars(SensorSummary, 'Link1', 'Before', 'Type');
SensorSummary.Link2 = strcat('<a href="', SensorSummary.Hyperlink2, '">Link2</a>');
SensorSummary = movevars(SensorSummary, 'Link2', 'Before', 'Type');
SensorSummary

% Stop logging
diary off
