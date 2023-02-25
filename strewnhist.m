% STREWNHIST Produces a gridded probability map for meteorite
% hunting, with gridsize specified in meters.

% Update file and folder names and query data permissions, if needed
syncevent

% Plot margin, in percent
plotmargin = [20 20 20 20];

% mass filter, in kilograms
plot_materials = {'all'};
%plot_minmass = 1; plot_maxmass = 5;
plot_minmass = 0.001; plot_maxmass = inf;

% Filter masses that continued ablation in darkflight
% Feature untested, requires calibration and simulation using ablation_thresh
filter_darkflight = darkflight_elevation - error_elevation;
%filter_darkflight = -999;

% Wind variation
%error_windmin = weather_minsigma; error_windmax = weather_maxsigma;
error_windmin = -1.4; error_windmax = -0.8;

% Lookup the mass filtered indices
filter = (strewndata.mass >= plot_minmass) & (strewndata.mass <= plot_maxmass) & (strewndata.darkflight > filter_darkflight) & (strewndata.error_wind >= error_windmin) & (strewndata.error_wind <= error_windmax);
if ~strcmp(plot_materials{1},'all')
    filter = filter & matches(strewndata.material,plot_materials);
end

% remove 80% of searched polygon
insearched = inpolygon(strewndata.Latitude,strewndata.Longitude,searchedtxt.lat,searchedtxt.long);
insearched_idx = find(insearched);
randdel = rand(numel(insearched_idx),1) > 0.2; % generate random indices to delete
insearched_idx(randdel) = [];  % delete 20% of the indices
insearched(insearched_idx) = false; % set 20% of the indices to false
filter = filter & ~insearched % filter out 80% of data the searched area

% Convert meters to degrees of latitude and longitude
lat_gridsize = gridsize / lat_metersperdeg;
long_gridsize = gridsize / long_metersperdeg;

% Calculate grid edges
MINLAT = min(MINLAT,min(strewndata.Latitude));
MAXLAT = max(MAXLAT,max(strewndata.Latitude));
MINLONG = min(MINLONG,min(strewndata.Longitude));
MAXLONG = max(MAXLONG,max(strewndata.Longitude));
Lat_edges = MINLAT:lat_gridsize:MAXLAT;
Long_edges = MINLONG:long_gridsize:MAXLONG;

% Create a new plot
figure
hold on

% Create Plot Title
strewndata_minmass = min(strewndata.mass(filter));
strewndata_maxmass = max(strewndata.mass(filter));
strewndata_rounded_minmass = round(strewndata_minmass,3,'significant');
strewndata_rounded_maxmass = round(strewndata_maxmass,3,'significant');

if strewndata_rounded_minmass >= 1000
    temp_bin1 = num2str(strewndata_rounded_minmass/1000);
    temp_unit1 = 'tonne';
elseif strewndata_rounded_minmass >= 1
    temp_bin1 = num2str(strewndata_rounded_minmass);
    temp_unit1 = 'kg';
else
    temp_bin1 = num2str(strewndata_rounded_minmass*1000);
    temp_unit1 = 'g';
end    

if strewndata_rounded_maxmass >= 1000
    temp_bin2 = num2str(strewndata_rounded_maxmass/1000);
    temp_unit2 = 'tonne';
        
elseif strewndata_rounded_maxmass >= 1
    temp_bin2 = num2str(strewndata_rounded_maxmass);
    temp_unit2 = 'kg';
else
    temp_bin2 = num2str(strewndata_rounded_maxmass*1000);
    temp_unit2 = 'g';
end 

plot_material_label = join(plot_materials,'/');
plot_material_char = [upper(plot_material_label{1}(1)) plot_material_label{1}(2:end)];
if strcmp(temp_unit1,temp_unit2)
    % Display title contains capitalized material label and mass filters
    strewnhist_title = [plot_material_char ' masses between ' temp_bin1 ' and ' temp_bin2 temp_unit2];
else
    strewnhist_title = [plot_material_char ' masses between ' temp_bin1 temp_unit1 ' and ' temp_bin2 temp_unit2];
end
if Permissions ~= "None"
    strewnhist_title = [strewnhist_title newline DataPermissionsTitle];
end

title(strewnhist_title);

% Fix plot aspect ratio
daspect([1/long_metersperdeg 1/lat_metersperdeg 1])

% Set axis limits
axis(setplotlimits(strewndata.Longitude(filter), strewndata.Latitude(filter), plotmargin))

% Plot a bivariate histogram of the Monte Carlo results
histogram2(strewndata.Longitude(filter),strewndata.Latitude(filter),Long_edges, Lat_edges,'DisplayStyle','tile','EdgeColor',edge_type,'Normalization','probability')
% cb = colorbar();
% cb.Label.String = 'Find Probability';
% cb.Label.FontSize = 12;
% cb.Label.FontWeight = 'bold';

% Plot meteorite find locations, if available
if exist('EventData_Finds','var')
    plotfinds
end

% Display stats in the console
disp(['Grid size is ' num2str(gridsize) ' meters.'])
if exist('DataPermissionsTitle','var')
    disp(DataPermissionsTitle)
end