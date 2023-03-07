end_idx = 64; %clipped for anomaly
start_height = 25300;
end_height = 20900;
z_speed = (start_height - end_height)/(time_s(end_idx)-time_s(1));

for idx = 1:end_idx
    met_h(idx,1) = start_height - z_speed * (time_s(idx) - time_s(1));
    [met_LAT(idx,1), met_LONG(idx,1), met_slantrange(idx,1)] = aer2geosolve(view_AZ(idx), view_ELEV(idx), GLM16_lat, GLM16_long, GLM16_height, met_h(idx,1), planet);
end

%plot(GLM_data.met_LONG, GLM_data.met_LAT )
%plot(GLM_data.time_s, GLM_data.met_LAT )
%plot(GLM_data.time_s, GLM_data.met_h )

% Calculate aspect ratio at event latitude, for graphing
lat_metersperdeg = 2*planet.ellipsoid_m.MeanRadius*pi/360;
long_metersperdeg = 2*planet.ellipsoid_m.MeanRadius*pi*cos(deg2rad(met_LAT(1)))/360;

% % Resample filter
% filter = false(size(GLM_data,1),1);
% time_prev = 0;
% filter(1,1) = 1; 
% step = 0.01;
% for i = 2:size(GLM_data,1)
%     if GLM_data.time_s(i) > time_prev + step
%         filter(i) = true;
%         time_prev = GLM_data.time_s(i);
%     end
% end

figure
%scatter3(met_LONG, met_LAT, met_h)
comet3(met_LONG, met_LAT, met_h)
grid on
daspect([1/long_metersperdeg 1/lat_metersperdeg 1]);
hold on
title(['Event Y20200221-07Z-19Q: Santa Filomena, GOES 16 Data' newline  num2str(met_h(1)) ' to ' num2str(met_h(end)) ' km Altitude Assumption'])
export_latlong = [time_s(1:end_idx) met_LAT met_LONG met_h];

[nom_AZ, nom_ELEV, nom_slantRange] = geodetic2aer(met_LAT(1), met_LONG(1), met_h(1), met_LAT(end), met_LONG(end), met_h(end),planet);
nom_AZ = wrapTo360(nom_AZ+180)
nom_SLOPE = 90 - nom_ELEV
nom_speed_kps = z_speed/cos(deg2rad(nom_SLOPE))/1000
% need a solver to fit a 3D line and calculate slope

