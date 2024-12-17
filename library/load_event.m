function load_event
% LOAD_EVENT Load event data
% This function loads event data from the database into working memory
% Future support would allow the ref_event object to hold multiple events

%*********** DRAFT *****************
% currently this function does nothing, except create a global variable
% Need to import an event from the database

% Initialize global variable
% Any existing data will be overwritten
global ref_config
if isempty(ref_config)
    ref_config = struct;
end

% Log initialization
if isfield(ref_event,'loaded') && ref_event.loaded
    logformat('Reloading event data...','INFO')
else
    logformat('Loading event data...','INFO')
end
ref_event.loaded = false;

% While loading, loading is incomplete
ref_event.loaded = false;

% ***** Load the event here ******

% Configuration loading complete
ref_event.loaded = true;
logformat('Event data loaded successfully.','INFO')