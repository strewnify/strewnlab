function GLM_data = dom_glm(GLM_data,start_height, z_speed)
strewnconfig

%met_h = linspace(start_height,end_height,size(GLM_data,1))';

met_h = start_height;
for i = 2:size(GLM_data,1)
    met_h(i,1) = met_h(i-1,1) - z_speed*1000*(GLM_data.time_s(i) - GLM_data.time_s(i-1));
end
end_height = met_h(end);

% [GOES16data.m2sat_AZ, GOES16data.m2sat_ELEV, GOES16data.slantRange] = geodetic2aer(sat_lat, sat_long, sat_h, GOES16data.latitude, GOES16data.longitude, 0,planet.ellipsoid_m);
[GLM_data.met_LAT, GLM_data.met_LONG, GLM_data.met_h] = aer2geodetic(GLM_data.m2sat_AZ, GLM_data.m2sat_ELEV, met_h./sin(deg2rad(GLM_data.m2sat_ELEV)), GLM_data.latitude, GLM_data.longitude,0 , planet);

%plot(GLM_data.met_LONG, GLM_data.met_LAT )
%plot(GLM_data.time_s, GLM_data.met_LAT )
%plot(GLM_data.time_s, GLM_data.met_h )

% Calculate aspect ratio at event latitude, for graphing
lat_metersperdeg = 2*planet.radius_m*pi/360;
long_metersperdeg = 2*planet.radius_m*pi*cos(deg2rad(GLM_data.met_LAT(1)))/360;

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

filter = true(size(GLM_data,1),1);

comet3(GLM_data.met_LONG(filter), GLM_data.met_LAT(filter), GLM_data.met_h(filter))
daspect([1/long_metersperdeg 1/lat_metersperdeg 1]);
title(['Event Y20200221-07Z-19Q: Dominican Republic, GOES 16 Data' newline  num2str(start_height) ' to ' num2str(end_height) ' km Altitude Assumption'])
