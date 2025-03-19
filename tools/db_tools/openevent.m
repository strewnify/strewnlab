%OPENEVENT

if exist('sdb_Events','var')
    EventList = strcat(sdb_Events.EventID, {' - '}, sdb_Events.Location, {' ('}, sdb_Events.AMS_event_id, {')'});
    [select_i,usersuccess] = listdlg('ListString',EventList,'SelectionMode','single','Name','Select a Meteor Event', 'OKString','Open','PromptString','Select a Meteor Event:','ListSize',[500,300]);
end

% Open browser to event pages
if ~isempty(sdb_Events.Hyperlink2{select_i})
    openlink(sdb_Events.Hyperlink2{select_i});    
end
if ~isempty(sdb_Events.Hyperlink1{select_i})
    openlink(sdb_Events.Hyperlink1{select_i});
end