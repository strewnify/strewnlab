function [ CNEOS_data ] = getcneos() 
%[ CNEOS_data ] = GETCNEOS()    Downloads and processes fireball data from
%the CNEOS database into a data table.

% Import reference data
import_ref_data

% load webread options
strewnconfig

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

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

CNEOS_fields = {'Datetime' 'LAT' 'LONG' 'Altitude' 'Speed' 'RadiatedEnergy' 'ImpactEnergy' 'vx' 'vy' 'vz'};
InitCells = {datetime(1900,1,1) 0 0 0 0 0 0 0 0 0};
CNEOS_data = cell2table(InitCells,'VariableNames',CNEOS_fields);

for i = 1:CNEOS_numrecords
    
     % Update waitbar
    waitbar(i/CNEOS_numrecords,handleCNEOS,'Loading Fireball Events from CNEOS');
    
    % convert empty cells to NaN
    empties = cellfun('isempty',CNEOS_raw.data{i});
    CNEOS_raw.data{i}(empties) = {'NaN'};
    
    % Clear previous row data
    CNEOS_row = {NaT NaN NaN NaN NaN NaN NaN NaN NaN NaN};
    
    % process data
    CNEOS_row{1} = datetime(CNEOS_raw.data{i}{1},'InputFormat','yyyy-MM-dd HH:mm:ss');
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
    CNEOS_row{4} = str2num(CNEOS_raw.data{i}{8}); % altitude, km
    CNEOS_row{6} = str2num(CNEOS_raw.data{i}{2}); % total radiated energy, J
    CNEOS_row{7} = str2num(CNEOS_raw.data{i}{3}); % total impact energy, kt
    CNEOS_row{8} = str2num(CNEOS_raw.data{i}{10}); % vx, km/s ECEF
    CNEOS_row{9} = str2num(CNEOS_raw.data{i}{11}); % vy, km/s ECEF
    CNEOS_row{10} = str2num(CNEOS_raw.data{i}{12}); % vz, km/s ECEF
    CNEOS_row{5} = round(norm([CNEOS_row{8} CNEOS_row{9} CNEOS_row{10}]),3); % speed, km/s
    CNEOS_data = [CNEOS_data;{CNEOS_row{1:10}}];
end
CNEOS_data(1,:) = []; % delete initialization row

% Post processing
CNEOS_data.SolarElev = solarelevation(CNEOS_data.LAT,CNEOS_data.LONG,CNEOS_data.Datetime); % Calculate solar elevation
CNEOS_data.Mass = round(Ev2mass(CNEOS_data.ImpactEnergy,CNEOS_data.Speed.*1000),0);
[CNEOS_data.vNorth,CNEOS_data.vEast,CNEOS_data.vDown] = ecef2nedv(CNEOS_data.vx,CNEOS_data.vy,CNEOS_data.vz,CNEOS_data.LAT,CNEOS_data.LONG);
CNEOS_data.Bearing = round(wrapTo360(90 - atan2d(CNEOS_data.vNorth,CNEOS_data.vEast)),3); % bearing angle (heading azimuth)
CNEOS_data.Incidence = round(atand(sqrt(CNEOS_data.vNorth.^2+CNEOS_data.vEast.^2)./CNEOS_data.vDown),3);  % incidence angle from vertical
CNEOS_data.Hyperlink1(:) = {'https://cneos.jpl.nasa.gov/fireballs/'};
CNEOS_data.Hyperlink2(:) = {''};
CNEOS_data.ImpactEnergy_Est = CNEOS_data.ImpactEnergy;
CNEOS_data.ProcessDate(:) = datetime('now');

% Assign EventID
CNEOS_data.EventID = arrayfun(@eventidcalc,CNEOS_data.LAT,CNEOS_data.LONG,CNEOS_data.Datetime,'UniformOutput',false);
CNEOS_data = movevars(CNEOS_data, 'EventID', 'Before', 'Datetime');

CNEOS_data = removevars(CNEOS_data, 'vNorth');
CNEOS_data = removevars(CNEOS_data, 'vEast');
CNEOS_data = removevars(CNEOS_data, 'vDown');

% Log
logformat(sprintf('%0.0f records retrieved from CNEOS',size(CNEOS_data,1)),'DATA')

% close waitbar
 close(handleCNEOS)
