function [data_out] = getEvent(eventid,varname)
%GETEVENT Get Meteor Event data from global struct variable

% Import reference data
global ref_event

% Check for missing initialization
if isempty(ref_event) || ~isfield(ref_event,'loaded') || ~ref_event.loaded
    logformat('Event data not loaded, run load_event.','ERROR')    
else

    % Store output
    if nargin == 0
        data_out = ref_event;
    else
        data_out = ref_event.(eventid).(varname);
    end
end