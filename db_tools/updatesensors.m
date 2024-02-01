% UPDATESENSORS Update the sensor database with the latest sensor data
% Get global seismic station inventory
% More to come...

% Global seismic data is available here
URL_seismic_stationinventory = 'http://seisan.ird.nc/USGS/mirror/neic.usgs.gov/neis/gis/station_comma_list.txt';

seismic_inventoryfile = 'seismicdata'; % save filename

% If the waitbar was closed, open a new one
if ~exist('WaitbarHandle','var') || ~ishghandle(WaitbarHandle)
    WaitbarHandle = waitbar(0,'Downloading Global Seismic Station Inventory...'); 
else
    waitbar(0,WaitbarHandle,'Downloading Global Seismic Station Inventory...');
end

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

% Get current time
nowtime = datetime('now','TimeZone','UTC');

cd(getSession('folders','remotefolder'); % change working directory to the remote data folder

outfilename = websave(seismic_inventoryfile,URL_seismic_stationinventory,webread_options); % save the file
%outfilename = ftpsave(seismic_inventoryfile,URL_seismic_stationinventory); % save the file    

% return to working directory
cd(getSession('folders','mainfolder')); 

%EventData_ProcessedIGRA(1,:) = []; % delete initialization row
waitbar(1,WaitbarHandle,'Data Processing Complete.');
pause(0.5);