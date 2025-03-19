function [when_description,when_sentence,solar_elev] = solartime(LAT, LON, DateTimeUTC)
%TIMEOFDAY Calculate solar elevation and time of day

% Error handling
if length(LAT) ~= length(LON)
    logformat('Input Lat/Lon array sizes not equal','ERROR')
end
if length(LAT) > 1 && length(LAT) ~= length(DateTimeUTC)
    logformat('Input Lat/Lon array size not equal to size of DateTime array','ERROR')
end

% if a single location is given with a DateTime array, use the same location for all
if length(LAT) == 1 && length(DateTimeUTC) > 1
    LAT = repmat(LAT,size(DateTimeUTC));
    LON = repmat(LON,size(DateTimeUTC));
end

% if timezone is not UTC, error
if ~isempty(DateTimeUTC.TimeZone) && ~strcmp(DateTimeUTC.TimeZone, 'UTC')
    logformat('Timezone must be UTC','ERROR')
end

if isnan(LON)
    solar_elev = NaN;
    local_hour = NaN;
else
    % Calculate solar elevation
    solar_elev = solarelevation(LAT, LON, DateTimeUTC);

    % Get local hour
    local_hour = hour(DateTimeUTC - hours(timezonefix(LON)));
end
sincemidnight = timeofday(DateTimeUTC);

% Calculate time of day, based on sun position and local hour
when_description = cell(size(solar_elev)); % pre-allocate array
when_description(isnan(solar_elev) | solar_elev > 90 | solar_elev < -90) = {''};
when_description(solar_elev >= 6) = {'daytime'};
when_description(solar_elev < 6 & solar_elev > -0.5 & local_hour < 12) = {'sunrise'};
when_description(solar_elev < 6 & solar_elev > -0.5 & local_hour >= 12) = {'sunset'};
when_description(solar_elev <= -0.5 & solar_elev > -6 & local_hour < 12) = {'civil dawn'};
when_description(solar_elev <= -0.5 & solar_elev > -6 & local_hour >= 12) = {'civil dusk'};
when_description(solar_elev <= -6 & solar_elev > -12 & local_hour < 12 ) = {'nautical dawn'};
when_description(solar_elev <= -6 & solar_elev > -12 & local_hour >= 12 ) = {'nautical dusk'};
when_description(solar_elev <= -12 & solar_elev > -18 & local_hour < 12 ) = {'astronomical dawn'};
when_description(solar_elev <= -12 & solar_elev > -18 & local_hour >= 12 ) = {'astronomical dusk'};
when_description(solar_elev <= -18) = {'night'};

% Adjust wording for arctic/antarctic
when_description(LAT > 60 | LAT < -60) = strrep(when_description(LAT > 60 | LAT < -60),'dawn','twilight');
when_description(LAT > 60 | LAT < -60) = strrep(when_description(LAT > 60 | LAT < -60),'dusk','twilight');

% Create a when description, that can be used at the beginning of a
% sentence or at the end of a sentence, after
% "the fireball occurred..."
% just after midnight on Thursday morning
% early Thursday morning before sunrise
% before sunrise on Thursday morning
% at sunrise on Thursday morning
% Thursday morning
% midday Thursday
% Thursday afternoon
% in late afternoon on Thursday
% at sunset on Thursday
% after sunset on Thursday evening
% Thursday night
% late Thursday night
% just before midnight on Thursday night

[~,dayname] = weekday(DateTimeUTC,'en_US','long'); % day of the week
dayname = cellstr(dayname);
time_descr = cell(size(solar_elev)); % pre-allocate array
sun_descr = cell(size(solar_elev)); % pre-allocate array

% For each element in the array
for idx = 1:numel(solar_elev)
    
    % Calculate time of day
    if isnan(local_hour(idx)) || isnan(sincemidnight(idx))
        time_descr(idx) = {''};
    elseif sincemidnight(idx) < minutes(1)
        time_descr(idx) = {['just after midnight on ' dayname{idx} ' morning']};
    elseif sincemidnight(idx) < minutes(30)
        time_descr(idx) = {['just after midnight on ' dayname{idx} ' morning']};
    elseif sincemidnight(idx) > minutes(1410)
        time_descr(idx) = {['just before midnight on ' dayname{idx} ' night']};
    elseif sincemidnight(idx) > minutes(690) && sincemidnight(idx) < minutes(720)
        time_descr(idx) = {['just before noon on ' dayname{idx}]};
    elseif sincemidnight(idx) >= minutes(720) && sincemidnight(idx) < minutes(750)
        time_descr(idx) = {['just after noon on ' dayname{idx}]};
    else
        switch local_hour(idx)
            case 0
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 1
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 2
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 3
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 4
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 5
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 6
                time_descr(idx) = {['early ' dayname{idx} ' morning']};
            case 7
                time_descr(idx) = {[dayname{idx} ' morning']};
            case 8
                time_descr(idx) = {[dayname{idx} ' morning']};
            case 9
                time_descr(idx) = {[dayname{idx} ' morning']};
            case 10
                time_descr(idx) = {[dayname{idx} ' morning']};
            case 11
                time_descr(idx) = {['around midday on ' dayname{idx}]};
            case 12
                time_descr(idx) = {['around midday on ' dayname{idx}]};
            case 13
                time_descr(idx) = {['around midday on ' dayname{idx}]};
            case 14
                time_descr(idx) = {[dayname{idx} ' afternoon']};
            case 15
                time_descr(idx) = {[dayname{idx} ' afternoon']};
            case 16
                time_descr(idx) = {[dayname{idx} ' afternoon']};
            case 17
                time_descr(idx) = {[dayname{idx} ' afternoon']};
            case 18
                time_descr(idx) = {[dayname{idx} ' evening']};
            case 19
                time_descr(idx) = {[dayname{idx} ' evening']};
            case 20
                time_descr(idx) = {[dayname{idx} ' evening']};
            case 21
                time_descr(idx) = {[dayname{idx} ' night']};
            case 22
                time_descr(idx) = {[dayname{idx} ' night']};
            case 23
                time_descr(idx) = {['late ' dayname{idx} ' night']};
            case 24
                time_descr(idx) = {['late ' dayname{idx} ' night']};
            otherwise
                logformat('Unknown time of day','DEBUG')
                time_descr(idx) = {''};
                
        end
    end
    
    % Calculate sun suffix
    if isnan(solar_elev(idx)) || solar_elev(idx) > 90 || solar_elev(idx) < -90
        logformat('Invalid solar elevation calculated','DEBUG')
        sun_descr(idx) = {''};
    elseif local_hour(idx) < 12 % before noon
        if solar_elev(idx) >= -12 && solar_elev(idx) < -1
            sun_descr(idx) = {' before sunrise'};
        elseif solar_elev(idx) >= -1 && solar_elev(idx) < 1
            sun_descr(idx) = {' at sunrise'};
        elseif solar_elev(idx) >= 1 && solar_elev(idx) < 12
            sun_descr(idx) = {' after sunrise'};
        elseif solar_elev(idx) > -12 && solar_elev(idx) < 0
            sun_descr(idx) = {' before sunrise'};
        else
            sun_descr(idx) = {''};
        end
        
    elseif local_hour(idx) >= 12 % after noon
        if solar_elev(idx) <= 12 && solar_elev(idx) > 1
            sun_descr(idx) = {' before sunset'};
        elseif solar_elev(idx) <= 1 && solar_elev(idx) > -1
            sun_descr(idx) = {' at sunset'};
        elseif solar_elev(idx) <= -1 && solar_elev(idx) > -12
            sun_descr(idx) = {' after sunset'};
        else
            sun_descr(idx) = {''};
        end
    else
        logformat('Unknown solar elevation','DEBUG')
        sun_descr(idx) = {''};
    end
    
end

% Concatenate the time description and the sun suffix
when_sentence = strcat(time_descr,sun_descr);

