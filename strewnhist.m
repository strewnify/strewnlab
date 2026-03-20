% STREWNHIST Produces a gridded probability map for meteorite
% hunting, with gridsize specified in meters.

% Update file and folder names and query data permissions, if needed
syncevent

% Plot margin, in percent
plotmargin = [20 20 20 20];

% Set overall filter for invalid data
setfilter

% Adjust for polygons
if exist('EventData_Searched','var')
    % Ask for user input
    if getSession('state','userpresent')
        user_quest = 'Adjust for Searched Areas?';
        logformat(user_quest,'USER')
        answer = questdlg(user_quest,'Searched Area Option','Yes','No','No');
    else
        answer = 'No';
    end
    % Handle response
    switch answer
        case 'Yes'
            for area_idx = 1:size(EventData_Searched,2)
                searched_data = inpolygon(strewndata.Latitude,strewndata.Longitude,EventData_Searched(area_idx).lat,EventData_Searched(area_idx).lon);
                searched = percentfilter(searched_data, EventData_Searched(area_idx).efficiency);   
                filter = filter & ~searched;
            end
                        
        case 'No'
            % Do nothing
            
        otherwise
            logformat('Unexpected response','ERROR')        
    end
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
fig_strewnfield = figure
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
strewnhist_vals = histogram2(strewndata.Longitude(filter),strewndata.Latitude(filter),Long_edges, Lat_edges,'DisplayStyle','tile','EdgeColor',edge_type,'Normalization','probability')
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

if exist('observations', 'var')
    %[fig_radarheatmap, station_summary] = binAndSummarize(observations(valid_observations,:),EventData_station_metadata);
    [fig_radarheatmap, station_summary] = binAndSummarize2(observations(valid_observations,:),EventData_station_metadata);
    NEXRAD_probability_report = generateSweepReport(observations(valid_observations,:),EventData_station_metadata);
end