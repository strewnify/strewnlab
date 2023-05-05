% PRINTTRAJECTORY Provide summary of trajectory data
% This function generates a summary of the trajectory input data for the
% current simulation, and displays it to the command window.

% filter the simulation monitor table
valid = SimMonitor.entrymass~=0;

% Summarize event
SimTrajectoryData = sprintf('%s Meteor Event (%s)', SimulationName, SimEventID);
if strcmp(datestr(entrytime,'FFF'),'000')
    SimTrajectoryData = [SimTrajectoryData newline 'Date/Time: ' datestr(entrytime,'yyyy-mm-dd HH:MM:SS') ' UTC'];
else
    SimTrajectoryData = [SimTrajectoryData newline 'Date/Time: ' datestr(entrytime,'yyyy-mm-dd HH:MM:SS.FFF') ' UTC'];
end
SimTrajectoryData = [SimTrajectoryData newline NearestTown ', ' State ', ' Country];

% Derive data quality
switch trajectory_quality
    case 0
        Data_Quality = 'unknown';
        DataQuality_mult = 0.1;
    case 1
        Data_Quality = 'poor';
        DataQuality_mult = 0.3;
    case 2
        Data_Quality = 'fair';
        DataQuality_mult = 0.5;
    case 3
        Data_Quality = 'good';
        DataQuality_mult = 0.8;
    case 4
        Data_Quality = 'verified';
        DataQuality_mult = 1;
    otherwise
        Data_Quality = 'unknown';
end
SimTrajectoryData = [SimTrajectoryData newline 'Data Quality: ' Data_Quality];
SimTrajectoryData = [SimTrajectoryData newline 'Simulation Version: ' SimVersion];
if exist('EventData_Finds','var') && sum(EventData_Finds.mass_kg) > 0
    SimTrajectoryData = [SimTrajectoryData newline sprintf('TKW:   %.3f kg', sum(EventData_Finds.mass_kg))];
end

% Strewn mass estimate

switch lower(material_sim)
    case 'random'
        HTC = 0.1; 
        ablationheat = 8245000;         
    case 'stony'
        HTC = 0.1; 
        ablationheat = 8245000;         
    case 'iron'
        HTC = 0.1; 
        ablationheat = 8010000; 
    case 'stony-iron'
        HTC = 0.1; 
        ablationheat = 8170000;         
    case 'carbonaceous'
        HTC = 0.1; 
        ablationheat = 8510000;
    case 'h chondrite'
        HTC = 0.1; 
        ablationheat = 8510000;
    case 'l chondrite'
        nom_density = 3400;
        error_density = 300;
        HTC = 0.1; 
    otherwise
        error('Invalid meteoroid material')
end

% Estimate strewn field statistics
predicted_TKW_max_kg = eststrewnmass(nom_mass, nom_speed, ablationheat, HTC);
nominal_strewnmass_g = predicted_TKW_max_kg*1000; % 1/10 of the max, in grams
mass_filt = filter & strewndata.mass > 0.010 & strewndata.mass < 1;  % 10 grams to 1 kg
[vertices_lat, vertices_lon, strewn_area_km2] = polyarea(strewndata.Latitude(mass_filt),strewndata.Longitude(mass_filt));
grams_per_km2 =  nominal_strewnmass_g / strewn_area_km2;

% Summarize input data
SimTrajectoryData = [SimTrajectoryData newline newline newline '*** Trajectory Data ***'];
SimTrajectoryData = [SimTrajectoryData newline 'Input Parameters    Data     ± Error  Units'];
SimTrajectoryData = [SimTrajectoryData newline '------------------------------------------------------'];
SimTrajectoryData = [SimTrajectoryData newline sprintf('End Latitude:      %- 9.4f ± %-7.4f °', nom_lat, error_lat)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('End Longitude:     %- 9.4f ± %-7.4f °', nom_long, error_long)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('End Altitude:      %- 9.4f ± %-7.4f km', ref_elevation/1000, error_elevation/1000)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Entry Speed:       %- 9.2f ± %-7.2f km/s', nom_speed/1000, error_speed/1000)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Entry Mass:        %- 9.0f ± %-7.0f kg', mean([lowmass highmass]), (highmass-lowmass)/2)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Impact Energy:     %- 9.4f ± %-7.4f kt TNT', mean([lowenergy_kt highenergy_kt]), (highenergy_kt-lowenergy_kt)/2)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Bearing (Heading): %- 9.2f ± %-7.2f ° %s', nom_bearing, error_bearing, compassdir(nom_bearing))];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Incidence Angle:   %- 9.2f ± %-7.2f ° from vertical', nom_angle, error_angle)];

% Summarize simulation data
SimTrajectoryData = [SimTrajectoryData newline newline newline '*** Simulation Details ***'];
SimTrajectoryData = [SimTrajectoryData newline '------------------------------------------------------'];
if strcmp(material_sim,'random')
    SimTrajectoryData = [SimTrajectoryData newline 'Simulation Type:     Monte Carlo, unknown meteoroid'];
else
    SimTrajectoryData = [SimTrajectoryData newline sprintf('Simulation Type:     Monte Carlo, %s meteoroid', material_sim)];
end
SimTrajectoryData = [SimTrajectoryData newline 'Simulation Engineer: Jim Goodall'];
SimTrajectoryData = [SimTrajectoryData newline 'Simulation Start:    ' datestr(SimMonitor.sim_time(1),'yyyy-mm-dd HH:MM:SS') ' UTC'];
SimTrajectoryData = [SimTrajectoryData newline 'Simulation End:      ' datestr(SimMonitor.sim_time(end),'yyyy-mm-dd HH:MM:SS') ' UTC'];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Scenarios Simulated: %i', SimMonitor.sim_scenario(end))];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Average fragments:   %.0f', mean(SimMonitor.strewn_count(valid)))];
%SimTrajectoryData = [SimTrajectoryData newline sprintf('Average strewn mass: %.1f kg', mean(SimMonitor.strewn_mass(valid)))];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Est. Strewn Mass:     < %.1f kg', predicted_TKW_max_kg)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Est. Main Mass:       < %.1f kg', strewndata_maxmass)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Nominal Search Area:  < %.1f km^2', strewn_area_km2)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Mass per km^2:        < %.1f grams/km^2', grams_per_km2)];


% Summarize weather stations
SimTrajectoryData = [SimTrajectoryData newline newline newline '*** Weather Stations Accessed (IGRA Database) ***'];
[~, IGRA_StationIdx, ~] = unique(EventData_ProcessedIGRA.Distance); % Get station indices
SimTrajectoryData = [SimTrajectoryData newline 'Dist(km)    Station ID   Latitude   Longitude'];
SimTrajectoryData = [SimTrajectoryData newline '--------------------------------------------------'];
for idx = IGRA_StationIdx'
    SimTrajectoryData = [SimTrajectoryData newline sprintf('%8.0f %13s % 10.4f° % 10.4f°', EventData_ProcessedIGRA.Distance(idx), EventData_ProcessedIGRA.StationID{idx}, EventData_ProcessedIGRA.NOM_LAT(idx), EventData_ProcessedIGRA.NOM_LONG(idx))];
end

% Summarize weather station
fm_alt = '%8.1f';
fm_wind = '%10.1f';
fm_dir = '%9s';
SimTrajectoryData = [SimTrajectoryData newline newline newline '*** StrewnLAB Weather Model ***'];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Ground Elevation:    %.0f m', ground)];
SimTrajectoryData = [SimTrajectoryData newline sprintf('Variation Included:  %.1fσ to %.1fσ', weather_minsigma, weather_maxsigma)];
SimTrajectoryData = [SimTrajectoryData newline newline 'Altitude  Nom Wind   Nom Dir '];
% SimTrajectoryData = [SimTrajectoryData newline         '      km       m/s    (from) '];
% SimTrajectoryData = [SimTrajectoryData newline '-------------------------------'];
SimTrajectoryData = [SimTrajectoryData newline newline 'Altitude  Min Wind  Nom Wind  Max Wind  Min Dir  Nom Dir  Max Dir '];
SimTrajectoryData = [SimTrajectoryData newline         '      km       m/s       m/s       m/s    (from)  (from)   (from) '];
SimTrajectoryData = [SimTrajectoryData newline '------------------------------------------------------------------------'];

for alt = [ground 2500 5000 7500 10000 12500 15000 20000 30000 40000]
    disp_height = alt/1000;
    disp_minwind = sqrt((EventData_WINDE_MIN_MODEL(alt))^2 + (EventData_WINDN_MIN_MODEL(alt))^2);
    disp_nomwind = sqrt((EventData_WINDE_MODEL(alt))^2 + (EventData_WINDN_MODEL(alt))^2);
    disp_maxwind = sqrt((EventData_WINDE_MAX_MODEL(alt))^2 + (EventData_WINDN_MAX_MODEL(alt))^2);
    disp_mindir = compassdir(wrapTo360(atan2d(EventData_WINDE_MIN_MODEL(alt),EventData_WINDN_MIN_MODEL(alt))));
    disp_nomdir = compassdir(wrapTo360(atan2d(EventData_WINDE_MODEL(alt),EventData_WINDN_MODEL(alt))));
    disp_maxdir = compassdir(wrapTo360(atan2d(EventData_WINDE_MAX_MODEL(alt),EventData_WINDN_MAX_MODEL(alt))));
    if alt == ground
        %SimTrajectoryData = [SimTrajectoryData newline sprintf(['%8s' fm_wind fm_dir], 'ground', disp_nomwind, disp_nomdir)];
        SimTrajectoryData = [SimTrajectoryData newline sprintf(['%8s' fm_wind fm_wind fm_wind fm_dir fm_dir fm_dir], 'ground', disp_minwind, disp_nomwind, disp_maxwind, disp_mindir, disp_nomdir, disp_maxdir)];
    else
        %SimTrajectoryData = [SimTrajectoryData newline sprintf([fm_alt fm_wind fm_dir], disp_height, disp_nomwind, disp_nomdir)];
        SimTrajectoryData = [SimTrajectoryData newline sprintf([fm_alt fm_wind fm_wind fm_wind fm_dir fm_dir fm_dir], disp_height, disp_minwind, disp_nomwind, disp_maxwind, disp_mindir, disp_nomdir, disp_maxdir)];
    end
end
SimTrajectoryData = [SimTrajectoryData newline newline 'NOTE: Wind variation is analyzed on a vector basis, so min and max wind scalar value will not necessarily fall in order.'];


% ***************************************
% Write Press Release Templates

% Arbitrate plain English event size
if nom_energy < 0.001
    eventsize = 'small meteor fireball';
elseif nom_energy < 0.01
    eventsize = 'meteor fireball';
elseif nom_energy < 0.1
    eventsize = 'large meteor fireball';
elseif nom_energy > 1
    eventsize = 'very large meteor fireball';
else
    eventsize = 'meteor';
end

SimStory = sprintf('%s, %s, %s - %s local time, A %s was observed heading %s at %0.0f mph, and ending at a height of %0.0f miles above the ground.', NearestTown, State, Country, datestr(entrytime + hours(timezone),'dddd, mmmm dd, yyyy,HH:MM AM'), eventsize, compassdir2(nom_bearing), round(nom_speed*2.23694,-3), (ref_elevation-ground)*0.000621371);
SimStoryMetric = sprintf('%s, %s, %s - %s local time, A %s was observed heading %s at %0.0f km/s, and ending at a height of %0.0f km above the ground.', NearestTown, State, Country, datestr(entrytime + hours(timezone),'dddd, mmmm dd, yyyy,HH:MM AM'), eventsize, compassdir2(nom_bearing), nom_speed/1000, (ref_elevation-ground)/1000);
SimStoryTechnical = sprintf('%s, %s, %s - %s UTC, A %s was observed heading %s at %0.0f km/s, and ending at a height of %0.0f km.', NearestTown, State, Country, datestr(entrytime,'dddd, mmmm dd, yyyy, HH:MM'), eventsize, compassdir(nom_bearing), nom_speed/1000, (ref_elevation-ground)/1000);

% End Press Release Templates
% ***************************************

% Display the trajectory data to the command window
SimStory
SimStoryMetric
SimStoryTechnical
SimTrajectoryData

% Write data to file
readme = [SimTrajectoryData newline newline 'Public Press Release Template: ' newline SimStory newline newline 'Public Press Release Template (Metric): ' newline SimStoryMetric newline newline 'Scientific Press Release Template: ' newline SimStoryTechnical newline newline release_statement newline datestr(datetime('now','TimeZone','UTC'),'yyyy/mm/dd HH:MM UTC')];
writematrix(readme,[exportfolder '\readme_' exportfoldername '.txt'],'QuoteStrings',false);