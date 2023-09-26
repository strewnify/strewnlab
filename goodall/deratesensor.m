function [db_Sensors_out] = deratesensor(db_Sensors_in, StationID, reason, newrating)
%DERATESENSORS Set sensor rating to zero for a given reason.  Example - cell phone video

% Ensure string output
StationID = convertCharsToStrings( StationID );
reason = convertCharsToStrings( reason );

if ~isnumeric(newrating)
    error('Invalid rating')
end

% Find Station ID
idx = find(contains(db_Sensors_in.StationID,StationID));

% Check for errors
if numel(idx) > 1
    error(sprintf('Multiple matches for StationID: %s',StationID))
elseif numel(idx) == 0
    error('Station ID not found.')
end

% Copy the database
db_Sensors_out = db_Sensors_in;

% Make changes
if numel(idx) == 1
    db_Sensors_out.Notes(idx) = reason;
    db_Sensors_out.BaseScore(idx) = newrating;
end

