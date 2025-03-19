function [HRA] = hourangle(LON,DateTime)
%[HRA] = HOURANGLE(LONGITUDE,OFFSET,DAY) Calculates hour angle
% Inputs are the longitude and time zone offset of the location and the day
% of the year.

% if no time zone given, assume UTC
if isempty(DateTime.TimeZone)
    logformat('Timezone not provided, UTC assumed','WARN')
    DateTime.TimeZone = 'UTC';
end

% Extract time and offsets
[dt,dst] = tzoffset(DateTime);
Offset = hours(dt);
%Offset = hours(dt - dst); % broken, seems correct without this
LT = rem(datenum(DateTime),1) .* 24;
daynum = datenum(DateTime) - datenum(year(DateTime),1,1);

% Correct Time and calculate hour angle
LSTM = 15 .* Offset;
EoT = EqOfTime(daynum);
TC = 4 .* (LON - LSTM) + EoT;
LST = LT + TC ./ 60;
HRA = 15 .* (LST - 12);

end

