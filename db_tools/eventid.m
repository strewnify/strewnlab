function [ EventID ] = eventid( LAT, LONG, Datetime, Category, EventName, Evidence )
% EVENTID = EVENTIDCALC(LAT, LONG, DATETIME, CATEGORY, EVENTNAME, EVIDENCE)

% Logging option
logthis = false; % turn on/off logging for this file
if ~logthis && strcmp(get(0,'Diary'),'on')
       diary off     
       resetdiary = true;
else
    resetdiary = false;
end

% Parse inputs
if nargin > 6
    error('Incorrect number of input arguments.')
end
if nargin == 3
    Category = 'witnessed';
end


% Calculate UTM zone
if isnan(LAT) || isnan(LONG) || LONG < -180 || LONG > 180 || LAT < -90 || LAT > 90
    logformat('Coordinates invalid.  Grid zone defaulted to XXX.','WARN')
    UTM_string = 'XXX';
elseif ((LAT == 0) && (LONG == 0))
    logformat('Zero coordinates likely invalid.  Grid zone defaulted to XXX.','WARN')
    UTM_string = 'XXX';
elseif LAT < -80 
    if LONG < 30.5
        UTM_string = '00A';
    elseif LONG >= 30.5
        UTM_string = '00B';
    end
elseif LAT > 84
    if LONG < 30.5
        UTM_string = '00Y';
    elseif LONG >= 30.5
        UTM_string = '00Z';
    end
else    
    UTM_string = utmzone(LAT,LONG);
    if length(UTM_string) == 2
        UTM_string = ['0' UTM_string];
    end
end

switch Category
    case 'witnessed'
        
        % Calculate date/time string
        if isnat(Datetime)
            logformat('Date and time invalid, assigning generic date code.','WARN')
            Datetime_string = 'YYYYMMDD_HHZ_';
        elseif ((second(Datetime) == 0) && (minute(Datetime) == 0) && (hour(Datetime) == 0) && (day(Datetime) == 1) && (month(Datetime) == 1))
            logformat('Default date and time detected.  Assigning year-only date code.','WARN')
            Datetime_string = datestr(Datetime,'yyyyXXXX_XXZ_');
        elseif ((second(Datetime) == 0) && (minute(Datetime) == 0) && (hour(Datetime) == 0))
            logformat('Default time detected.  Assigning XXZ hour code.','WARN')
            Datetime_string = datestr(Datetime,'yyyymmdd_XXZ_');
        else
            Datetime_string = datestr(Datetime,'yyyymmdd_HHZ_');
        end

        % Return Witnessed EventID
        EventID = ['Y' Datetime_string UTM_string];
        
    case 'unwitnessed'
        
        % Error checking
        if nargin < 6
            error('Unwitnessed events require event name and evidence inputs.')
        end
        if length(Evidence) ~= 1
            error('Evidence identifier should be a single character.')
        elseif Evidence ~= 'C' && Evidence ~= 'M' && Evidence ~= 'T'
            error('Evidence identifier must be C, M, or T.')
        end
        
        % Calculate date/time string
        if isnat(Datetime)
            warning('Date and time invalid, assigning generic date code.')
            year_string = 'XXXX';
        else
            year_string = datestr(Datetime,'yyyy');
        end

        % Parse event name
        EventName = removediacritics(EventName);
        EventName = EventName(isstrprop(EventName,'alpha'));
        EventName = upper(EventName);
        if length(EventName) < 4
            EventName = [EventName repmat('X',1,4-length(EventName))];
        else
            EventName = EventName(1:4);
        end
        
        % Return Witnessed EventID
        % assuming no duplicate - TBD
        EventID = ['N' year_string EventName '_' Evidence '01_' UTM_string];
    otherwise
        error('Invalid event category.')

end

if resetdiary
    diary on
end

