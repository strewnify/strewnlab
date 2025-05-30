function [sdb_Events] = manualload(DataSource, sdb_Events, startLAT,startLONG, endLAT, endLONG, Datetime, AMS_event_id)
% Manually import a meteor event into the legacy database
% AMS event id format: 'Event_2024_5537'

idx = size(sdb_Events,1) + 1;

% import user data
sdb_Events.start_lat(idx) = startLAT;
sdb_Events.start_long(idx) = startLONG;
sdb_Events.end_lat(idx) = endLAT;
sdb_Events.end_long(idx) = endLONG;
sdb_Events.Datetime(idx) = Datetime;
sdb_Events.DataSource{idx} = DataSource;

% Calculate event id
sdb_Events.EventID{idx} = eventidcalc(sdb_Events.start_lat(idx), sdb_Events.start_long(idx), sdb_Events.Datetime(idx));

% default values for start and end altitude
sdb_Events.start_alt(idx) = getConfig('nom_startaltitude');
sdb_Events.end_alt(idx) = getConfig('nom_endaltitude');
sdb_Events.Altitude(idx) = round(sdb_Events.end_alt(idx)./1000,3);

% Calculate bearing and distance
[temp_distance_meters, temp_bearing] = distance(sdb_Events.start_lat(idx),sdb_Events.start_long(idx),sdb_Events.end_lat(idx),sdb_Events.end_long(idx),getPlanet('ellipsoid_m'));
sdb_Events.CurveDist(idx) = temp_distance_meters ./ 1000; % convert meters to kilometers
sdb_Events.Bearing(idx) = round(temp_bearing,3);
sdb_Events.Incidence(idx) = round(atand(1000.*sdb_Events.CurveDist(idx)./(sdb_Events.start_alt(idx)-sdb_Events.end_alt(idx))),3);

[sdb_Events.LAT(idx),sdb_Events.LONG(idx)] = nomlatlong(sdb_Events.Bearing(idx), sdb_Events.Incidence(idx), sdb_Events.end_lat(idx), sdb_Events.end_long(idx), sdb_Events.Altitude(idx));

% Get location
sdb_Events.Location{idx} = getlocation(endLAT, endLONG);

% Generate Hyperlinks
sdb_Events.HyperMap{idx} = ['https://maps.google.com/?q=' num2str(sdb_Events.end_lat(idx),'%f') '%20' num2str(sdb_Events.end_long(idx),'%f')];

if strcmp(sdb_Events.DataSource{idx},'AMS')
    sdb_Events.AMS_event_id{idx} = AMS_event_id;
    sdb_Events.Hyperlink1(idx) = strcat('https://fireball.amsmeteors.org/members/imo_view/',{regexprep(sdb_Events.AMS_event_id{idx},'(?:_)','/')});
end

% Unknown data
sdb_Events.Speed(idx) = NaN;
sdb_Events.NumReports(idx) = NaN;
sdb_Events.ImpactEnergy(idx) = NaN;
sdb_Events.RadiatedEnergy(idx) = NaN;
sdb_Events.vx(idx) = NaN;
sdb_Events.vy(idx) = NaN;
sdb_Events.vz(idx) = NaN;
sdb_Events.Mass(idx) = NaN;
sdb_Events.average_magnitude(idx) = NaN;
sdb_Events.impact_lat(idx) = NaN;
sdb_Events.impact_long(idx) = NaN;
sdb_Events.epicenter_lat(idx) = NaN;
sdb_Events.epicenter_long(idx) = NaN;
sdb_Events.threshold(idx) = NaN;
sdb_Events.min_hour_diff(idx) = NaN;
sdb_Events.comp_precision(idx) = NaN;
sdb_Events.min_rating(idx) = NaN;
sdb_Events.end_threshold(idx) = NaN;
sdb_Events.optimized_ratings(idx) = NaN;
sdb_Events.num_reports_for_options(idx) = NaN;

% Log Dates
nowtime_utc = datetime('now'); 
sdb_Events.AddDate(idx) = nowtime_utc;
sdb_Events.UpdateDate(idx) = nowtime_utc;
sdb_Events.ProcessDate(idx) = nowtime_utc;

% Misc
sdb_Events.SolarElev(idx) = solarelevation(sdb_Events.LAT(idx),sdb_Events.LONG(idx),sdb_Events.Datetime(idx)); % Calculate solar elevation
sdb_Events.ImpactEnergy_Est(idx) = 0.00005;

end
