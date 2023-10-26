%EXPORTSTREWNFIELD Exports current figure as a png file with transparent background.

% enter export mode
exporting = true;

% Update file and folder names and query data permissions, if needed
syncevent

nowtime = datetime('now','TimeZone','UTC');
pngfilestring = [SimulationName '_StrewnField_' datestr(nowtime,'yyyymmdd_HHMMSS') '.png'];

% Backup the workspace
strewnbackup

try
    % change directory
    cd(exportfolder)

    % Save the current image to file
    saveas(gcf,pngfilestring);
    
    % Set color white to transparent
    img = imread(pngfilestring);   % an rgb image
    imwrite(img, pngfilestring, 'Transparency', [1 1 1]);

    % return to main folder
    cd(mainfolder)

    % Get tick mark locations
    x_ticks = xticks;
    y_ticks = yticks;
    % [NW SW SE]
    align_lats = [y_ticks(end) y_ticks(1) y_ticks(1)];
    align_lons = [x_ticks(1) x_ticks(1) x_ticks(end)];

catch
    % return to main folder
    cd(mainfolder)
    logformat('Error in strewn field image export!','ERROR');
end

% MAKEKMZ needs a lot of work
% try
%     % change directory
%     cd(exportfolder)
%     
%     % export KMZ file
%     makekmz(strewnhist_vals.Values, Lat_edges, Long_edges)
% catch
%      % return to main folder
%     cd(mainfolder)
%     logformat('Error in strewn field KMZ export!','ERROR');
% end

% Export strewnfield alignment pins
exportpins(exportfolder, [SimulationName '_StrewnField_' datestr(nowtime,'yyyymmdd_HHMMSS') '_AlignmentPins'],'Alignment Pins', align_lats, align_lons, 0, [{'NW'} {'SW'} {'SE'}]);

% Export finds, if any public data exists
if exist('EventData_Finds','var') && any(permission_filter)
    if numel(Permissions) == 1 && (Permissions == "Public" || Permissions == "None") % if public
        exportpins(exportfolder, [SimulationName '_Finds_' datestr(nowtime,'yyyymmdd_HHMMSS')],'Finds', EventData_Finds.Latitude(permission_filter)', EventData_Finds.Longitude(permission_filter)', 0, stringmass(EventData_Finds.mass_grams(permission_filter)./1000));
    else % confidential data exists
        exportpins([secreteventsfolder '\' SimEventID '_' SimFilename], [SimulationName '_Finds_' datestr(nowtime,'yyyymmdd_HHMMSS') '_' DataPermissionsFilename],'Finds', EventData_Finds.Latitude(permission_filter)', EventData_Finds.Longitude(permission_filter)', 0, stringmass(EventData_Finds.mass_grams(permission_filter)./1000));
    end
end

% Generate weather data plot
plotweather

% Export air density data (for Gucsik Bence)
export_rho

% Generate strewn mass zones
zoneplot

% Export the 2D and 3D path to kml 
exportpath

% Print trajectory data
printtrajectory

% exit export mode
exporting = false;
