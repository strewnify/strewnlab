function [last_sample_utc, available_time_utc] = estAvailableIGRA(event_time, StationID)
%ESTIGRA_AVAILABLE Estimate the radiosonde sampling time after an event and
% the time that the data will likely be available in the IGRA database.
%   Source: 2024-02-15 Email from Bruce Hundermark / Riverside Technology, Inc.
%   Federal Government Contractor - Meteorologist/Scientific Programmer
%   NOAA's National Centers for Environmental Information (NCEI)
%   
%   The IGRA application is run daily at 5pm Eastern Time and when it gets 
%   finished, the output product gets pushed to the public access location.
%   Updated IGRA products are usually available around 10pm EST.
%   
%   The IGRA Update data product is developed from various sources of input
%   radiosonde soundings to develop an integrated and quality controlled
%   output product.  IGRA usually receives some of this input data on the 
%   current day by the late afternoon (this is data we receive directly 
%   from the National Weather Service (NWS) after they launch their 
%   balloons for the US and Caribbean stations). So, the US and Caribbean
%   stations for the current day would get processed by the IGRA 
%   application and be available at around 10pm EST of the same day.  
%   
%   For US and Caribbean stations, the IGRA data for the current day would be
%   available on the same day around 10pm EST. For other regions, the IGRA
%   data for the current day would be available the next day around 10pm EST.
%   However, the input soundings for the other stations around the globe 
%   are only available the next morning through the Global 
%   Telecommunications System (GTS) and so the non-US and non-Caribbean 
%   stations for the current day do not get processed by the IGRA system 
%   until the next day and would not be available until around 10pm EST 
%   on the following day.  At this time, we cannot provide the IGRA data 
%   any sooner as we are limited by the 1 day latency of the data from the GTS.

% set upload time to 10:00pm Eastern Time
% This is considered the latest that data will be uploaded
upload_hour = 22;
upload_tz = 'America/New_York';

% Change input time zone to UTC
event_time_utc = event_time;
event_time_utc.TimeZone = 'UTC';

% Determine regional intervals and delays
% DEBUG - other regions detail missing
if strcmp(StationID(1:2),'US')
    sample_hours = [0 12];
    data_delay = days(0);
else
    sample_hours = [0 12];
    data_delay = days(1);
end

% Determine the last sample needed for the event
effective_time = event_time_utc + hours(1); % allow time for balloon flight
effective_hour = hour(effective_time);

% Round up to the next hour
last_sample_utc = datetime(year(effective_time),month(effective_time),day(effective_time),hour(effective_time) + 1,0,0,'TimeZone','UTC');

% Find the next sample
while  nnz(hour(last_sample_utc) == sample_hours) == 0
    last_sample_utc = last_sample_utc + hours(1);
end

% Apply data delay
available_time_utc = last_sample_utc + data_delay;

% Find the next upload
available_time_utc.TimeZone = upload_tz;
while  hour(available_time_utc) ~= upload_hour
    available_time_utc = available_time_utc + hours(1);
end

available_time_utc.TimeZone = 'UTC';

% Calculate local times for logging purposes
utc_format = 'yyyy-MM-dd HH:mm z';
local_format = 'eeee, MMMM d, yyyy, hh:mm a z';
event_time_local = event_time_utc;
event_time_local.TimeZone = getSession('env','TimeZone');
event_time_local.Format = local_format;
event_time_utc.Format = utc_format;
last_sample_local = last_sample_utc;
last_sample_local.TimeZone = getSession('env','TimeZone');
last_sample_local.Format = local_format;
last_sample_utc.Format = utc_format;
available_time_local = available_time_utc;
available_time_local.TimeZone = getSession('env','TimeZone');
available_time_local.Format = local_format;
available_time_utc.Format = utc_format;

logformat(sprintf('Event Date/Time: %s (%s) ',event_time_utc,event_time_local),'INFO')
logformat(sprintf('IGRA Station %s: Radiosonde sample after event estimated at %s (%s)',StationID,last_sample_utc,last_sample_local),'INFO')

% If the event is in the past and data is not yet available, provide countdown
nowtime_utc = datetime('now','TimeZone','UTC');

if event_time_utc < nowtime_utc
    until_available_hours = hours(available_time_utc - nowtime_utc);

    % Error checking
    if until_available_hours > 200
        logformat(sprintf('IGRA Station %s: Unknown error in weather data availability estimation, %.',StationID),'DEBUG')

    % Provide countdown info
    elseif until_available_hours >= 0
        logformat(sprintf('IGRA Station %s: Weather data available in %0.1f hours, at %s (%s)', StationID,until_available_hours,available_time_utc,available_time_local),'INFO')        
    end
else
    logformat(sprintf('IGRA Station %s: Weather data available by %s (%s)',StationID,available_time_utc,available_time_local),'INFO')
end
