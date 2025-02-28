%EXPORTSTREWNFIELD Exports current figure as a png file with transparent background.

% enter export mode
setExporting(true);

% Update file and folder names and query data permissions, if needed
clear 'SimVersion' % reset version
syncevent

nowtime = datetime('now','TimeZone','UTC');
export_filename = [SimulationName '_StrewnField_' datestr(nowtime,'yyyymmdd_HHMMSS')];

% Backup the workspace
strewnbackup

% export the strewn field map
 try
    % change directory
    cd(exportfolder)

    % Set the current figure to the strewn field histogram
    figure(fig_strewnfield);
    
    % Save the current image to file
    saveas(fig_strewnfield,[export_filename '.png']);
    
    % Set color white to transparent
    img = imread([export_filename '.png']);   % an rgb image
    imwrite(img, [export_filename '.png'], 'Transparency', [1 1 1]);

    % return to main folder
    cd(getSession('folders','mainfolder'))

    % Get tick mark locations
    x_ticks = xticks;
    y_ticks = yticks;
    % [NW SW SE]
    align_lats = [y_ticks(end) y_ticks(1) y_ticks(1)];
    align_lons = [x_ticks(1) x_ticks(1) x_ticks(end)];

 catch
    % return to main folder
    cd(getSession('folders','mainfolder'))
    logformat('Error in strewn field image export!','ERROR');
 end

% MAKEKMZ needs a lot of work
try
    % change directory
    cd(exportfolder)
    
    % export KMZ file
    makekmz(strewnhist_vals.Values, Lat_edges, Long_edges,'imname',export_filename)
catch
     % return to main folder
    cd(getSession('folders','mainfolder'))
    logformat('Error in strewn field KMZ export!','WARN');
end

% Export strewnfield alignment pins
exportpins(exportfolder, [SimulationName '_StrewnField_' datestr(nowtime,'yyyymmdd_HHMMSS') '_AlignmentPins'],'Alignment Pins', align_lats, align_lons, 0, [{'NW'} {'SW'} {'SE'}]);

% Export finds, if any public data exists
if exist('EventData_Finds','var') && any(permission_filter)
    if numel(Permissions) == 1 && (Permissions == "Public" || Permissions == "None") % if public
        exportpins(exportfolder, [SimulationName '_Finds_' datestr(nowtime,'yyyymmdd_HHMMSS')],'Finds', EventData_Finds.Latitude(permission_filter)', EventData_Finds.Longitude(permission_filter)', 0, stringmass(EventData_Finds.mass_grams(permission_filter)./1000));
    else % confidential data exists
        exportpins([getSession('folders','secreteventsfolder') '\' SimEventID '_' SimFilename '_CONFIDENTIAL'], [SimulationName '_Finds_' datestr(nowtime,'yyyymmdd_HHMMSS') '_' DataPermissionsFilename],'Finds', EventData_Finds.Latitude(permission_filter)', EventData_Finds.Longitude(permission_filter)', 0, stringmass(EventData_Finds.mass_grams(permission_filter)./1000));
    end
end

% Generate weather data plot
plotweather

% Export air density data (for Gucsik Bence)
export_rho

% Generate strewn mass zones
zoneplot

% Export the 2D and 3D path to kml 
exportpath(nom_startlocation(1), nom_startlocation(2), nom_startaltitude, nom_darklocation(1), nom_darklocation(2), darkflight_elevation, exportfolder, [SimulationName '_Path' SimVersionSfx])

% Print trajectory data
printtrajectory

% Export radar binned data, if existing
if exist('fig_radarheatmap','var')
    try
        export_filename = [SimulationName '_NEXRAD_' datestr(nowtime,'yyyymmdd_HHMMSS')];
                           
        % change directory
        cd(exportfolder)

        % Save the current image to file
        saveas(fig_radarheatmap,[export_filename '.png']);

        % return to main folder
        cd(getSession('folders','mainfolder'))
    catch
        logformat('Failed to export radar heatmap','WARN')
    end
end

% exit export mode
setExporting(false);
