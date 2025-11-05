% SETFILTER

% mass filter, in kilograms
plot_materials = {'all'};
plot_minmass = 0; plot_maxmass = inf;

% Bearing
bearingmin = 0;
bearingmax = 360;

% Filter masses that continued ablation in darkflight
% Feature needs further testing, requires calibration and simulation using ablation_thresh
filter_darkflight = darkflight_elevation - error_elevation;
% filter_darkflight = -999;

% Wind variation
error_windmin = weather_minsigma; 
error_windmax = weather_maxsigma;

% Lookup the mass filtered indices
filter = (strewndata.mass >= plot_minmass) & (strewndata.mass <= plot_maxmass) & (strewndata.darkflight > filter_darkflight) & (strewndata.error_wind >= error_windmin) & (strewndata.error_wind <= error_windmax) & (strewndata.bearing >= bearingmin) & (strewndata.bearing <= bearingmax);
%filter = (strewndata.mass >= lower_edges(1)) & (strewndata.mass <= upper_edges(end)) & (strewndata.darkflight > filter_darkflight) & (strewndata.error_wind >= wnd_min) & (strewndata.error_wind <= wnd_max);

if ~strcmp(plot_materials{1},'all')
    filter = filter & matches(strewndata.material,plot_materials);
end

% If density is measured, filter out-of-range density
if meas_density ~= 0
    filter = filter & strewndata.density > (meas_density * (1-meas_density_err)) & strewndata.density < (meas_density * (1+meas_density_err));
end

% Compile valid rockID's for other functions, like SIMSENSOR
% This has to compiled after running full scenarios, because data recorded
% during the simulation will not have a priori knowledge of darkflight
valid_rockIDs = strewndata.rockID(filter);
if exist('observations','var')
    valid_observations = ismember(observations.rockID,valid_rockIDs);
end

