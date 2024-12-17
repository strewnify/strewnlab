function filepath = testquadrangle(eventfolder, lat1, lat2, long1, long2, GE)
%TESTQUADRANGLE Export a basic quadrangle to KML
% filepath = testquadrangle(eventfolder, lat1, lat2, long1, long2)
% lat and long order do not matter

if nargin == 5
    GE = true;
end

% Remove slash from export path, if needed (non-standard)
if eventfolder(end) == '\' || eventfolder(end) == '/'
    eventfolder = eventfolder(1:(end-1));        
end

% Starting at the SW corner, and moving clockwise, resolve the coordinates
p1_lat = min(lat1,lat2);
p1_long = min(long1,long2);
p2_lat = max(lat1,lat2);
p2_long = min(long1,long2);
p3_lat = max(lat1,lat2);
p3_long = max(long1,long2);
p4_lat = min(lat1,lat2);
p4_long = max(long1,long2);

minlat = fix(mean([p1_lat p2_lat p3_lat p4_lat]));
minlong = fix(mean([p1_long p2_long p3_long p4_long]));

% Generate a path and filename
filename = sprintf('TestQuadrangle_%.0f_%.0f', minlat, minlong);
filepath = [eventfolder '\' filename '.kml'];

% Rename the file and copy to the event folder
copyfile([getSession('folders','mainfolder') '\templates\TestQuadrangle.kml'],filepath)

% open the file, with write access
[FID, ~] = fopen(filepath);

% If the file opened, search it for AMS Event ID
if FID < 0
    logformat(sprintf('Cannot open file at %s',filepath),'ERROR');
else
    % Read the file
    file_contents = fread(FID,'*char')';
    fclose(FID);

    % Check file validity
    if ~contains(file_contents(1:50),'xml ver')
        logformat('Unable to process KML file, file format invalid!','WARN')

    % if the file is valid, replace template names
    else
        
        % Replace template coordinates
        file_contents = regexprep(file_contents,'p1_lat',sprintf('%.6f',p1_lat));
        file_contents = regexprep(file_contents,'p2_lat',sprintf('%.6f',p2_lat));
        file_contents = regexprep(file_contents,'p3_lat',sprintf('%.6f',p3_lat));
        file_contents = regexprep(file_contents,'p4_lat',sprintf('%.6f',p4_lat));
        file_contents = regexprep(file_contents,'p1_long',sprintf('%.6f',p1_long));
        file_contents = regexprep(file_contents,'p2_long',sprintf('%.6f',p2_long));
        file_contents = regexprep(file_contents,'p3_long',sprintf('%.6f',p3_long));
        file_contents = regexprep(file_contents,'p4_long',sprintf('%.6f',p4_long));
        file_contents = regexprep(file_contents,'TestQuadrangle',filename);
                
        % Re-write the file
        FID  = fopen(filepath,'w');
        fprintf(FID,'%s',file_contents);
        
    end
end

% Close the file
if exist('FID','var')
    fclose(FID);
end

% If Google Earth selected, load the template and delete the file
if GE
    winopen(filepath)
    pause(2)
    %delete(temp_GE_filepath)    
else
    logformat(sprintf('KML quadrangle exported to %s',filepath),'INFO')
end

