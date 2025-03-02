% STREWNALYZE Prepares folders and reports nearby sensors for data analysis

% Initialize
import_ref_data
strewnconfig

% Start logging
diary([getSession('folders','logfolder') '\strewnlab_log.txt'])        
diary on 
logformat('New meteor event analysis initialized.','INFO')

% Load the event database
load_database

% Choose event database

%analyze_answer = questdlg("Choose a Database","Database Choice","New","Old","Cancel","Cancel");
%logformat('User prompted to choose old or new database','USER')

analyze_answer = 'Old';
logformat('New database in development. Defaulted to old database.','DEBUG')

% Arbitrate database
switch analyze_answer
    case 'Old'
        Events_db = sdb_Events;
    case 'New'
        error('not supported')
    otherwise
        logformat('User cancelled data analysis.','ERROR')
end

% Open a waitbar
handleStrewnalyze = waitbar(0.1,'Loading Analysis Application...');

% Run the Event Picker
EventPicker_UI = EventPicker(Events_db);
waitfor(EventPicker_UI,'success')

waitbar(0.2,handleStrewnalyze,'Waiting for user selection...');

% Get output data from UI before closing
if ~isempty(EventPicker_UI.SelectedEvent)
    SelectedEvent = extractBefore(EventPicker_UI.SelectedEvent,' - ')
    success = EventPicker_UI.success;
    CONFIDENTIAL = EventPicker_UI.CONFIDENTIAL;
    WCT = EventPicker_UI.WCT;
    GE = EventPicker_UI.GE;
    VIDEO = EventPicker_UI.VIDEO;
    
    % temp - old database - lookup index
    select_i = find(strcmp(sdb_Events.EventID,SelectedEvent),1,'first');
else
    success = false;
end 

% Close the Event Picker UI
EventPicker_UI.delete

if success
    logformat(sprintf('User selected "%s"',SelectedEvent),'USER')
else
    logformat(sprintf('User failed to select an event.'),'ERROR')
end

% Lookup nearby localities and suggest event names
CustomName = {'< Use a Custom Event Name >'};
[suggestions, radii] = suggest_eventnames(sdb_Events.LAT(select_i),sdb_Events.LONG(select_i),9);
if isempty(suggestions)
    suggestionsfound = false;    
else
    suggestionsfound = true;
    SuggestionList = strcat('~', num2str(radii), {'km | '},suggestions);
    SuggestionList = [CustomName; SuggestionList];
end

usersuccess = false;
while ~usersuccess

    % if nearby place names were found, allow the user to pick from list
    if suggestionsfound
        [selection_idx,usersuccess] = listdlg('ListString',SuggestionList,'SelectionMode','single','Name','Preliminary Event Naming', 'OKString','OK','PromptString','Select an Event Name:','ListSize',[300,300]);
    else
        selection_idx = 1;
    end
    
    if selection_idx == 1
        SimulationName = inputdlg('Enter a preliminary name for this event:','Custom Event Name',1,{'< Custom Name >'}); 
        SimulationName = SimulationName{1};
        usersuccess = true;
    else
        SimulationName = suggestions{selection_idx-1};
    end
    
    logformat(sprintf('User selected "%s" as Event Name',SimulationName),'USER')
end
clear usersuccess
clear selection_idx

waitbar(0.4,handleStrewnalyze,'Creating folders & templates...');

% Create folders
if SelectedEvent(1) == 'S'
    SimEventID = ['Y' SelectedEvent(2:end)];
else
    SimEventID = SelectedEvent;
end

% Create folders
SimVersion = '0';
syncevent

% If Video was checked
if VIDEO

    % Create a video folder
    if exist([eventfolder '/Video'], 'dir') ~= 7
       mkdir([eventfolder '/Video'])
    end
    
    % Open 
    [~,temp_result] = system('tasklist /FI "imagename eq 4kvideodownloader.exe" /fo table /nh'); % check if program is running
    if GE && strcmp(temp_result(1:4),'INFO') % if program is not running
        system([getConfig('VideoDownloader_path') ' &']); % open Video Downloader
        system('TASKKILL -f -im "cmd.exe" > NUL'); % kill the random command window from previous system command
    end
end

% Print trajectory data and save to file
event_report = reportevents(sdb_Events(select_i,:))
writematrix(event_report,[exportfolder '\readme_' exportfoldername '.txt'],'QuoteStrings',false);

% If an ASGARD event, save ASGARD image
if contains(sdb_Events.Hyperlink1(select_i),'event.png')
    try
        ASGARD_path = websave([eventfolder '\' SimEventID 'NASA_ASGARD.png'],sdb_Events.Hyperlink1{select_i}); % save the file
        logformat(['ASGARD solution saved to ' ASGARD_path],'INFO')
    catch
        logformat('Error saving ASGARD image.','DEBUG')
    end
    
    try
        % Read the image
        ASGARD_img = imread(ASGARD_path);

        % Crop the map area of the ASGARD image
        % Define crop region as [x, y, width, height]
        xmin = floor(0.5209*size(img,1));
        xmax = size(ASGARD_img,1);
        ymin = 1;
        ymax = floor(0.2735*size(ASGARD_img,2));
        ASGARD_cropped_img = ASGARD_img(xmin:xmax, ymin:ymax, :);

        % Save the cropped image
        imwrite(ASGARD_cropped_img, [eventfolder '\' SimEventID 'NASA_ASGARD_map_cropped.png']);
        logformat('Cropped ASGARD image saved.','DEBUG')
    catch
        logformat('Error cropping ASGARD image.','DEBUG')
    end
end

% Create the KML template
load_KMLtemplate(eventfolder, SimEventID, SimulationName, GE);

% Get AMS event data
if strcmp(sdb_Events(select_i,:).DataSource{1},'AMS')

    waitbar(0.3,handleStrewnalyze,'Downloading data from AMS...');
    
    % DEBUG Correct the AMS event ID
    AMS_EventID = sdb_Events(select_i,:).AMS_event_id{1};
    AMS_EventID = [AMS_EventID(12:end) '-' AMS_EventID(7:10)];
    
    % Print the AMS reports
    if getConfig('ams_disable')
        logformat('AMS connectivity not available to retrieve reports.','WARN')
    else
        AMS_json = getams_reportsforevent(AMS_EventID,eventfolder);
    end
    
    % Download the latest KML file from AMS and save it to the event folder
    try
        KML_filepath = getamsKML(AMS_EventID,eventfolder);

        % if Google Earth was selected, open the file
        if GE
            winopen(KML_filepath);        
        end
    catch
        logformat('Cannot retrieve/open AMS KML file.','WARN')
    end
end

waitbar(0.5,handleStrewnalyze,'Analyzing nearby sensors...');

% Analyze nearby sensors
analyze_nearby

% Plot Doppler Stations
DopplerStations = SensorSummary(SensorSummary.Type=="Doppler",:);
plotsensors(DopplerStations)
title([SimulationName ' : ' strrep(SimEventID,'_','-')])
geoscatter(sdb_Events.LAT(select_i),sdb_Events.LONG(select_i),'filled','b')

% Export Doppler Station Data
% (future release will include other stations as well)
DopplerStationIDs = DopplerStations.StationID;
station_data = getstation_metadata(DopplerStationIDs,entrytime);

% Export plot to image file
saveas(gcf,[eventfolder '/' SimEventID '_DopplerStationMap.png']);

waitbar(0.75,handleStrewnalyze,'Opening Applications...');

% Create shortcut file and open browser to event pages
if ~isempty(sdb_Events.Hyperlink1{select_i})
    createURLshortcut(sdb_Events.Hyperlink1{select_i}, eventfolder, 'Hyperlink1.url');
    openlink(sdb_Events.Hyperlink1{select_i});
end
if ~isempty(sdb_Events.Hyperlink2{select_i})
    createURLshortcut(sdb_Events.Hyperlink2{select_i}, eventfolder, 'Hyperlink2.url');
    openlink(sdb_Events.Hyperlink2{select_i});    
end

%Open Google Earth, if not open
[~,temp_result] = system('tasklist /FI "imagename eq googleearth.exe" /fo table /nh'); % check if program is running
if GE && strcmp(temp_result(1:4),'INFO') % if program is not running
    system([getConfig('GoogleEarth_path') ' &']); % open Google Earth
    system('TASKKILL -f -im "cmd.exe" > NUL'); % kill the random command window from previous system command
end

%Open WCT, if not open
[~,temp_result] = system('tasklist /FI "imagename eq wct.exe" /fo table /nh'); % check if program is running
if WCT && strcmp(temp_result(1:4),'INFO') % if program is not running
    system([getConfig('WCT_path') ' &']); % open Google Earth    
end

waitbar(0.95,handleStrewnalyze,'Cleaning up...')

system('TASKKILL -f -im "cmd.exe" > NUL'); % kill random command windows from previous system commands

% clear temp variables
clear temp_*

% Stop logging
diary off

% Close waitbar
waitbar(1,handleStrewnalyze,'Analysis Preparation Complete.')
pause(0.8)
close(handleStrewnalyze)
