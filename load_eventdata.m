% LOAD_EVENTDATA loads meteor event data from an Excel file

% Load config file
strewnconfig

% Spreadsheet config
eventfilename = 'AllEventData.xlsx';
firsteventrow = 6;

% Create or update waitbar
if ~exist('WaitbarHandle','var') || ~ishghandle(WaitbarHandle)
    WaitbarHandle = waitbar(0,['Opening ' eventfilename '...']);
else
    waitbar(0,WaitbarHandle,['Opening ' eventfilename '...']);
end

% Open Event Data File
[num, txt, AllEventData] = xlsread(eventfilename, 'AllEventData');

% If event has not been selected, query user for event selection
if ~exist('eventindex','var')
    usersuccess = false;
    SimulationList = AllEventData(firsteventrow:end,2);
    try
        [eventindex,usersuccess] = listdlg('ListString',SimulationList,'SelectionMode','single','Name','Select Simulation', 'OKString','Load','PromptString','Select a Meteor Event:','ListSize',[300,300]);
    catch
        logformat('Error loading event list.  Check for extraneous data in input sheet.','ERROR')
    end
    if ~usersuccess
        clear usersuccess
        clear eventindex
        close(WaitbarHandle)
        error('No event selected. Exit program.')
    end
end

% Import event data
waitbar(0.5,WaitbarHandle,'Loading Event Data...');

% Store all data not marked as "source_" or "find_"
for column = 1:size(AllEventData,2)
    if isempty(strfind(AllEventData{3,column}, 'find_')) && isempty(strfind(AllEventData{3,column}, 'source_')) && isempty(strfind(AllEventData{3,column}, 'notes_'))
        if strcmp(AllEventData{2,column},'text')
            eval([AllEventData{3,column} ' = ''' AllEventData{(eventindex + firsteventrow - 1),column} ''';'])
        elseif strcmp(AllEventData{2,column},'bool')
            eval([AllEventData{3,column} ' = logical(' num2str(AllEventData{(eventindex + firsteventrow - 1),column}) ');'])
        else        
            eval([AllEventData{3,column} ' = ' num2str(AllEventData{(eventindex + firsteventrow - 1),column}) ';'])
        end
    end
end

% Convert Excel date and time to MATLAB format
dtstr = textscan(ImportUTC,'%f %f %f %f %f %f %s', 'Delimiter',{'/',':',' '});
if dtstr{4} == 12
        dtstr{4} = 0;
end
if strcmp(dtstr{7},'AM')
    entrytime = datetime(dtstr{3},dtstr{1},dtstr{2},dtstr{4},dtstr{5},dtstr{6},'TimeZone','UTC');
elseif strcmp(dtstr{7},'PM')
    entrytime = datetime(dtstr{3},dtstr{1},dtstr{2},dtstr{4}+12,dtstr{5},dtstr{6},'TimeZone','UTC');
else
    error('UTC Date Format Invalid');
end

% Generate Event ID
if ~exist('SimEventID_OLD','var')
    SimEventID_OLD = {};
end

% Check for updated event ID.  LOAD_EVENTDATA should only run on a new session call
% to STREWNIFY, or if the user calls it manually after updating the input sheet.
if exist('SimEventID','var') && ~strcmp(SimEventID, eventid(nom_lat, nom_long, entrytime))
    UserContinue = questdlg(['Event ID will change from ' SimEventID ' to ' eventid(nom_lat, nom_long, entrytime) '. If you continue, a new project directory will be created.  If you want to load a new event, exit and clear the workspace.'], 'Event ID Warning','Continue', 'Exit', 'Exit');
    if strcmp(UserContinue,'Continue')
        SimEventID_OLD{end + 1} = SimEventID;
        SimEventID = eventid(nom_lat, nom_long, entrytime);
    else
        error('Event ID mismatch.  Simulation aborted.')
    end        
else
    SimEventID = eventid(nom_lat, nom_long, entrytime);
end

SimVersion = input('Enter version number: ','s');

% Create filenames
syncevent

% Load previous data from file
cd(eventfolder);
if exist([SimFilename '.mat'], 'file') == 2
    eval(['load ' SimFilename])
    disp(['Data loaded from ' SimFilename '.mat'])
    
    % check if weather data is loaded
    if exist('EventData_WINDN_MIN_MODEL','var')
        check_weatherloaded = true;
    end
end
cd(getSession('folders','mainfolder'));

% Get event ground elevation data
[body_of_water, ground] = identifywater(nom_lat, nom_long);

% Calculate aspect ratio at event latitude, for graphing
lat_metersperdeg = 2*planet.ellipsoid_m.MeanRadius*pi/360;
long_metersperdeg = 2*planet.ellipsoid_m.MeanRadius*pi*cos(deg2rad(nom_lat))/360;

% Calculate nominal release vector
slope = -1/tan(degtorad(nom_angle));
startposition = [(startaltitude - geometric_elevation) / slope 0 startaltitude];
endposition = [-(geometric_elevation - ground) / slope 0 ground];
darkposition = [-(geometric_elevation - darkflight_elevation) / slope 0 darkflight_elevation];

% Calculation nominal start and end locations
AZ = nom_bearing + atan2d(-startposition(2),startposition(1)); % convert position to azimuth angle
ARCLEN = (360 * norm([startposition(1),startposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
startlocation = reckon(nom_lat, nom_long, ARCLEN, AZ); 
AZ = nom_bearing + atan2d(-endposition(2),endposition(1)); % convert position to azimuth angle
ARCLEN = (360 * norm([endposition(1),endposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
endlocation = reckon(nom_lat, nom_long, ARCLEN, AZ); 
ARCLEN = (360 * norm([darkposition(1),darkposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
darklocation = reckon(nom_lat, nom_long, ARCLEN, AZ); 

% Calculate nominal path for visualization
nom_slope = -1/tan(degtorad(nom_angle));
nom_startposition = [(nom_startaltitude - geometric_elevation) / nom_slope 0 nom_startaltitude];
nom_endposition = [-(geometric_elevation - ground) / slope 0 ground];
nom_darkposition = [-(geometric_elevation - darkflight_elevation) / slope 0 darkflight_elevation];
nom_AZ = nom_bearing + atan2d(-nom_startposition(2),nom_startposition(1)); % convert position to azimuth angle
nom_ARCLEN = (360 * norm([nom_startposition(1),nom_startposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
nom_startlocation = reckon(nom_lat, nom_long, nom_ARCLEN, nom_AZ); 
nom_AZ = nom_bearing + atan2d(-nom_endposition(2),nom_endposition(1)); % convert position to azimuth angle
nom_ARCLEN = (360 * norm([nom_endposition(1),nom_endposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
nom_endlocation = reckon(nom_lat, nom_long, nom_ARCLEN, nom_AZ); 
nom_ARCLEN = (360 * norm([nom_darkposition(1),nom_darkposition(2)]))/(2 * pi * planet.ellipsoid_m.MeanRadius); % distance in degrees of arc
nom_darklocation = reckon(nom_lat, nom_long, nom_ARCLEN, nom_AZ); 


% Update waitbar
waitbar(1,WaitbarHandle,'Event data loaded from file.');
pause(1)

% Check flag
check_eventdataloaded = true;