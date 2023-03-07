% STREWNALYZE Prepares folders and reports nearby sensors for data analysis

% Start logging
diary([logfolder 'strewnlab_log.txt'])        
diary on 
logformat('Strewnify Meteor Event Notification service started.')

% Initialize
strewnconfig

% Load the event database
load_database

% Run the Event Picker
EventPicker_UI = EventPicker(sdb_Events);
waitfor(EventPicker_UI,'success')

% Get output data from UI before closing
SelectedEvent = EventPicker_UI.SelectedEvent;
success = EventPicker_UI.success;

% Close the Event Picker UI
EventPicker_UI.delete

if success
    logformat(sprintf('User selected "%s"',SelectedEvent),'USER')
else
    logformat(sprintf('User failed to select an event.'),'ERROR')
end

% Stop logging
diary off
