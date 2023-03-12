% STREWNALYZE Prepares folders and reports nearby sensors for data analysis

% Initialize
strewnconfig

% Start logging
diary([logfolder 'strewnlab_log.txt'])        
diary on 
logformat('Strewnify Meteor Event Notification service started.')

% Load the event database
load_database

% Run the Event Picker
EventPicker_UI = EventPicker(sdb_Events);
waitfor(EventPicker_UI,'success')

% Get output data from UI before closing
SelectedEvent = extractBefore(EventPicker_UI.SelectedEvent,' - ');
success = EventPicker_UI.success;

% Close the Event Picker UI
EventPicker_UI.delete

if success
    logformat(sprintf('User selected "%s"',SelectedEvent),'USER')
else
    logformat(sprintf('User failed to select an event.'),'ERROR')
end

% Lookup nearby localities and suggest event names
CustomName = {'< Use a Custom Event Name >'};
[suggestions, radii] = suggest_eventnames(sdb_Events.LAT,sdb_Events.LONG,9);
if isempty(suggestions)
    suggestionsfound = true;
else
    suggestionsfound = false;
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
        UserEventName = inputdlg('Enter a preliminary name for this event:','Custom Event Name',1,{'< Custom Name >'});        
    else
        UserEventName = SuggestionList(selection_idx);
    end
    
    logformat(sprintf('User selected "%s" as Event Name',UserEventName{1}),'USER')
end
clear usersuccess
clear selection_idx

% Stop logging
diary off
