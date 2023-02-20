% PLOTFINDS plots meteorite find data

% if plot masses have not been assigned, include all
if ~exist('plot_maxmass','var')
    plot_minmass = 0; plot_maxmass = inf;    
end

% Calculate scenario-specific parameters
EventData_Finds.mass_kg = EventData_Finds.mass_grams ./ 1000; % mass in kilograms
EventData_Finds.volume_m3 = EventData_Finds.mass_kg ./ nom_density; % volume in cubic meters
EventData_Finds.diameter_m = (6.*EventData_Finds.volume_m3./pi).^(1/3); % diameter in meters

% Filter all finds by mass
find_filter = (EventData_Finds.mass_kg >= plot_minmass) & (EventData_Finds.mass_kg <= plot_maxmass);

% filter out confidential data
if exist('permission_filter','var')
    find_filter = find_filter & permission_filter;
end

% plot finds
scatter(EventData_Finds.Longitude(find_filter),EventData_Finds.Latitude(find_filter),EventData_Finds.diameter_m(find_filter).*marksize*100,'k')