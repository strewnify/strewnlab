function [points] = exportpins(exportfolder, filename, foldername, LATS, LONS, Altitudes, labels)
%EXPORTPINS Exports the trajectory path to a kml file, in both 2D and 3D format.
% Inputs are as follows:
% exportfolder - folder where the file will be saved 
% filename - name of the kml file, to be exported
% foldername - name of the folder that will appear in Google Earth
% LATS - latitude array
% LONS - longitude array
% Altitudes - scalar or array to define altitude of pins
% labels - optional cell array of pin labels

% if a scalar is provided for altitude, create an array of that scalar
if numel(Altitudes) ~= numel(LATS) 
    scalar = Altitudes;
    Altitudes = scalar .* ones(1,numel(LATS));
end

% Generate kml text
kmltxt_path = '<?xml version="1.0" encoding="UTF-8"?>';
kmltxt_path = [kmltxt_path newline '<kml xmlns="http://www.opengis.net/kml/2.2">'];
kmltxt_path = [kmltxt_path newline '<Document>'];
kmltxt_path = [kmltxt_path newline '	<name>' filename '.kml</name>'];
kmltxt_path = [kmltxt_path newline '	<Folder>'];
kmltxt_path = [kmltxt_path newline '		<name>' foldername '</name>'];
kmltxt_path = [kmltxt_path newline '		<open>1</open>'];

% write pin data
for i = 1:numel(LATS)
    kmltxt_path = [kmltxt_path newline '		<Placemark>'];
    
    % if label is not provided, use Pin 1, Pin 2,...
    if nargin == 6
        kmltxt_path = [kmltxt_path newline '			<name>Pin ' num2str(i) '</name>'];
    else
        kmltxt_path = [kmltxt_path newline '			<name>' labels{i} '</name>'];
    end
    kmltxt_path = [kmltxt_path newline '			<Point>'];
    kmltxt_path = [kmltxt_path newline '				<coordinates>'];
    kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,%.1f',LONS(i),LATS(i),Altitudes(i))];
    kmltxt_path = [kmltxt_path newline '				</coordinates>'];
    kmltxt_path = [kmltxt_path newline '			</Point>'];
    kmltxt_path = [kmltxt_path newline '		</Placemark>'];
end

kmltxt_path = [kmltxt_path newline '	</Folder>'];
kmltxt_path = [kmltxt_path newline '</Document>'];
kmltxt_path = [kmltxt_path newline '</kml>'];

% Save the File

% get home directory and go to export directory
homefolder = pwd;
cd(exportfolder)

% Write text file
fid = fopen([filename '.kml'],'wt');
fprintf(fid, kmltxt_path);
fclose(fid);

% return to home directory
cd(homefolder)

points = [1:i ; LATS ; LONS]';