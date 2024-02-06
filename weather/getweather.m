%GETWEATHER  Get radiosonde weather balloon data from file

%   GETWEATHER downloads and processes weather balloon data from the IGRA 
%   database  The algorithm will attempt to find a target number of datasets
%   data with a given radius.  If the data is not available, it will 
%   download all the available data in the given radius.
%
%   Program written by Jim Goodall, July 2019

% Load config file
if ~exist('check_configloaded','var') || ~check_configloaded
    strewnconfig
end

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

% Get current time
nowtime = datetime('now','TimeZone','UTC');

% Load event data
if ~exist('check_eventdataloaded','var') || ~check_eventdataloaded
    error('Event data not loaded!')
end

% Initialize points for lookup
numsteps = 100; % number of points = numsteps + 1
A = [endlocation(1) endlocation(2) endposition(3)];
B = [startlocation(1) startlocation(2) startposition(3)];
AB  = B - A;
nAB = AB ./ sqrt(sum(AB .^ 2, 2));   % Normalize
stepsize = norm(AB)/numsteps;

clear EventData_latitudes
clear EventData_longitudes
clear EventData_altitudes
point = A;
for step = 1:(numsteps + 1)
    EventData_latitudes(step,1) = point(1);
    EventData_longitudes(step,1) = point(2);
    EventData_altitudes(step,1) = point(3);
    point = point + stepsize * nAB;
end
EventData_altitudes_km = EventData_altitudes/1000; % km axis for plotting


% Check for previous failure
if ~exist('weatherdatamissing','var')
    weatherdatamissing = true;
end

% If the waitbar was closed, open a new one
if ~exist('WaitbarHandle','var') || ~ishghandle(WaitbarHandle)
    WaitbarHandle = waitbar(0,'Loading Weather Balloon Data...'); 
end

% Maximum distance in kilometers to attempt to find radiosonde stations
if (nom_lat > 60 || nom_lat < -40)
    IGRA_Radius_km = 3000; 
else
    IGRA_Radius_km = 1500; 
end

weatherdatadelay = days(4); % maximum time that weather data availability can be delayed

% Convert units
IGRA_Radius = IGRA_Radius_km * 1000;  % kilometers to meters

% Initialize entry time
if ~exist('effective_entrytime','var')
    effective_entrytime = entrytime;
end

% If the event was less than 3 days ago, weather data may not yet be available
if ~exist('user_weatherchoice','var') && weatherdatamissing && days(nowtime-entrytime) < 3
    user_weatherchoice = questdlgtimeout(60,'The event occurred recently, so weather data may not yet be available...','Recent Event Warning','Use Generic Data','Try Anyway','Stop','Use Generic Data');

    switch user_weatherchoice
        case 'Use Generic Data'
            effective_entrytime = effective_entrytime - days(1);
        case 'Stop'
            error('Program terminated by user.  Weather data files are updated once per day, in the early morning US Eastern Time. The latest observations usually become available within two calendar days of when they were taken.');
    end
end

cd(getSession('folders','weatherfolder')); % change working directory to weather folder

% Keep looking for data until enough is found.
while weatherdatamissing
    entryhour = hour(effective_entrytime);
    
    % Round to the nearest 12 hour UTC time to match radiosonde measurement times
    if strcmp(SimulationName,'Hamburg')
        warning('Hamburg weather data analysis')
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),0,0,0,'TimeZone','UTC');
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC');
    elseif entryhour <= 1
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC') - days(1);
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC');
    elseif entryhour <= 9 
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),0,0,0,'TimeZone','UTC');
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC');        
    elseif entryhour <= 14
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),0,0,0,'TimeZone','UTC');
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),0,0,0,'TimeZone','UTC') + days(1);
    elseif entryhour <= 21
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC');
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),0,0,0,'TimeZone','UTC') + days(1);
    else
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC');
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC') + days(1);
    end
    
    if exist('weathergeneric','var') && weathergeneric == true
        effective_entrytime = entrytime - days(5);
        StartDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC') - days(2);
        EndDate = datetime(year(effective_entrytime),month(effective_entrytime),day(effective_entrytime),12,0,0,'TimeZone','UTC') + days(2);
        devwarning('GETWEATHER');
    end
    

    
    % if this is the first run, get station inventory
    if ~exist('IGRA_Nearby','var')
        % Check for up-to-date station inventory list
        if exist(IGRA_stationinventoryfile, 'file') == 2

            file = dir(IGRA_stationinventoryfile);
            file_updated = datetime(file.date,'TimeZone',getSession('env','TimeZone'));

            % check if the file is up to date
            % weather data is not guaranteed to be posted until two a few days after it happens
            if year(file_updated) < year(nowtime) 
                download_stationinventory = true;
            else
                download_stationinventory = false;
            end
        else
            download_stationinventory = true;
        end

        % If needed, download a new data file
        if download_stationinventory
            waitbar(0,WaitbarHandle,'Downloading Weather Station Inventory');
            URL = [URL_IGRA_stationinventorydir IGRA_stationinventoryfile];
            %outfilename = websave(IGRA_stationinventoryfile,URL,webread_options); % save the file
            outfilename = ftpsave(IGRA_stationinventoryfile,URL); % save the file
        end
        clear download_stationinventory

        % Define header and initialize table
        IGRA_SIheader = {'StationID' 'LAT' 'LONG' 'Elevation' 'State' 'StationName' 'StartYear' 'EndYear' 'Unknown'};
        InitCells = {'init' 0 0 0 'init' 'init' 1900 1900 9999};
        clear IGRA_SItable
        IGRA_SItable = cell2table(InitCells,'VariableNames',IGRA_SIheader);

        % open the station inventory file
        FID = fopen(IGRA_stationinventoryfile);

        % Read each record in station inventory file
        stationprogress = 0;
        globalstationcount = 2788; % estimated number of stations for waitbar
        while ~feof(FID)

            % Update waitbar
            waitbar(stationprogress/globalstationcount,WaitbarHandle,'Reviewing WeatherStation Inventory');

            % Get the next line from the file
            line = fgetl(FID);

            IGRA_SIdata(1) = {line(1:11)}; % StationID
            IGRA_SIdata(2) = {str2double(line(13:20))}; % LAT
            IGRA_SIdata(3) = {str2double(line(22:30))}; % LONG
            IGRA_SIdata(4) = {str2double(line(32:37))}; % Elevation
            IGRA_SIdata(5) = {line(39:40)}; % State
            IGRA_SIdata(6) = {line(42:71)}; % StationName
            IGRA_SIdata(7) = {str2double(line(73:76))}; % StartYear
            IGRA_SIdata(8) = {str2double(line(78:81))}; % EndYear
            IGRA_SIdata(9) = {str2double(line(83:88))}; % Unknown
            IGRA_SItable = [IGRA_SItable;{IGRA_SIdata{1:9}}];

            % Update waitbar counter
            stationprogress = stationprogress + 1;
        end

        IGRA_SItable(1,:) = []; % delete initialization row
        IGRA_SItable.State = strtrim(IGRA_SItable.State);
        IGRA_SItable.StationName = strtrim(IGRA_SItable.StationName);

        % Find the nearest radiosonde stations
        %IGRA_Inventory = readtable('igra2-station-list.csv');
        IGRA_SItable.Distance = distance(nom_lat,nom_long,IGRA_SItable.LAT,IGRA_SItable.LONG,getPlanet('ellipsoid_m').MeanRadius);

        IGRA_Filtered = IGRA_SItable(IGRA_SItable.EndYear >= year(StartDate),:);
        IGRA_Filtered = IGRA_Filtered(IGRA_Filtered.StartYear <= year(EndDate),:);
        EventData_IGRA_Nearby = IGRA_Filtered(IGRA_Filtered.Distance <= IGRA_Radius,:);
        
        % Sort list by distance and store nearby station ID's and their distances
        EventData_IGRA_Nearby = sortrows(EventData_IGRA_Nearby,'Distance');
        
        % Limit number of stations to 20
        EventData_IGRA_Nearby = EventData_IGRA_Nearby(1:min(size(EventData_IGRA_Nearby,1),20),:);
        numstations = size(EventData_IGRA_Nearby,1);

        IGRA_nomdistance_km = EventData_IGRA_Nearby.Distance(1:numstations)/1000;
        
        % Display 
        disp(EventData_IGRA_Nearby.StationID(1:8))
    end

    % Create a map figure
    station_fig = figure;
    set(station_fig, 'WindowState', 'maximized');
    gx = geoaxes;
    hold on

    % Plot Weather Stations
    geoscatter(EventData_IGRA_Nearby.LAT, EventData_IGRA_Nearby.LONG,'filled','b')
    text(EventData_IGRA_Nearby.LAT, EventData_IGRA_Nearby.LONG, EventData_IGRA_Nearby.StationID)

    % Plot trajectory
    geoplot(EventData_latitudes,EventData_longitudes,'k','LineWidth',4)

    % Plot reference point
    geoscatter(nom_lat,nom_long,'filled','r')
    
    % Allow user to select desired stations
    [selection_idx,usersuccess] = listdlg('ListString',EventData_IGRA_Nearby.StationID,'SelectionMode','multiple','Name','Radiosonde Station Selection', 'OKString','OK','PromptString','Select desired weather stations:','ListSize',[300,300]);
    IGRA_StationTarget = numel(selection_idx); % Target minimum number of weather stations
    
    % close the selection map
    close(station_fig)
    
    % Log selection
    logformat(['User selected ' num2str(IGRA_StationTarget) ' stations: ' strjoin(EventData_IGRA_Nearby.StationID(selection_idx), ', ')],'USER')
    if usersuccess && ~isempty(selection_idx)
        switch numel(selection_idx)
            case 1
                logformat('Single radiosonde station not supported.','ERROR')
            case 2 
                logformat('Two radiosonde stations not supported.  Unable to interpolate','ERROR')                                     
        end
    else
        logformat('User failed to select a radiosonde station.','ERROR')
    end
    
    % Sort the selected stations to the top of the list
    EventData_IGRA_Nearby = EventData_IGRA_Nearby([selection_idx setdiff(1:size(EventData_IGRA_Nearby,1),selection_idx)],:);
    
    clear ZipFileName
    clear TextFileName

    % Define header and initialize table
    VariableNames = {'DatasetIndex' 'Distance' 'StationID' 'YEAR' 'MONTH' 'DAY' 'HOUR' 'RELTIME' 'NUMLEV' 'P_SRC' 'NP_SRC' 'NOM_LAT' 'NOM_LONG' 'LVLTYPE' 'NOM_RELTIME' 'ETIME' 'Datetime' 'LAT' 'LONG' 'PRESS' 'HEIGHT' 'TEMP' 'RH' 'DPDP' 'WDIR' 'WSPD'};
    InitCells = {0 0 'init' 0 0 0 0 effective_entrytime 0 'string' 'string' 0 0 0 effective_entrytime 0 effective_entrytime 0 0 0 0 0 0 0 0 0};
    clear EventData_ProcessedIGRA
    EventData_ProcessedIGRA = cell2table(InitCells,'VariableNames',VariableNames);

    % Download data files from IGRA server and process data, until the dataset
    % target is met
    station = 1;
    stationprogress = 0;
    numstations_t1 = 0;
    numstations_t2 = 0;
    IGRA_DatasetIndex = 0;

    % If less than the target and progress is being made, continue
     while (stationprogress < IGRA_StationTarget) && (stationprogress/station > 0.2 || station < 4)


        % There seem to be two different filename formats...
        ZipFileName = [EventData_IGRA_Nearby.StationID{station} '-data.txt.zip'];
        %ZipFileName = [IGRA_Nearby.StationID{station} '.zip'];
        TextFileName(station) = cellstr([EventData_IGRA_Nearby.StationID{station} '-data.txt']);
        URL = [URL_IGRA_pordatadir ZipFileName];

        % if the file has been downloaded previously, make sure it is up to date for the current event
        if exist(TextFileName{station}, 'file') == 2

            % check if the file is up to date
            % weather data is not guaranteed to be posted until two days after 
            % it happens, so add 2 days to the entry time for validity
            file = dir(TextFileName{station});
            file_updated = datetime(file.date,'TimeZone',getSession('env','TimeZone'));
            % if it is within a few days of the event 
            % or the data has been updated in the last 4 hours
            %(and the user has not already chosen to use generic data)
            if (file_updated < (entrytime + weatherdatadelay) || (file_updated > (nowtime - hours(4))))...
                    && (~exist('user_weatherchoice','var') || ~strcmp(user_weatherchoice,'Generic'))...
                    && (~exist('skipdownload','var') || skipdownload == false)
                download_stationdata = true;
            else
                download_stationdata = false;
            end
        else
            download_stationdata = true;
        end
        
        % If needed, download a new data file
        if download_stationdata
            % Update waitbar
            waitbar(stationprogress/(IGRA_StationTarget+1),WaitbarHandle,sprintf('Downloading %s Weather Data, File %0.0f',EventData_IGRA_Nearby.StationName{station},  station));
            
            % download file
            %outfilename = websave(ZipFileName,URL,webread_options);
%             try
                outfilename = ftpsave(ZipFileName,URL);
%             catch
%                 % return to working directory
%                 cd(getSession('folders','mainfolder')); 
%                 error('FTPSAVE failed.  Check that the function is included in the project.')
%             end
            unzip(ZipFileName); % unzip the file
            delete(ZipFileName); % delete the zip
        end
        clear download_stationdata

        % Update waitbar
        waitbar((stationprogress + 0.5)/(IGRA_StationTarget+1),WaitbarHandle,sprintf('Reading Weather Data, File %0.0f\nLocation: %s', station, EventData_IGRA_Nearby.StationName{station}));

        clear header
        header = {'#initialize'};

        % open the text file
        FID = fopen(TextFileName{station});

        % Read each record in file
        while ~feof(FID)

            % Get the next line from the file
            line = fgetl(FID);

            % Check file validity
            if ~(line(1) =='#')
                warning(['Unable to process "' TextFileName{station} '", file format invalid!'])
                fclose(FID);
                break;
            end
            header(1) = {line(2:12)}; % StationID
            header(2) = {str2double(line(14:17))}; % YEAR
            header(3) = {str2double(line(19:20))}; % MONTH
            header(4) = {str2double(line(22:23))}; % DAY
            header(5) = {str2double(line(25:26))}; % HOUR
            header(6) = {line(28:31)}; % RELTIME
            header(7) = {str2double(line(33:36))}; % NUMLEV
            header(8) = {line(38:45)}; % P_SRC
            header(9) = {line(47:54)}; % NP_SRC
            header(10) = {str2double(line(56:62))}; % LAT
            header(11) = {str2double(line(64:71))}; % LONG

            YEAR = header{2};
            MONTH = header{3};
            DAY = header{4};
            HOUR = header{5};
            RELTIME = header{6};
            NUMLEV = header{7};
            LAT = header{10}/10000;
            LONG = header{11}/10000;
            nom_release_time = datetime(YEAR,MONTH,DAY,HOUR,0,0,'TimeZone','UTC');

            % if the data is before the start date, throw it away
            if (nom_release_time < StartDate)
                for i = 1:NUMLEV
                    line = fgetl(FID);
                end

            % if the data falls in the date range, store output
            elseif (nom_release_time >= StartDate) && (nom_release_time <= EndDate)

                % clear old data
                clear rawdata

                % Increment the dataset index
                IGRA_DatasetIndex = IGRA_DatasetIndex + 1;

                % Convert release time
                if strcmp(RELTIME(1:2),'99')
                    release_hour = HOUR;
                else
                    release_hour = str2double(RELTIME(1:2));
                end
                if strcmp(RELTIME(3:4),'99')
                    release_minute = 0;
                else
                    release_minute = str2double(RELTIME(3:4));
                end
                % if release hour is different from nominal hour by
                % more than 18 hours, assume it was on the previous day
                if abs(HOUR - release_hour) > 18
                    release_time = datetime(YEAR,MONTH,DAY,release_hour,release_minute,0,'TimeZone','UTC') - days(1);
                else
                    release_time = datetime(YEAR,MONTH,DAY,release_hour,release_minute,0,'TimeZone','UTC');
                end
                header(6) = {release_time}; % RELTIME

                % Read data from file
                rawdata = textscan(FID,'%f %f %f %f %f %f %f %f %f','Delimiter',{'\t','\b',' ','A','B'},'MultipleDelimsAsOne',1,'N',1);
                for i = 1:NUMLEV

                    % Convert data
                    LVLTYPE = rawdata{1}(i);
                    ETIME = rawdata{2}(i);
                    if ETIME < 0
                        ETIME = 0;
                    end
                    DATETIME = release_time + seconds(ETIME);
                    PRESS = rawdata{3}(i)/1000;
                    HEIGHT = rawdata{4}(i); 
                    TEMP = rawdata{5}(i)/10;
                    RH = rawdata{6}(i)/10;
                    DPDP = rawdata{7}(i)/10;
                    WDIR = rawdata{8}(i); 
                    WSPD = rawdata{9}(i)/10;

                    % Add row to table
                    EventData_ProcessedIGRA = [EventData_ProcessedIGRA;{IGRA_DatasetIndex IGRA_nomdistance_km(station) header{1:9} LAT LONG LVLTYPE nom_release_time ETIME DATETIME  -9999 -9999 PRESS HEIGHT TEMP RH DPDP WDIR WSPD}];
                end
            elseif (nom_release_time > EndDate)
                break;
            end
        end
        fclose(FID);

        % Recalculate filters and station count
        filt_t1 = EventData_ProcessedIGRA.RELTIME <= effective_entrytime;
        filt_t2 = EventData_ProcessedIGRA.RELTIME > effective_entrytime;
        numstations_t1 = numel(unique(EventData_ProcessedIGRA.StationID(filt_t1)));
        numstations_t2 = numel(unique(EventData_ProcessedIGRA.StationID(filt_t2)));
        stationprogress = min([numstations_t1,numstations_t2]);

        % Update station data
        filt_t1 = EventData_ProcessedIGRA.RELTIME <= effective_entrytime & ismember(EventData_ProcessedIGRA.StationID,EventData_IGRA_Nearby.StationID(station));
        filt_t2 = EventData_ProcessedIGRA.RELTIME > effective_entrytime & ismember(EventData_ProcessedIGRA.StationID,EventData_IGRA_Nearby.StationID(station));
        EventData_IGRA_Nearby.t1(station) = mean(EventData_ProcessedIGRA.Datetime(filt_t1));
        EventData_IGRA_Nearby.t2(station) = mean(EventData_ProcessedIGRA.Datetime(filt_t2));
        
        % increment station counter
        station = station + 1;
    end

    if stationprogress <= 0
        weatherdatamissing = true;
        weathergeneric = true;
        warning('No weather data found at event time, defaulting to data from a previous date.');
        effective_entrytime = effective_entrytime - days(1);        
    else
        weatherdatamissing = false; % weather data found, exit loop
        if entrytime ~= effective_entrytime
            warning(['Weather data sourced from ' datestr(effective_entrytime, 'mmmm dd, yyyy') '. Results may be innaccurate!'])
            SimulationName = [SimulationName ' - GENERIC'];
        end
    end
end

% return to working directory
cd(getSession('folders','mainfolder')); 

EventData_ProcessedIGRA(1,:) = []; % delete initialization row
IGRA_numDatasets = IGRA_DatasetIndex;
waitbar(1,WaitbarHandle,'Data Processing Complete.');
pause(0.5);

% Sort data
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HEIGHT');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HOUR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DAY');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'MONTH');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'YEAR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DatasetIndex'); 

% Delete rows where there is 
%     - no HEIGHT data
%     - windspeed is zero above 10km
% and adjust NUMLEV to match
% Level Type = 30 (this data is missing E-TIME)
toDelete = EventData_ProcessedIGRA.HEIGHT < 0 |(EventData_ProcessedIGRA.HEIGHT > 10000 & EventData_ProcessedIGRA.WSPD == 0) | (EventData_ProcessedIGRA.LVLTYPE == 30);
if ~isempty(toDelete)
    DatasetsUpdated = unique(EventData_ProcessedIGRA.DatasetIndex(toDelete)); %grab dataset indicies for deleted rows

    % Update the NUMLEV values
    for i = 1:numel(DatasetsUpdated)
        dataset = DatasetsUpdated(i);
        deleteCount = nnz(toDelete & EventData_ProcessedIGRA.DatasetIndex == dataset); % number of rows in the dataset to be deleted
        updateRows = (EventData_ProcessedIGRA.DatasetIndex == dataset); % all rows in the dataset
        EventData_ProcessedIGRA.NUMLEV(updateRows) = EventData_ProcessedIGRA.NUMLEV(updateRows) - deleteCount; % subtract the number of deleted rows from NUMLEV in each row
    end

    % Delete the rows
    EventData_ProcessedIGRA(toDelete,:) = []; % delete rows
end

% Clear invalid values
EventData_ProcessedIGRA.ETIME(EventData_ProcessedIGRA.ETIME < 0) = NaN;
EventData_ProcessedIGRA.PRESS(EventData_ProcessedIGRA.PRESS <= 0) = NaN;
EventData_ProcessedIGRA.TEMP(EventData_ProcessedIGRA.TEMP < -900) = NaN;
EventData_ProcessedIGRA.RH(EventData_ProcessedIGRA.RH < -900) = NaN;
EventData_ProcessedIGRA.DPDP(EventData_ProcessedIGRA.DPDP < -900) = NaN;

% Fill missing values in the data
for dataset = 1:IGRA_numDatasets
    filter = (EventData_ProcessedIGRA.DatasetIndex == dataset);
    numlevs = EventData_ProcessedIGRA.NUMLEV(find(EventData_ProcessedIGRA.DatasetIndex == dataset,1));

    % Resolve duplicate values of HEIGHT, important before using the "fillmissing" function
    % If there are duplicates, add a random number (less than 1 meter) to each duplicate value
    if length(unique(EventData_ProcessedIGRA.HEIGHT(filter))) ~= numlevs
        [~,uniqueindices] = unique(EventData_ProcessedIGRA.HEIGHT(filter),'stable');
        duplicates = setdiff(1:numlevs,uniqueindices);
        linearindices = find(filter);
        EventData_ProcessedIGRA.HEIGHT(linearindices(duplicates)) = EventData_ProcessedIGRA.HEIGHT(linearindices(duplicates)) + rand(numel(duplicates),1);
        clear uniqueindices
        clear duplicates
        clear linearindices
    end

    % Fill missing values by cubic spline interpolation, with respect to HEIGHT
    EventData_ProcessedIGRA(filter,{'ETIME','PRESS','HEIGHT','TEMP','RH','DPDP','WDIR','WSPD'}) = fillmissing(EventData_ProcessedIGRA(filter,{'ETIME','PRESS','HEIGHT','TEMP','RH','DPDP','WDIR','WSPD'}),'spline','SamplePoints',EventData_ProcessedIGRA.HEIGHT(filter));
end

% Clip bad values, due to spline interpolation
EventData_ProcessedIGRA.ETIME(EventData_ProcessedIGRA.ETIME < 0) = 0;
EventData_ProcessedIGRA.TEMP(EventData_ProcessedIGRA.TEMP < -273) = -273;
EventData_ProcessedIGRA.TEMP(EventData_ProcessedIGRA.TEMP > 100) = 100;
EventData_ProcessedIGRA.RH(EventData_ProcessedIGRA.RH < 0) = 0;
EventData_ProcessedIGRA.RH(EventData_ProcessedIGRA.RH > 100) = 100;
EventData_ProcessedIGRA.DPDP(EventData_ProcessedIGRA.DPDP < -273) = -273;
EventData_ProcessedIGRA.DPDP(EventData_ProcessedIGRA.DPDP > 100) = 100;
EventData_ProcessedIGRA.WDIR = wrapTo360(EventData_ProcessedIGRA.WDIR);
EventData_ProcessedIGRA.WSPD(EventData_ProcessedIGRA.WSPD < 0) = 0;

% Delete rows where there is 
%     - no HEIGHT data
%     - windspeed is zero above 10km
% and adjust NUMLEV to match
toDelete = EventData_ProcessedIGRA.HEIGHT < 0 |(EventData_ProcessedIGRA.HEIGHT > 10000 & EventData_ProcessedIGRA.WSPD == 0);
if ~isempty(toDelete)
    DatasetsUpdated = unique(EventData_ProcessedIGRA.DatasetIndex(toDelete)); %grab dataset indicies for deleted rows

    % Update the NUMLEV values
    for i = 1:numel(DatasetsUpdated)
        dataset = DatasetsUpdated(i);
        deleteCount = nnz(toDelete & EventData_ProcessedIGRA.DatasetIndex == dataset); % number of rows in the dataset to be deleted
        updateRows = (EventData_ProcessedIGRA.DatasetIndex == dataset); % all rows in the dataset
        EventData_ProcessedIGRA.NUMLEV(updateRows) = EventData_ProcessedIGRA.NUMLEV(updateRows) - deleteCount; % subtract the number of deleted rows from NUMLEV in each row
    end

    % Delete the rows
    EventData_ProcessedIGRA(toDelete,:) = []; % delete rows
end

% Simulate Radiosonde Balloon Flight
% Inputs include ETIME, NOM_LAT, NOM_LONG, WSPD, WDIR
numrows = size(EventData_ProcessedIGRA,1);
row = 1;
while row <= numrows
    % Update waitbar
    waitbar(row/numrows,WaitbarHandle,'Simulating Weather Balloon Flight Paths');
    
    % If elapsed time is zero, initialize the location and skip to the next row
    if row == 1 || ~strcmp(EventData_ProcessedIGRA.StationID(row),EventData_ProcessedIGRA.StationID(row-1)) || EventData_ProcessedIGRA.ETIME(row) == 0 || isnan(EventData_ProcessedIGRA.ETIME(row))
        EventData_ProcessedIGRA.LAT(row) = EventData_ProcessedIGRA.NOM_LAT(row);
        EventData_ProcessedIGRA.LONG(row) = EventData_ProcessedIGRA.NOM_LONG(row);

    % Calculate new location
    else
        balloon_dt = EventData_ProcessedIGRA.ETIME(row) - ETIME_prev;
        balloon_accel = (EventData_ProcessedIGRA.WSPD(row) - WSPD_prev)/balloon_dt;
        balloon_dist = WSPD_prev * balloon_dt + 0.5 * balloon_accel * balloon_dt^2;
        AZ = mean([WDIR_prev EventData_ProcessedIGRA.WDIR(row)]); % average direction
        % convert wind source direction to balloon direction
        if AZ > 180
            AZ = AZ - 180;
        else 
            AZ = AZ + 180;
        end
        ARCLEN = 360 * balloon_dist/(2 * pi * getPlanet('ellipsoid_m').MeanRadius); % distance in degrees of arc
        [EventData_ProcessedIGRA.LAT(row), EventData_ProcessedIGRA.LONG(row)] = reckon(LAT_prev, LONG_prev, ARCLEN, AZ); 
    end     
    
    % Save previous
    ETIME_prev = EventData_ProcessedIGRA.ETIME(row);
    WSPD_prev = EventData_ProcessedIGRA.WSPD(row);
    WDIR_prev = EventData_ProcessedIGRA.WDIR(row);
    LAT_prev = EventData_ProcessedIGRA.LAT(row);
    LONG_prev = EventData_ProcessedIGRA.LONG(row);
    
    % Increment row counter
    row = row + 1;
end

% If balloon flight could not be calculated, populate nominal latitude and longitude
filt_unknownLOC = isnan(EventData_ProcessedIGRA.LAT) | isnan(EventData_ProcessedIGRA.LONG);
EventData_ProcessedIGRA.LAT(filt_unknownLOC) = EventData_ProcessedIGRA.NOM_LAT(filt_unknownLOC);
EventData_ProcessedIGRA.LONG(filt_unknownLOC) = EventData_ProcessedIGRA.NOM_LONG(filt_unknownLOC);

% Detect missing elapsed time for GRAPHBALLOONS function
EventData_elapsedtimemissing = false;
if nnz(filt_unknownLOC) > 0
    EventData_elapsedtimemissing = true;
end

% Generate gridded lookup for weather data
waitbar(0,WaitbarHandle,'Reticulating Splines');

% Calculate times for interpolation
filt_t1 = EventData_ProcessedIGRA.RELTIME <= effective_entrytime;
filt_t2 = EventData_ProcessedIGRA.RELTIME > effective_entrytime;
IGRA_t1 = mean(EventData_ProcessedIGRA.Datetime(filt_t1));
IGRA_t2 = mean(EventData_ProcessedIGRA.Datetime(filt_t2));

if IGRA_t1 > effective_entrytime
    interpfactor = 0;
elseif IGRA_t2 < effective_entrytime
    interpfactor = 1;
else
    interpfactor = ((effective_entrytime - IGRA_t1)/(IGRA_t2 - IGRA_t1));
end

% Convert wind speed and direction into north and east vector components
% north is positive, south is negative
% east is positive, west is negative
EventData_ProcessedIGRA.WINDN = EventData_ProcessedIGRA.WSPD .* cosd(EventData_ProcessedIGRA.WDIR);
EventData_ProcessedIGRA.WINDE = EventData_ProcessedIGRA.WSPD .* sind(EventData_ProcessedIGRA.WDIR);

% Interpolate wind speed vectors in 3 dimensions: latitude, longitude, and altitude
IGRA_t1_WINDN = scatteredInterpolant([EventData_ProcessedIGRA.LAT(filt_t1), EventData_ProcessedIGRA.LONG(filt_t1), EventData_ProcessedIGRA.HEIGHT(filt_t1)], EventData_ProcessedIGRA.WINDN(filt_t1),'natural','nearest');
IGRA_t1_WINDE = scatteredInterpolant([EventData_ProcessedIGRA.LAT(filt_t1), EventData_ProcessedIGRA.LONG(filt_t1), EventData_ProcessedIGRA.HEIGHT(filt_t1)], EventData_ProcessedIGRA.WINDE(filt_t1),'natural','nearest');
IGRA_t2_WINDN = scatteredInterpolant([EventData_ProcessedIGRA.LAT(filt_t2), EventData_ProcessedIGRA.LONG(filt_t2), EventData_ProcessedIGRA.HEIGHT(filt_t2)], EventData_ProcessedIGRA.WINDN(filt_t2),'natural','nearest');
IGRA_t2_WINDE = scatteredInterpolant([EventData_ProcessedIGRA.LAT(filt_t2), EventData_ProcessedIGRA.LONG(filt_t2), EventData_ProcessedIGRA.HEIGHT(filt_t2)], EventData_ProcessedIGRA.WINDE(filt_t2),'natural','nearest');

% lookup meteor path at time 1 and time 2 and interpolate wind vectors to entry time
WINDN = IGRA_t1_WINDN(EventData_latitudes,EventData_longitudes,EventData_altitudes) + interpfactor .* (IGRA_t2_WINDN(EventData_latitudes,EventData_longitudes,EventData_altitudes)-IGRA_t1_WINDN(EventData_latitudes,EventData_longitudes,EventData_altitudes));
WINDE = IGRA_t1_WINDE(EventData_latitudes,EventData_longitudes,EventData_altitudes) + interpfactor .* (IGRA_t2_WINDE(EventData_latitudes,EventData_longitudes,EventData_altitudes)-IGRA_t1_WINDE(EventData_latitudes,EventData_longitudes,EventData_altitudes));
EventData_WINDN_MODEL = griddedInterpolant(EventData_altitudes,WINDN);    
EventData_WINDE_MODEL = griddedInterpolant(EventData_altitudes,WINDE); 

% lookup model for every point in table
EventData_ProcessedIGRA.WINDN_MODEL = EventData_WINDN_MODEL(EventData_ProcessedIGRA.HEIGHT);
EventData_ProcessedIGRA.WINDE_MODEL = EventData_WINDE_MODEL(EventData_ProcessedIGRA.HEIGHT);
EventData_ProcessedIGRA.WSPD_MODEL = (EventData_ProcessedIGRA.WINDN_MODEL.^2 + EventData_ProcessedIGRA.WINDE_MODEL.^2).^0.5;
EventData_ProcessedIGRA.WDIR_MODEL = wrapTo360(atan2d(EventData_ProcessedIGRA.WINDE_MODEL,EventData_ProcessedIGRA.WINDN_MODEL));

% Calculate height in km for plotting
EventData_ProcessedIGRA.HEIGHT_km = EventData_ProcessedIGRA.HEIGHT / 1000;
EventData_ProcessedIGRA.Datenum = datenum(EventData_ProcessedIGRA.NOM_RELTIME);

% Calculate standard deviation of weather data
% Sort data by height for moving standard deviation calculation
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HEIGHT');
 
% initialize the exponentially weighted moving standard deviation (EWMSD) calculation
altitude_domain_constant = 1000; % altitude domain constant, equivalent to a time constant applied to altitude
filtEWMSD_init = EventData_ProcessedIGRA.HEIGHT < (ground + 1000); % identify data used to initialize the EWMSD
EventData_ProcessedIGRA.EWMSD_WINDN(1) = sqrt(sum((EventData_ProcessedIGRA.WINDN(filtEWMSD_init)-EventData_ProcessedIGRA.WINDN_MODEL(filtEWMSD_init)).^2)/(nnz(filtEWMSD_init)));
EventData_ProcessedIGRA.EWMSD_WINDE(1) = sqrt(sum((EventData_ProcessedIGRA.WINDE(filtEWMSD_init)-EventData_ProcessedIGRA.WINDE_MODEL(filtEWMSD_init)).^2)/(nnz(filtEWMSD_init)));

% Step through each row of output data to calculate EWMSD
for row=2:numrows
    % Update waitbar
    waitbar(row/numrows,WaitbarHandle,'Analyzing Weather Data Variation');
    
    % Calculate exponentially weighted moving standard deviation (EWMSD)
    filtEWMSD = 1-exp(-(EventData_ProcessedIGRA.HEIGHT(row)-EventData_ProcessedIGRA.HEIGHT(row-1))/altitude_domain_constant);  % local filter constant, the 1st order lag filter constant, adjusted for sampling rate
    EventData_ProcessedIGRA.EWMSD_WINDN(row) = sqrt((1-filtEWMSD)*((EventData_ProcessedIGRA.EWMSD_WINDN(row-1))^2+filtEWMSD*(EventData_ProcessedIGRA.WINDN(row-1)-EventData_ProcessedIGRA.WINDN_MODEL(row-1))^2));
    EventData_ProcessedIGRA.EWMSD_WINDE(row) = sqrt((1-filtEWMSD)*((EventData_ProcessedIGRA.EWMSD_WINDE(row-1))^2+filtEWMSD*(EventData_ProcessedIGRA.WINDE(row-1)-EventData_ProcessedIGRA.WINDE_MODEL(row-1))^2));
end

% Calculate wind speed variation
% uses WindSigma defined in config file
EventData_ProcessedIGRA.WINDN_MIN = EventData_ProcessedIGRA.WINDN_MODEL - WindSigma .* EventData_ProcessedIGRA.EWMSD_WINDN;
EventData_ProcessedIGRA.WINDN_MAX = EventData_ProcessedIGRA.WINDN_MODEL + WindSigma .* EventData_ProcessedIGRA.EWMSD_WINDN;
EventData_ProcessedIGRA.WINDE_MIN = EventData_ProcessedIGRA.WINDE_MODEL - WindSigma .* EventData_ProcessedIGRA.EWMSD_WINDE;
EventData_ProcessedIGRA.WINDE_MAX = EventData_ProcessedIGRA.WINDE_MODEL + WindSigma .* EventData_ProcessedIGRA.EWMSD_WINDE;

EventData_ProcessedIGRA.WSPD_MIN = (EventData_ProcessedIGRA.WINDN_MIN.^2 + EventData_ProcessedIGRA.WINDE_MIN.^2).^0.5;
EventData_ProcessedIGRA.WSPD_MAX = (EventData_ProcessedIGRA.WINDN_MAX.^2 + EventData_ProcessedIGRA.WINDE_MAX.^2).^0.5;
EventData_ProcessedIGRA.WDIR_MIN = wrapTo360(atan2d(EventData_ProcessedIGRA.WINDE_MIN,EventData_ProcessedIGRA.WINDN_MIN));
EventData_ProcessedIGRA.WDIR_MAX = wrapTo360(atan2d(EventData_ProcessedIGRA.WINDE_MAX,EventData_ProcessedIGRA.WINDN_MAX));

% Create gridded models of wind velocity for lookup
[~,uniqueindices] = unique(EventData_ProcessedIGRA.HEIGHT);
EventData_WINDN_MIN_MODEL = griddedInterpolant(EventData_ProcessedIGRA.HEIGHT(uniqueindices),EventData_ProcessedIGRA.WINDN_MIN(uniqueindices),'linear','nearest');
EventData_WINDN_MAX_MODEL = griddedInterpolant(EventData_ProcessedIGRA.HEIGHT(uniqueindices),EventData_ProcessedIGRA.WINDN_MAX(uniqueindices),'linear','nearest');
EventData_WINDE_MIN_MODEL = griddedInterpolant(EventData_ProcessedIGRA.HEIGHT(uniqueindices),EventData_ProcessedIGRA.WINDE_MIN(uniqueindices),'linear','nearest');
EventData_WINDE_MAX_MODEL = griddedInterpolant(EventData_ProcessedIGRA.HEIGHT(uniqueindices),EventData_ProcessedIGRA.WINDE_MAX(uniqueindices),'linear','nearest');
clear uniqueindices

% Create models of air properties
altitude_step = 21
1;  % meters bewteen interpolant steps
EventData_altitudes_fine = ground:altitude_step:startaltitude;
PRESS_indices = ~isnan(EventData_ProcessedIGRA.PRESS); % valid values of pressure
TEMP_indices = ~isnan(EventData_ProcessedIGRA.TEMP); % valid values of temperature
%RH_indices = ~isnan(EventData_ProcessedIGRA.RH); % valid values of relative humidity
%DPDP_indices = ~isnan(EventData_ProcessedIGRA.DPDP); % valid values of dewpoint
datenums_fine = ones(1,numel(EventData_altitudes_fine)) .* datenum(effective_entrytime);
waitbar(0.25,WaitbarHandle,'Reticulating Splines');
try
    EventData_PRESS_Pa_2D_MODEL = fit([EventData_ProcessedIGRA.Datenum(PRESS_indices),EventData_ProcessedIGRA.HEIGHT(PRESS_indices)],EventData_ProcessedIGRA.PRESS(PRESS_indices) .* 1000,'linearinterp');
catch
    EventData_PRESS_Pa_2D_MODEL = fit([EventData_ProcessedIGRA.Datenum(PRESS_indices),EventData_ProcessedIGRA.HEIGHT(PRESS_indices)],EventData_ProcessedIGRA.PRESS(PRESS_indices) .* 1000,'lowess');
end
EventData_TEMP_2D_MODEL = fit([EventData_ProcessedIGRA.Datenum(TEMP_indices),EventData_ProcessedIGRA.HEIGHT(TEMP_indices)],EventData_ProcessedIGRA.TEMP(TEMP_indices),'lowess');
% RH_2D_MODEL = fit([EventData_ProcessedIGRA.Datenum(RH_indices),EventData_ProcessedIGRA.HEIGHT(RH_indices)],EventData_ProcessedIGRA.RH(RH_indices),'linearinterp');
% DPDP_2D_MODEL = fit([EventData_ProcessedIGRA.Datenum(DPDP_indices),EventData_ProcessedIGRA.HEIGHT(DPDP_indices)],EventData_ProcessedIGRA.DPDP(DPDP_indices),'linearinterp');
waitbar(0.5,WaitbarHandle,'Reticulating Splines');
EventData_pressure_Pa_2D_model = max(0,EventData_PRESS_Pa_2D_MODEL(datenums_fine,EventData_altitudes_fine));
waitbar(0.7,WaitbarHandle,'Reticulating Splines');
EventData_temp_2D_model = EventData_TEMP_2D_MODEL(datenums_fine,EventData_altitudes_fine);
waitbar(0.9,WaitbarHandle,'Reticulating Splines');
psurf_Pa = EventData_ProcessedIGRA.PRESS(1) * 1000;
TsurfC = EventData_ProcessedIGRA.TEMP(1);

% Calculate array of barometric properties to replace missing data
for alt_index = 1:numel(EventData_altitudes_fine)
     [baro_pressures(alt_index,1), baro_temps(alt_index,1), baro_densities(alt_index,1)] = barometric( psurf_Pa, TsurfC, ground, EventData_altitudes_fine(alt_index));
end

% Replace missing data with standard atmosphere data
p_missing = isnan(EventData_pressure_Pa_2D_model)|(EventData_pressure_Pa_2D_model==0);
T_missing = isnan(EventData_temp_2D_model);
EventData_pressure_Pa_2D_model(p_missing) = baro_pressures(p_missing);
EventData_temp_2D_model(T_missing) = baro_temps(T_missing);

% Create interpolants for barometric properties
Rspec = 287.058; % specific gas constant dry air J/(kg.K)
EventData_PRESSURE_MODEL = griddedInterpolant(EventData_altitudes_fine, EventData_pressure_Pa_2D_model,'linear','nearest');
EventData_TEMPERATURE_MODEL = griddedInterpolant(EventData_altitudes_fine, EventData_temp_2D_model,'linear','nearest');
EventData_DENSITY_MODEL = griddedInterpolant(EventData_altitudes_fine,EventData_pressure_Pa_2D_model./(Rspec.*(EventData_temp_2D_model+273.15)),'linear','nearest');

% Update progress bar
waitbar(1,WaitbarHandle,'Reticulating Splines');

% Plot the weather data
plotweather

% Sort data for output
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HEIGHT');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'HOUR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DAY');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'MONTH');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'YEAR');
EventData_ProcessedIGRA = sortrows(EventData_ProcessedIGRA,'DatasetIndex'); 

%Plot to verify data
%Unfinished plot code
% quiverscale = 0.001;
% EventData_ProcessedIGRA.DLAT = sind(EventData_ProcessedIGRA.WDIR);
% EventData_ProcessedIGRA.DLONG = cosd(EventData_ProcessedIGRA.WDIR);
% EventData_ProcessedIGRA.DALT = EventData_ProcessedIGRA.HEIGHT*0;
% axesm miller
% view(3)
% hold on
% daspect([0.05/long_metersperdeg 0.05/lat_metersperdeg 1]) %guess... miller axis unknown
% quiver3m(EventData_ProcessedIGRA.LAT,EventData_ProcessedIGRA.LONG,EventData_ProcessedIGRA.HEIGHT,EventData_ProcessedIGRA.DLAT,EventData_ProcessedIGRA.DLONG,EventData_ProcessedIGRA.DALT,quiverscale)
% quiver3m(startlocation(1),startlocation(2),startposition(3),startlocation(1)-endlocation(1),startlocation(2)-endlocation(2),-(startposition(3)-endposition(3)),'r',0)

% Update waitbar
waitbar(1,WaitbarHandle,'Writing weather data to file...');

% Output files to event folder
cd(eventfolder);

% Write the table to a CSV file 
temporary = EventData_ProcessedIGRA;
temporary.Datetime = exceltime(temporary.Datetime);
IGRA_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
clear temporary
output_filenameIGRA = [SimFilename '_RadiosondeData'];
% user_response = 'NA';
% if exist([output_filenameIGRA '.xls'], 'file') == 2
%      user_response = questdlgtimeout(60,['The file "' output_filenameIGRA '".xlsx already exists.'],'Data Already Exists','Overwrite','Rename','Stop','Overwrite');
% end
% switch user_response
%     case 'NA'
%         xlswrite(output_filenameIGRA,IGRA_xlsdata)
%         disp(['Processed weather data has been saved to "' output_filenameIGRA '.xlxs"']); 
%     case 'Overwrite'
%         try
%             delete([output_filenameIGRA '.xls']);
%             xlswrite(output_filenameIGRA,IGRA_xlsdata)
%             disp(['Processed weather data has been saved to "' output_filenameIGRA '.xlxs"']); 
%         catch
%             output_filenameIGRA = [output_filenameIGRA '_' datestr(now,'yyyymmddHHMM')];
%             xlswrite(output_filenameIGRA,IGRA_xlsdata)
%             warning(['New processed weather data has been saved to "' output_filenameIGRA '.xlxs"']); 
%         end
%     case 'Stop'
%         output_filenameIGRA = [output_filenameIGRA '_' datestr(now,'yyyymmddHHMM')];
%         xlswrite(output_filenameIGRA,IGRA_xlsdata)
%         error('Program terminated by user.\n%s',['Weather data has been saved to "' output_filenameIGRA '.xlxs"']);
%     otherwise
%         output_filenameIGRA = [output_filenameIGRA '_' datestr(now,'yyyymmddHHMM')];
         xlswrite(output_filenameIGRA,IGRA_xlsdata)
%         warning('Old weather data already exists.\n%s',['New weather data has been saved to "' output_filenameIGRA '.xlxs"']); 
% end

% Cleanup
%clear EventData_ProcessedIGRA
clear IGRA_xlsdata



% Backup data
strewnbackup

% return to main working directory
cd(getSession('folders','mainfolder')); 

% Check flag
check_weatherloaded = true;