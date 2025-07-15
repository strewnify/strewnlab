% STREWNCALIBRATE Generate plots for each find and calculate strewn field
% statistical error

% Query data permissions
querydatapermissions

% Plot margin, in percent
plotmargin = [5 5 5 5];

% Set overall filter for invalid data
setfilter

% setup static axes for all the find data under analysis
plot_limit_values = setplotlimits([strewndata.Longitude(filter);EventData_Finds.Longitude], [strewndata.Latitude(filter);EventData_Finds.Latitude], plotmargin);

% Wind bins
wnd_step = (error_windmax - error_windmin)/3; 
wnd_bins = error_windmin:wnd_step:error_windmax;
wind_bins_lower_edges = wnd_bins(1:3);
wind_bins_upper_edges = wnd_bins(2:4);

% Bin data
log_base = 2;
[bin_counts,bin_edges] = histcounts(logb(EventData_Finds.mass_kg(EventData_Finds.mass_kg > minmass),log_base),'BinMethod','sturges');
bin_idx = 1:numel(bin_edges);
plot_idx = find(bin_counts > 0);
lower_edges = log_base.^bin_edges(plot_idx);
upper_edges = log_base.^bin_edges(plot_idx + 1);
%  lower_edges = [0.0005 0.075 0.500];
%  upper_edges = [0.005 0.250 0.900];

% Setup plot
figure
hold on
plot_idx = 0;
numbins = numel(lower_edges);

% For each wind bin
for wind_idx = 1:numel(wind_bins_lower_edges)

    % Wind variation bin
    temp_windmin = wind_bins_lower_edges(wind_idx);
    temp_windmax = wind_bins_upper_edges(wind_idx);
        
    % Plot each mass bin
    for idx = 1:numbins

        plot_minmass = lower_edges(idx);
        plot_maxmass = upper_edges(idx);

        % Lookup the mass filtered indices
        temp_filter = filter & (strewndata.mass >= plot_minmass) & (strewndata.mass <= plot_maxmass) & (strewndata.error_wind >= temp_windmin) & (strewndata.error_wind <= temp_windmax);

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
        strewndata_minmass = min(strewndata.mass(temp_filter));
        strewndata_maxmass = max(strewndata.mass(temp_filter));
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
        histogram2(strewndata.Longitude(temp_filter),strewndata.Latitude(temp_filter),Long_edges, Lat_edges,'DisplayStyle','tile','EdgeColor',edge_type,'Normalization','probability')
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

% Calculate an individual vector for each find, to calibrate the strewn field to finds
cal_pct = 0.2; % percent error bin size for calibration
temp_lower = EventData_Finds.mass_kg - EventData_Finds.mass_kg .* cal_pct;
temp_upper = EventData_Finds.mass_kg + EventData_Finds.mass_kg .* cal_pct;

% Calculate calibration vectors for each find    
for idx = 1:size(EventData_Finds,1)

    % Filter on the zone relevant to each find
    temp_filt = filter & (strewndata.mass >= temp_lower(idx)) & (strewndata.mass <= temp_upper(idx));

    % if there is enough simulation data in the mass range, calculate a vector to adjust the strewnfield
    EventData_Finds.zone_lat(idx) = mean(strewndata.Latitude(temp_filt));
    EventData_Finds.zone_long(idx) = mean(strewndata.Longitude(temp_filt));            
end    


% Calculate zone vectors for each find
% These are the offsets for the strewnfield, to match the finds
[EventData_Finds.zoneDist_m , EventData_Finds.zoneAZ] = distance(EventData_Finds.zone_lat,EventData_Finds.zone_long,EventData_Finds.Latitude,EventData_Finds.Longitude, getPlanet('ellipsoid_m'));

% Calculate an overall correction vector for the strewnfield
% This is the offset for the strewnfield, to match the finds
[cal_dist_m , cal_AZ] = distance(mean(EventData_Finds.zone_lat),mean(EventData_Finds.zone_long), mean(EventData_Finds.Latitude),mean(EventData_Finds.Longitude),getPlanet('ellipsoid_m'));

% Report Calibration Results
temp_separator_width = 50;
fprintf('\n');
fprintf('%s\n', repmat('*', 1, temp_separator_width));  % 40 asterisks
fprintf('Calibration Results:\n');
fprintf('Offsets to the strewnfield, to match the finds\n\n');
fprintf('Individual Find Vectors:\n') 
fprintf('%5.0fg Sample: %.0f meters at %.2f degrees azimuth\n', EventData_Finds.mass_grams, EventData_Finds.zoneDist_m , EventData_Finds.zoneAZ)
fprintf('\nOverall Vector:\n %.0f meters at %.2f degrees azimuth\n', cal_dist_m, cal_AZ)
fprintf('%s\n', repmat('*', 1, temp_separator_width));  % 40 asterisks

% Display stats in the console
disp(['Grid size is ' num2str(gridsize) ' meters.'])
if exist('DataPermissionsTitle','var')
    disp(DataPermissionsTitle)
end

clear temp_*


