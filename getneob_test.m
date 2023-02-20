function [ NEOB_data ] = getneob_test(startdate, enddate) 
%[ NEOB_data ] = GETNEOB(STARTDATE, ENDDATE)    Downloads and processes fireball data from
%the NASA "neo-bolide" database into a data table.

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
handleNEOB = waitbar(0,'Downloading NEO-Bolide Data...'); 

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Set metadata
nowtime_utc = datetime('now','TimeZone','UTC'); 

if ~exist('NEOB_raw','var')
    try
        NEOB_raw = webread('https://neo-bolide.ndc.nasa.gov/service/event/public',webread_options);
    catch
        error('NEOB database access failed!  Check internet connection.')
    end
end
NEOB_numrecords = size(NEOB_raw.data,1);

% % check that data fields match expected format
% if ~all(ismember(NEOB_raw.fields,{'date';'energy';'impact-e';'lat';'lat-dir';'lon';'lon-dir';'alt';'vel';'vx';'vy';'vz'}))
%     error('NEOB data format unexpected! Contact developer for help.')
% end

% This didn't work when the new records had a different number of variables
% NEOB_data = struct2table(NEOB_raw.data{1},'AsArray',true);
% for i = 1:NEOB_numrecords
%     temp = struct2table(NEOB_raw.data{i},'AsArray',true);
%     try
%         NEOB_data = [NEOB_data; temp];
%     catch
%         NEOB_data = outerjoin(temp,NEOB_data,'MergeKeys',true);
%     end
% end

NEOB_data = table;
for record_i = 1:NEOB_numrecords
    
    % Update waitbar
    waitbar(record_i/NEOB_numrecords,handleNEOB,'Loading Events from NEO Bolide Database');
    
    % Parse record data
    temp_fieldnames = fieldnames(NEOB_raw.data{record_i});
    temp_numfields = numel(temp_fieldnames);
    for field_i = 1:temp_numfields
        
        % Parse field data
        temp_data = NEOB_raw.data{record_i}.(temp_fieldnames{field_i});
        if ~isempty(temp_data)
            if strcmp(temp_fieldnames{field_i},'datetime')
                NEOB_data.DatetimeUTC(record_i,1) = datetime(temp_data,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','Timezone','UTC');
            
            elseif ischar(temp_data) || isstruct(temp_data) || iscell(temp_data)
                NEOB_data.(temp_fieldnames{field_i})(record_i,1) = {temp_data};
            
            else
                NEOB_data.(temp_fieldnames{field_i})(record_i,1) = temp_data;
            
            end
        end
    end
end

% Post processing - array functions
% NEOB_data.entry_Mass_kg = round(Ev2mass(NEOB_data.ImpactEnergy_kt,NEOB_data.ref_Speed_kps.*1000),0);
% [NEOB_data.ref_vNorth_kps,NEOB_data.ref_vEast_kps,NEOB_data.ref_vDown_kps] = ecef2nedv(NEOB_data.ref_vx_ECEF_kps,NEOB_data.ref_vy_ECEF_kps,NEOB_data.ref_vz_ECEF_kps,NEOB_data.ref_Lat,NEOB_data.ref_Long);
% NEOB_data.Bearing_deg = round(wrapTo360(90 - atan2d(NEOB_data.ref_vNorth_kps,NEOB_data.ref_vEast_kps)),3); % bearing angle (heading azimuth)
% NEOB_data.ZenithAngle_deg = round(atand(sqrt(NEOB_data.ref_vNorth_kps.^2+NEOB_data.ref_vEast_kps.^2)./NEOB_data.ref_vDown_kps),3);  % incidence angle from vertical
NEOB_data.ref_Description = repmat({'Peak Intensity'},[NEOB_numrecords,1]);
%NEOB_data.ImpactEnergyEst_kt = NEOB_data.ImpactEnergy_kt;
NEOB_data.DateAccessed = repmat(nowtime_utc,[NEOB_numrecords,1]);

%temporary
%NEOB_data.entry_Speed_kps = NEOB_data.ref_Speed_kps;
NEOB_data.ref_Lat = NEOB_data.latitude;
NEOB_data.ref_Long = NEOB_data.longitude;

% Post processing - complex functions for each record
for record_i = 1:NEOB_numrecords
    
    % Get energy estimates
    NEOB_data.RadiatedEnergy_J(record_i) = 0;
    try
        bright_fields = fields(NEOB_data.brightness{record_i});        
        % check for GLM-16 and GLM-17
        for bright_idx = 1:size(bright_fields,1)
            if NEOB_data.brightness{record_i}.(bright_fields{bright_idx}).value > NEOB_data.RadiatedEnergy_J(record_i)
                NEOB_data.RadiatedEnergy_J(record_i) = NEOB_data.brightness{record_i}.(bright_fields{bright_idx}).value;
            end
        end        
    catch
        %error('failed to retrieve brightness.')
    end
    if NEOB_data.RadiatedEnergy_J(record_i) == 0
        NEOB_data.RadiatedEnergy_J(record_i) = NaN;
    end
    
    % Set Hyperlinks
    NEOB_data.Hyperlink1(record_i) = {['https://neo-bolide.ndc.nasa.gov/#/eventdetail/' NEOB_data.x_id{record_i} ]};
end

% Array functions
NEOB_data.ImpactEnergyEst_kt = rad2impact(NEOB_data.RadiatedEnergy_J .* 4.3e22); % NEOB radiated energy experimental correction factor

% % Filter out small events
% if contains('ImpactEnergyEst_kt',NEOB_data.Properties.VariableNames)
%     energy_filter = (NEOB_data.ImpactEnergyEst_kt > 0.001);
% else
%     error('NEOB data read error. Unexpected data format.')
% end
% NEOB_data = NEOB_data(energy_filter,:);


% Assign keys
NEOB_data.SourceKey = NEOB_data.x_id;
NEOB_data.EventID_nom = arrayfun(@eventid,NEOB_data.ref_Lat,NEOB_data.ref_Long,NEOB_data.DatetimeUTC,'UniformOutput',false);

% Filter events before dayhistory
NEOB_data = NEOB_data(NEOB_data.DatetimeUTC >= startdate & NEOB_data.DatetimeUTC <= enddate,:);

% Standardize output data
NEOB_data.DateAccessed(:) = nowtime_utc; % Add timestamp
NEOB_data = standardize_tbdata(NEOB_data); % Convert units and set column order

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from NEOB',size(NEOB_data,1)),'DATA')

% close waitbar
 close(handleNEOB)
