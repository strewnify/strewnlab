function [ EventID ] = eventidcalc( LAT, LONG, Datetime )
% EVENTID = EVENTIDCALC(LAT, LONG, DATETIME)

% Calculate date/time string
if isnat(Datetime)
    Datetime_string = 'YYYYMMDD_HHZ_';
elseif ((second(Datetime) == 0) && (minute(Datetime) == 0) && (hour(Datetime) == 0) && (day(Datetime) == 1) && (month(Datetime) == 1))
    Datetime_string = datestr(Datetime,'yyyyXXXX_XXZ_');
else
    Datetime_string = datestr(Datetime,'yyyymmdd_HHZ_');
end

% Calculate UTM zone
if isnan(LAT) || isnan(LONG)
    UTM_string = 'XXX';
elseif LAT < -80 
    if LONG < 30.5
        UTM_string = 'AAA';
    elseif LONG >= 30.5
        UTM_string = 'BBB';
    end
elseif LAT > 84
    if LONG < 30.5
        UTM_string = 'YYY';
    elseif LONG >= 30.5
        UTM_string = 'ZZZ';
    end
else    
    UTM_string = utmzone(LAT,LONG);
end

% Return EventID
EventID = ['S' Datetime_string UTM_string];
