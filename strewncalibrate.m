% STREWNCALIBRATE Generate plots for each find and calculate strewn field
% statistical error

% Query data permissions
querydatapermissions

% Plot margin, in percent
plotmargin = [5 5 5 5];

% mass filter, in kilograms
plot_material = 'all';

% Wind bins
wnd_min = weather_minsigma;
wnd_max = weather_maxsigma;
wnd_step = (wnd_max - wnd_min)/3; 
wnd_bins = wnd_min:wnd_step:wnd_max;
wind_bins_lower_edges = wnd_bins(1:3);
wind_bins_upper_edges = wnd_bins(2:4);

% Filter masses that continued ablation in darkflight
% Feature untested, requires calibration and simulation using ablation_thresh
filter_darkflight = darkflight_elevation - error_elevation;
%filter_darkflight = ground;

% Bin data
log_base = 2;
[bin_counts,bin_edges] = histcounts(logb(EventData_Finds.mass_kg(EventData_Finds.mass_kg > minmass),log_base),'BinMethod','sturges');
bin_idx = 1:numel(bin_edges);
plot_idx = find(bin_counts > 0);
lower_edges = log_base.^bin_edges(plot_idx);
upper_edges = log_base.^bin_edges(plot_idx + 1);
 lower_edges = [0.0005 0.075 0.500];
 upper_edges = [0.005 0.250 0.900];

% Setup plot
figure
hold on
plot_idx = 0;
numbins = numel(lower_edges);

% setup static axes for all the find data under analysis
filter = (strewndata.mass >= lower_edges(1)) & (strewndata.mass <= upper_edges(end)) & (strewndata.darkflight > filter_darkflight) & (strewndata.error_wind >= wnd_min) & (strewndata.error_wind <= wnd_max);
if ~strcmp(plot_material,'all')
    filter = filter & strcmp(strewndata.material, plot_material);
end
plot_limit_values = setplotlimits([strewndata.Longitude(filter);EventData_Finds.Longitude], [strewndata.Latitude(filter);EventData_Finds.Latitude], plotmargin);

% For each wind bin
for wind_idx = 1:numel(wind_bins_lower_edges)

    % Wind variation bin
    error_windmin = wind_bins_lower_edges(wind_idx);
    error_windmax = wind_bins_upper_edges(wind_idx);
        
    % Plot each mass bin
    for idx = 1:numbins

        plot_minmass = lower_edges(idx);
        plot_maxmass = upper_edges(idx);


        % Lookup the mass filtered indices
        filter = (strewndata.mass >= plot_minmass) & (strewndata.mass <= plot_maxmass) & (strewndata.darkflight > filter_darkflight) & (strewndata.error_wind >= error_windmin) & (strewndata.error_wind <= error_windmax);
        if ~strcmp(plot_material,'all')
            filter = filter & strcmp(strewndata.material, plot_material);
        end

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
        plot_idx = plot_idx + 1;
        subplot(numel(wind_bins_lower_edges),numel(lower_edges),plot_idx)
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

        if strcmp(temp_unit1,temp_unit2)
            % Display title contains capitalized material label and mass filters
            strewnhist_title = [plot_material ' masses between ' temp_bin1 ' and ' temp_bin2 temp_unit2];
        else
            strewnhist_title = [plot_material ' masses between ' temp_bin1 temp_unit1 ' and ' temp_bin2 temp_unit2];
        end
        strewnhist_title = [strewnhist_title newline 'Wind sigma = ' num2str(wind_bins_lower_edges(wind_idx)) ' to ' num2str(wind_bins_upper_edges(wind_idx))];

        % Capitalize the title
        strewnhist_title = TitleCase(strewnhist_title);
        
        title(strewnhist_title);

        % Fix plot aspect ratio
        daspect([1/long_metersperdeg 1/lat_metersperdeg 1])

        % Set axis limits
        axis(plot_limit_values)

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

    end
end

% Display stats in the console
disp(['Grid size is ' num2str(gridsize) ' meters.'])
if exist('DataPermissionsTitle','var')
    disp(DataPermissionsTitle)
end

function m = logb(x,b)

m = log2(x)/log2(b);
end