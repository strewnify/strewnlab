% % FIRST SCRIPT TO PULL UNIQUE STATION NAMES
% numcells = size(GMN_data,1);
% stations = {};
% for idx = 1:numcells
%     station_raw = strsplit(GMN_data.Participating{idx},',');
%     stations = [stations station_raw];
% end

% % SECOND SCRIPT TO PULL STATION OBSERVATIONS
% for idx = 21186:21756
%     StationID = sdb_Sensors.StationID(idx);
%     Index = strfind(GMN_data.Participating, StationID);
%     StationData.(StationID).Lat = [];
%     StationData.(StationID).Long = [];
%     
%     % find each station in the data
%     for data_idx = 1:size(Index,1) 
%         if ~isempty(Index{data_idx})
%             StationData.(StationID).Lat(end+1) = GMN_data.ref_Lat(data_idx);
%             StationData.(StationID).Long(end+1) = GMN_data.ref_Long(data_idx);
%         end
%     end
% end

% % THIRD SCRIPT TO AVERAGE LAT/LONG
% earth_km = referenceEllipsoid('earth','km');
% for idx = 21186:21756
%     clear p_dist
%     StationID = sdb_Sensors.StationID(idx);
%     sdb_Sensors.LAT(idx) = mean(StationData.(StationID).Lat);
%     sdb_Sensors.LONG(idx) = mean(StationData.(StationID).Long);
%     p_dist = distance(sdb_Sensors.LAT(idx), sdb_Sensors.LONG(idx),StationData.(StationID).Lat(1),StationData.(StationID).Long(1), earth_km);
%     for point = 2:numel(StationData.(StationID).Lat)
%         p_dist = max(p_dist,distance(sdb_Sensors.LAT(idx), sdb_Sensors.LONG(idx),StationData.(StationID).Lat(point),StationData.(StationID).Long(point), earth_km));
%     end
%     if numel(StationData.(StationID).Lat) < 20
%         sdb_Sensors.range_km(idx) = 500;
%     else
%         sdb_Sensors.range_km(idx) = p_dist*1.1;
%     end
%     %sdb_Sensors.Altitude_m(idx) = getElevations(sdb_Sensors.LAT(idx),sdb_Sensors.LONG(idx), 'key', GoogleMapsAPIkey );
% end
