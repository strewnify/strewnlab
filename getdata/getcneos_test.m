function [ CNEOS_data ] = getcneos_test(startdate, enddate) 
%[ CNEOS_data ] = GETCNEOS()    Downloads and processes fireball data from
%the CNEOS database into a data table.

% Load config
strewnconfig

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

nowtime_utc = datetime('now','TimeZone','UTC');

% Open a waitbar
handleCNEOS = waitbar(0,'Downloading CNEOS Fireball Data...'); 

try
    CNEOS_raw = webread('https://ssd-api.jpl.nasa.gov/fireball.api?vel-comp=1',webread_options);
catch
    error('CNEOS database access failed!  Check internet connection.')
end
CNEOS_numrecords = str2double(CNEOS_raw.count);

% check that data fields match expected format
if ~all(ismember(CNEOS_raw.fields,{'date';'energy';'impact-e';'lat';'lat-dir';'lon';'lon-dir';'alt';'vel';'vx';'vy';'vz'}))
    error('CNEOS data format unexpected! Contact developer for help.')
end

CNEOS_fields = {'DatetimeUTC' 'peak_Lat' 'peak_Long' 'peak_Height_km' 'peak_Speed_kps' 'RadiatedEnergy_J' 'ImpactEnergy_kt' 'peak_vx_ECEF_kps' 'peak_vy_ECEF_kps' 'peak_vz_ECEF_kps'};
InitCells = {datetime(1900,1,1,'TimeZone','UTC') 0 0 0 0 0 0 0 0 0};
CNEOS_data = cell2table(InitCells,'VariableNames',CNEOS_fields);

for event_i = 1:CNEOS_numrecords
    
     % Update waitbar
    waitbar(event_i/CNEOS_numrecords,handleCNEOS,'Loading Fireball Events from CNEOS');
    
    % convert empty cells to NaN
    empties = cellfun('isempty',CNEOS_raw.data{event_i});
    CNEOS_raw.data{event_i}(empties) = {'NaN'};
    
    % Clear previous row data
    CNEOS_row = {NaT NaN NaN NaN NaN NaN NaN NaN NaN NaN}; % Batman
    
    % process data
    CNEOS_row{1} = datetime(CNEOS_raw.data{event_i}{1},'InputFormat','yyyy-MM-dd HH:mm:ss','Timezone','UTC');
    if strcmp(CNEOS_raw.data{event_i}(5),'N')
        CNEOS_row{2} = str2num(cell2mat(CNEOS_raw.data{event_i}(4))); % northern latitude
    elseif strcmp(CNEOS_raw.data{event_i}(5),'S')
        CNEOS_row{2} = -str2num(cell2mat(CNEOS_raw.data{event_i}(4))); % southern latitude
    end
    if strcmp(CNEOS_raw.data{event_i}(7),'E')
        CNEOS_row{3} = str2num(cell2mat(CNEOS_raw.data{event_i}(6))); % eastern longitude
    elseif strcmp(CNEOS_raw.data{event_i}(7),'W')
        CNEOS_row{3} = -str2num(cell2mat(CNEOS_raw.data{event_i}(6))); % western longitude    
    end
    CNEOS_row{4} = str2num(CNEOS_raw.data{event_i}{8}); % peak height, km
    CNEOS_row{6} = str2num(CNEOS_raw.data{event_i}{2}) * 10^10; % total radiated energy, J
    CNEOS_row{7} = str2num(CNEOS_raw.data{event_i}{3}); % total impact energy, kt
    CNEOS_row{8} = str2num(CNEOS_raw.data{event_i}{10}); % vx, km/s ECEF
    CNEOS_row{9} = str2num(CNEOS_raw.data{event_i}{11}); % vy, km/s ECEF
    CNEOS_row{10} = str2num(CNEOS_raw.data{event_i}{12}); % vz, km/s ECEF
    CNEOS_row{5} = round(norm([CNEOS_row{8} CNEOS_row{9} CNEOS_row{10}]),3); % speed, km/s
    CNEOS_data = [CNEOS_data;{CNEOS_row{1:10}}];
end

waitbar(event_i/CNEOS_numrecords,handleCNEOS,'Post-Processing CNEOS Data');
CNEOS_data(1,:) = []; % delete initialization row

% Filter events by date
if nargin > 0
    % if timezone is empty, assume UTC
    if isempty(startdate.TimeZone) || ~strcmp(startdate.TimeZone,'UTC')
        startdate.TimeZone = 'UTC';
    end
    if isempty(enddate.TimeZone) || ~strcmp(enddate.TimeZone,'UTC')
        enddate.TimeZone = 'UTC';
    end

    % Clip min date for source database
    mindate = datetime(500,1,1,'TimeZone','UTC'); % No min date
    if isnat(startdate) || startdate < mindate
        startdate = mindate;
    end
    if isnat(enddate) || enddate > nowtime_utc
        enddate = nowtime_utc;
    end
    
    % Filter by date
    CNEOS_data = CNEOS_data(CNEOS_data.DatetimeUTC >= startdate & CNEOS_data.DatetimeUTC <= enddate,:);
end

% Post processing - array functions
[CNEOS_data.peak_vNorth_kps,CNEOS_data.peak_vEast_kps,CNEOS_data.peak_vDown_kps] = ecef2nedv(CNEOS_data.peak_vx_ECEF_kps,CNEOS_data.peak_vy_ECEF_kps,CNEOS_data.peak_vz_ECEF_kps,CNEOS_data.peak_Lat,CNEOS_data.peak_Long);
CNEOS_data.Bearing_deg = wrapTo360(90 - atan2d(CNEOS_data.peak_vNorth_kps,CNEOS_data.peak_vEast_kps)); % bearing angle (heading azimuth)
CNEOS_data.ZenithAngle_deg = atand(sqrt(CNEOS_data.peak_vNorth_kps.^2+CNEOS_data.peak_vEast_kps.^2)./CNEOS_data.peak_vDown_kps);  % incidence angle from vertical

% Delete intermediate data
CNEOS_data.peak_vNorth_kps = [];
CNEOS_data.peak_vEast_kps = [];
CNEOS_data.peak_vDown_kps = [];

CNEOS_data.ImpactEnergyEst_kt = CNEOS_data.ImpactEnergy_kt;
CNEOS_data.Hyperlink1 = repmat({'https://cneos.jpl.nasa.gov/fireballs/'},[CNEOS_numrecords 1]);

% Assign EventID
CNEOS_data.EventID_nom = arrayfun(@eventid,CNEOS_data.peak_Lat,CNEOS_data.peak_Long,CNEOS_data.DatetimeUTC,'UniformOutput',false);
CNEOS_data.SourceKey = CNEOS_data.EventID_nom;

% Add timestamp
CNEOS_data.DateAccessed(:) = nowtime_utc; 

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from CNEOS',size(CNEOS_data,1)),'DATA')

% close waitbar
 close(handleCNEOS)
