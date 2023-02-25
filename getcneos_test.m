function [ CNEOS_data ] = getcneos_test(startdate, enddate) 
%[ CNEOS_data ] = GETCNEOS()    Downloads and processes fireball data from
%the CNEOS database into a data table.

% Load config
strewnconfig
nowtime_utc = datetime('now','TimeZone','UTC');

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

CNEOS_fields = {'DatetimeUTC' 'ref_Lat' 'ref_Long' 'ref_Height_km' 'ref_Speed_kps' 'RadiatedEnergy_J' 'ImpactEnergy_kt' 'ref_vx_ECEF_kps' 'ref_vy_ECEF_kps' 'ref_vz_ECEF_kps'};
InitCells = {datetime(1900,1,1,'TimeZone','UTC') 0 0 0 0 0 0 0 0 0};
CNEOS_data = cell2table(InitCells,'VariableNames',CNEOS_fields);

for i = 1:CNEOS_numrecords
    
     % Update waitbar
    waitbar(i/CNEOS_numrecords,handleCNEOS,'Loading Fireball Events from CNEOS');
    
    % convert empty cells to NaN
    empties = cellfun('isempty',CNEOS_raw.data{i});
    CNEOS_raw.data{i}(empties) = {'NaN'};
    
    % Clear previous row data
    CNEOS_row = {NaT NaN NaN NaN NaN NaN NaN NaN NaN NaN}; % Batman
    
    % process data
    CNEOS_row{1} = datetime(CNEOS_raw.data{i}{1},'InputFormat','yyyy-MM-dd HH:mm:ss','Timezone','UTC');
    if strcmp(CNEOS_raw.data{i}(5),'N')
        CNEOS_row{2} = str2num(cell2mat(CNEOS_raw.data{i}(4))); % northern latitude
    elseif strcmp(CNEOS_raw.data{i}(5),'S')
        CNEOS_row{2} = -str2num(cell2mat(CNEOS_raw.data{i}(4))); % southern latitude
    end
    if strcmp(CNEOS_raw.data{i}(7),'E')
        CNEOS_row{3} = str2num(cell2mat(CNEOS_raw.data{i}(6))); % eastern longitude
    elseif strcmp(CNEOS_raw.data{i}(7),'W')
        CNEOS_row{3} = -str2num(cell2mat(CNEOS_raw.data{i}(6))); % western longitude    
    end
    CNEOS_row{4} = str2num(CNEOS_raw.data{i}{8}); % peak height, km
    CNEOS_row{6} = str2num(CNEOS_raw.data{i}{2}) * 10^10; % total radiated energy, J
    CNEOS_row{7} = str2num(CNEOS_raw.data{i}{3}); % total impact energy, kt
    CNEOS_row{8} = str2num(CNEOS_raw.data{i}{10}); % vx, km/s ECEF
    CNEOS_row{9} = str2num(CNEOS_raw.data{i}{11}); % vy, km/s ECEF
    CNEOS_row{10} = str2num(CNEOS_raw.data{i}{12}); % vz, km/s ECEF
    CNEOS_row{5} = round(norm([CNEOS_row{8} CNEOS_row{9} CNEOS_row{10}]),3); % speed, km/s
    CNEOS_data = [CNEOS_data;{CNEOS_row{1:10}}];
end
CNEOS_data(1,:) = []; % delete initialization row

% Post processing - array functions
CNEOS_data.entry_Mass_kg = round(Ev2mass(CNEOS_data.ImpactEnergy_kt,CNEOS_data.ref_Speed_kps.*1000),0);
[CNEOS_data.ref_vNorth_kps,CNEOS_data.ref_vEast_kps,CNEOS_data.ref_vDown_kps] = ecef2nedv(CNEOS_data.ref_vx_ECEF_kps,CNEOS_data.ref_vy_ECEF_kps,CNEOS_data.ref_vz_ECEF_kps,CNEOS_data.ref_Lat,CNEOS_data.ref_Long);
CNEOS_data.Bearing_deg = round(wrapTo360(90 - atan2d(CNEOS_data.ref_vNorth_kps,CNEOS_data.ref_vEast_kps)),3); % bearing angle (heading azimuth)
CNEOS_data.ZenithAngle_deg = round(atand(sqrt(CNEOS_data.ref_vNorth_kps.^2+CNEOS_data.ref_vEast_kps.^2)./CNEOS_data.ref_vDown_kps),3);  % incidence angle from vertical
CNEOS_data.ref_Description = repmat({'Peak Intensity'},[CNEOS_numrecords 1]);
CNEOS_data.ImpactEnergyEst_kt = CNEOS_data.ImpactEnergy_kt;
CNEOS_data.Hyperlink1 = repmat({'https://cneos.jpl.nasa.gov/fireballs/'},[CNEOS_numrecords 1]);

% Assign EventID
CNEOS_data.EventID_nom = arrayfun(@eventid,CNEOS_data.ref_Lat,CNEOS_data.ref_Long,CNEOS_data.DatetimeUTC,'UniformOutput',false);
CNEOS_data.SourceKey = CNEOS_data.EventID_nom;

% Filter events by date
CNEOS_data = CNEOS_data(CNEOS_data.DatetimeUTC >= startdate & CNEOS_data.DatetimeUTC <= enddate,:);

% Standardize output data
CNEOS_data.DateAccessed(:) = nowtime_utc; % Add timestamp
CNEOS_data = standardize_tbdata(CNEOS_data); % Convert units and set column order

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from CNEOS',size(CNEOS_data,1)),'DATA')

% close waitbar
 close(handleCNEOS)
