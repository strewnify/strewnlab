function [ GMN_data ] = getgmn(startdate,enddate)
% GMN_DATA = GETGMN()    Download the Global Meteor Network database.  

% Load config
strewnconfig
nowtime_utc = datetime('now','TimeZone','UTC');

% Data folder
GMNfolder = [datafolder '\GMN'];
if ~(exist(GMNfolder,'dir')==7)
    mkdir(GMNfolder) % create folder
end

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

% Create an array of needed filenames
nom_startdate = datetime(year(startdate),month(startdate),15);
nom_enddate = datetime(year(enddate),month(enddate),15);
nom_dates = nom_startdate:calmonths(1):nom_enddate;
filenames = strcat('traj_summary_monthly_',cellstr(datestr(nom_dates,'yyyymm')),'.txt');
nummonths = length(filenames);

% Open a waitbar
handleGMN = waitbar(0,'Downloading Global Meteor Network data...'); 

% Disable warnings
warning('off','MATLAB:table:RowsAddedExistingVars');
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

% Change directory
cd(GMNfolder)

% Download files
for month_i = 1:nummonths
    
    % Update waitbar
    waitbar(month_i/nummonths, handleGMN,sprintf('Accessing Global Meteor Network data... %s',datestr(nom_dates(month_i),'mmm yyyy'))); 
        
    % If the file doesn't exist or it is the current month, download it
    if exist(filenames{month_i}, 'file') ~= 2 ||...
            ((month(datetime('now')) == month(nom_dates(month_i))) && (year(datetime('now')) == year(nom_dates(month_i))))
        try
            % Import the file
            urlwrite(['https://globalmeteornetwork.org/data/traj_summary_data/monthly/' filenames{month_i}],filenames{month_i});
            
        catch
             logformat(['GMN data not found for ' datestr(datetime(),'mmmm yyyy') '!  No reports exist or internet connection.'],'WARN')
        end
    end
end

% Read files
GMN_raw = table; % intialize table
for month_i = 1:nummonths
    
    % Update waitbar
    waitbar(month_i/nummonths, handleGMN,sprintf('Reading Global Meteor Network data... %s',datestr(nom_dates(month_i),'mmm yyyy'))); 
    
    % Read table data and append
    if exist(filenames{month_i}, 'file') == 2
        try
            try
                GMN_raw = [GMN_raw; readtable(filenames{month_i})];
            catch
                
                % convert {'None'} cell values to NaN
                GMN_raw.x____14(strcmp(GMN_raw.x____14,'None')) = {'NaN'};
                S = sprintf('%s ', GMN_raw.x____14{:});
                GMN_raw.x____14 = sscanf(S, '%f');
                
                % Try appending again
                GMN_raw = [GMN_raw; readtable(filenames{month_i})];
            end
        catch
            logformat(sprintf('Error reading %s.  Could not append to GMN data.',filenames{month_i}),'DEBUG')
        end
    end
    
end

% Go back to main directory
cd(mainfolder)

%Need to fix this
%Warning: Column headers from the file were modified to make them valid MATLAB
%identifiers before creating variable names for the table. The original column
% headers are saved in the VariableDescriptions property.
% Set 'VariableNamingRule' to 'preserve' to use the original column headers as
% table variable names. 

% Rename Variables
source_varnames = GMN_raw.Properties.VariableNames;
logformat('GMN variable names not robust to changes','DEBUG')
% Need to add source_varnames = ...
db_varnames = [{'SourceKey'} {'Beginning'} {'Beginning_1'} {'IAU'} {'IAU_1'} {'SolLon'} {'AppLST'} {'RAgeo'} {'err_RAgeo'} {'DECgeo'} {'err_DECgeo'} {'LAMgeo'} {'err_LAMgeo'}];
db_varnames = [db_varnames {'BETgeo'} {'err_BETgeo'} {'Vgeo'} {'err_Vgeo'} {'LAMhel'} {'err_LAMhel'} {'BEThel'} {'err_BEThel'} {'Vhel'} {'err_Vhel'} {'a'} {'err_a'} {'e'} {'err_e'} {'i'} {'err_i'}];
db_varnames = [db_varnames {'peri'} {'err_peri'} {'node'} {'err_node'} {'Pi'} {'err_Pi'} {'b'} {'err_b'} {'q'} {'err_q'} {'f'} {'err_f'} {'M'} {'err_M'} {'Q'} {'err_Q'} {'n'} {'err_n'} {'T'} {'err_T'}];
db_varnames = [db_varnames {'TisserandJ'} {'err_TisserandJ'} {'RAapp'} {'err_RAapp'} {'DECapp'} {'err_DECapp'} {'Azim_plusE'} {'err_Azim_plusE'} {'ref_ElevationAngle_deg'} {'err_Elev'} {'entry_Speed_kps'} {'err_entry_Speed_kps'} {'Vavg_kps'} {'err_Vavg_kps'}];
db_varnames = [db_varnames {'entry_Lat'} {'err_entry_Lat'} {'entry_Long'} {'err_entry_Long'} {'entry_Height_km'} {'err_entry_Height_km'} {'end_Lat'} {'err_end_Lat'} {'end_Long'} {'err_end_Long'} {'end_Height_km'} {'err_end_Height_km'}];
db_varnames = [db_varnames {'duration_s'} {'PeakMag'} {'PeakHt_km'} {'F'} {'entry_Mass_kg'} {'Qc'} {'MedianFitErr'} {'BegIn'} {'EndIn'} {'NumStations'} {'ParticipatingStations'}];
GMN_raw = renamevars(GMN_raw, source_varnames, db_varnames);

% Filter out small events
if contains('Peak',GMN_raw.Properties.VariableNames) && contains('entry_Speed_kps',GMN_raw.Properties.VariableNames) && contains('entry_Mass_kg',GMN_raw.Properties.VariableNames)
    GMN_raw.ImpactEnergyEst_kt = mv2energy(GMN_raw.entry_Mass_kg, GMN_raw.entry_Speed_kps.*1000);    
    fireball_filter = ((GMN_raw.PeakMag < mag_fireball) | (GMN_raw.ImpactEnergyEst_kt > ImpactEnergy_min_kt)) & (GMN_raw.end_Height_km < end_alt_max_km);
else
    error('GMN data read error. Unexpected data format.')
end
GMN_data = GMN_raw(fireball_filter,:);

GMN_numrecords = size(GMN_data,1);

% Post processing
GMN_data.DatetimeUTC = datetime(GMN_data.Beginning_1,'InputFormat','yyyy-MM-dd HH:mm:ss.sss','Timezone','UTC');
GMN_data.Hyperlink1 = repmat({'https://globalmeteornetwork.org/data/'},[GMN_numrecords 1]);
GMN_data.DateAccessed = repmat(nowtime_utc,[GMN_numrecords 1]);

% Post processing

% Assign EventID
GMN_data.EventID_nom = arrayfun(@eventid,GMN_data.end_Lat,GMN_data.end_Long,GMN_data.DatetimeUTC,'UniformOutput',false);

% Filter events before dayhistory
GMN_data = GMN_data(GMN_data.DatetimeUTC >= startdate & GMN_data.DatetimeUTC <= enddate,:);

% Add timestamp
GMN_data.DateAccessed(:) = nowtime_utc; 

% Re-enable warnings
warning('on','MATLAB:table:RowsAddedExistingVars');
warning('on','MATLAB:table:ModifiedAndSavedVarnames');

% Log
logformat(sprintf('%0.0f records retrieved from GMN',size(GMN_data,1)),'DATA')

% close waitbar
close(handleGMN)
