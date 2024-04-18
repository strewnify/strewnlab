function filepath_export = getamsKML(AMS_EventID, path_export)
%GETAMSKML Download and save the latest AMS trajectory KML file.
%

% Initialize
downloaded = false;

% Timestamp the download file
datetimestring = datestr(now,'yyyymmddHH');

% Add a slash to the export path, if missing
if path_export(end) ~= '\' || path_export(end) ~= '/'
    path_export = [path_export '\'];
end
    
% Extract AMS Event ID contents
% Example: '761-2023'
if length(strfind(AMS_EventID,'-')) == 1
    event_id = extractBefore(AMS_EventID,'-');    
    year_str = extractAfter(AMS_EventID,'-');
else
    logformat('Invalid AMS Event ID.','ERROR')
end

try
    FILENAME = ['AMS_Event' event_id '-' year_str '_Ver' datetimestring '.kml'];
    filepath_export = [path_export FILENAME];
    websave(filepath_export,['https://www.amsmeteors.org/members/imo_kml/view_trajectory_kml?event_id=' event_id '&event_year=' year_str]);
    downloaded = true;
    logformat(sprintf('%s saved to %s',FILENAME, path_export),'INFO')

catch
    logformat('AMS KML download failed, manual file download required.','DEBUG')
end

% Check the downloaded data
if downloaded
    
    % open the file, with write access
    [FID, ~] = fopen(filepath_export);
    
    % If the file opened, search it for AMS Event ID
    if FID < 0
        logformat(sprintf('Cannot open file at %s',filepath_export),'ERROR');
    else
        % Read the file
        file_contents = fread(FID,'*char')';
        fclose(FID);

        % Check file validity
        if ~contains(file_contents(1:50),'xml ver')
            logformat('Unable to process KML file, file format invalid!','WARN')
       
        % if the file is valid, search for AMS event ID
        else
            search_string = 'AMS Event#';
            correct_ID = [event_id ' - ' year_str];
            len_string = numel(search_string);
            
            % location of the event identifier
            file_idx = strfind(file_contents,search_string) + len_string;
            
            % If the correct ID is in the file, append a version number
            if contains(file_contents(file_idx:(file_idx + 20)),correct_ID)
                file_contents = regexprep(file_contents,correct_ID,[correct_ID ' Ver' datetimestring]);
            
            else
                logformat('Apparent KML file version mismatch.  Review KML file.','DEBUG')
            end
            
            % Re-write the file
            FID  = fopen(filepath_export,'w');
            fprintf(FID,'%s',file_contents);
            
            logformat(sprintf('KML file read/write successful. %s appended to EventID',['Ver' datetimestring]),'INFO')
        end
    end
end
   
if exist('FID','var')
    fclose(FID);
end
