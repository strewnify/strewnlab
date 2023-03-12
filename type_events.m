function [datatype] = type_events(import_data)
%TYPE_EVENTS categorizes types of events in a table

% Default data type is trajectory
datatype = repmat({'Trajectory'},size(import_data,1),1);

% currently this function just looks for event names containing "Doppler"
if ismember('EventName',fieldnames(import_data))
    datatype(contains(import_data.EventName,'Doppler')) = {'Doppler'};
end

