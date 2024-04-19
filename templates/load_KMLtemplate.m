function temp_GE_filepath = load_KMLtemplate(eventfolder, SimEventID, SimulationName, GE)
%LOAD_KMLTEMPLATE Create a basic folder structure for Google Earth
% If GE is true, load the template into Google Earth and delete the file

% Remove slash from export path, if needed (non-standard)
if eventfolder(end) == '\' || eventfolder(end) == '/'
    eventfolder = eventfolder(1:(end-1));        
end
    
% Load the template from file
temp_GE_filepath = [eventfolder '\' SimEventID '_' SimulationName '_Template.kml'];

% Rename the file and copy to the event folder
copyfile([getSession('folders','mainfolder') '\templates\EventID_EventName_Template.kml'],temp_GE_filepath)

% open the file, with write access
[FID, ~] = fopen(temp_GE_filepath);

% If the file opened, search it for AMS Event ID
if FID < 0
    logformat(sprintf('Cannot open file at %s',temp_GE_filepath),'ERROR');
else
    % Read the file
    file_contents = fread(FID,'*char')';
    fclose(FID);

    % Check file validity
    if ~contains(file_contents(1:50),'xml ver')
        logformat('Unable to process KML file, file format invalid!','WARN')

    % if the file is valid, replace template names
    else
        
        % Top Folder Name
        file_contents = regexprep(file_contents,'TopFolderName',[SimEventID '_' SimulationName]);

        % Export Folder Name
        file_contents = regexprep(file_contents,'ExportFolderName',[SimulationName '_StrewnLAB_V1']);
        
        % Re-write the file
        FID  = fopen(temp_GE_filepath,'w');
        fprintf(FID,'%s',file_contents);
        
    end
end

% Close the file
if exist('FID','var')
    fclose(FID);
end

% If Google Earth selected, load the template and delete the file
if GE
    winopen(temp_GE_filepath)
    pause(2)
    delete(temp_GE_filepath)
    logformat(sprintf('KML template %s imported into Google Earth',[SimEventID '_' SimulationName]),'INFO')
else
    logformat(sprintf('KML template exported to %s',temp_GE_filepath),'INFO')
end

