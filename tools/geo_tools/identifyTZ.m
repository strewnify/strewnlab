function [timezone_name, offset, suffix] = identifyTZ(lat,long, datetime_utc, db_Timezones)


% if timezone is empty, assume UTC
if isempty(datetime_utc.TimeZone)
    startdate.TimeZone = 'UTC';
end
   
% Error checking
if ~strcmp(startdate.TimeZone,'UTC')
    error('Timezone must be UTC')
end

for idx = 1:numel(lat)
    
    % Calculate distance from each time zone
    db_Timezones.temp_dist = distance(lat(idx), long(idx), db_Timezones.CityLAT, db_Timezones.CityLONG);
    db_Timezones = sortrows(db_Timezones,'temp_dist','ascend');
    
    % save the nearest time zone
    timezone_name(idx) = db_Timezones.Name(1);
    
    datetime_temp = datetime_utc(idx); % Copy UTC time
    datetime_temp.TimeZone = timezone_name{idx}; % Change time zone
    
    % determine if DST is active in that time zone
    if isdst(datetime_temp)
        offset(idx) = db_Timezones.UTCOffset(1) + db_Timezones.DSTOffset(1);
        suffix(idx) = db_Timezones.DST_Zone(1);
    else
        offset(idx) = db_Timezones.UTCOffset(1);
        suffix(idx) = db_Timezones.Zone(1);
    end
end

