temp_IDs = unique(observations.StationID);

% Export data sample for each station

% Find matching Station Data
temp_indices = find(observations.P_detect > 0.1);

% Take a random sample of the filtered data
temp_idx = temp_indices(unique(randi(numel(temp_indices),1,10000)));

%exportpins(exportfolder,'StationData','StationData',observations.Lat(temp_idx)', observations.Long(temp_idx)' ,(observations.Alt_km(temp_idx).*1000)', cellstr(num2str(observations.Mass_kg(temp_idx).*1000,'%.0f'))')
exporttimepins(exportfolder,'StationData','StationData',observations.Lat(temp_idx)', observations.Long(temp_idx)' ,(observations.Alt_km(temp_idx).*1000)',(observations.ObservationTime(temp_idx))', cellstr(num2str(observations.Mass_kg(temp_idx).*1000,'%.0f'))')
clear temp_*