function exportpath(start_lat, start_long, start_height_m, end_lat, end_long, end_height_m, exportfolder, export_filename)
%EXPORTPATH Exports the trajectory path to a kml file, in both 2D and 3D format.

% Get current directory
startfolder = pwd;

if nargin == 8
    % do nothing
elseif nargin == 7
    export_filename = 'TestPathExport';
elseif nargin == 6
    export_filename = 'TestPathExport';
    exportfolder = getSession('folders','workingfolder');
elseif nargin ~= 7
    logformat('Invalid number of inputs.',ERROR')
end

% Add kml extension to filename
export_filename = [export_filename '.kml'];

% Check for valid coordinates
if ~islat(start_lat) || ~islong(start_long) || ~islat(end_lat) || ~islong(end_long)
    logformat('Invalid coordinates provided for meteor path','ERROR')
end

% Calculate Arrow points
arrow_len = 500; % arrow leg length in meters
arrow_ang = 32;  % arrow leg angle
[ARCLEN, backpath_AZ] = distance(end_lat,end_long,start_lat,start_long, getPlanet('ellipsoid_m'))
[arrow_lat1, arrow_long1] = reckon(end_lat, end_long, arrow_len, wrapTo360(backpath_AZ+arrow_ang), getPlanet('ellipsoid_m'));
[arrow_lat2, arrow_long2] = reckon(end_lat, end_long, arrow_len, wrapTo360(backpath_AZ-arrow_ang), getPlanet('ellipsoid_m'));

% kml text
kmltxt_path = '<?xml version="1.0" encoding="UTF-8"?>';
kmltxt_path = [kmltxt_path newline '<kml xmlns="http://www.opengis.net/kml/2.2">'];
kmltxt_path = [kmltxt_path newline '<Document>'];
kmltxt_path = [kmltxt_path newline '	<name>' export_filename '</name>'];
kmltxt_path = [kmltxt_path newline '	<Style id="inline33">'];
kmltxt_path = [kmltxt_path newline '		<LineStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>ff00ffff</color>'];
kmltxt_path = [kmltxt_path newline '			<width>4</width>'];
kmltxt_path = [kmltxt_path newline '		</LineStyle>'];
kmltxt_path = [kmltxt_path newline '	</Style>'];
kmltxt_path = [kmltxt_path newline '	<Style id="Linestyle500">'];
kmltxt_path = [kmltxt_path newline '		<LineStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>ff00ffff</color>'];
kmltxt_path = [kmltxt_path newline '			<width>4</width>'];
kmltxt_path = [kmltxt_path newline '		</LineStyle>'];
kmltxt_path = [kmltxt_path newline '		<PolyStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>b3ffffff</color>'];
kmltxt_path = [kmltxt_path newline '			<outline>0</outline>'];
kmltxt_path = [kmltxt_path newline '		</PolyStyle>'];
kmltxt_path = [kmltxt_path newline '	</Style>'];
kmltxt_path = [kmltxt_path newline '	<Style id="Linestyle52">'];
kmltxt_path = [kmltxt_path newline '		<LineStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>ff00ffff</color>'];
kmltxt_path = [kmltxt_path newline '			<width>4</width>'];
kmltxt_path = [kmltxt_path newline '		</LineStyle>'];
kmltxt_path = [kmltxt_path newline '		<PolyStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>b3ffffff</color>'];
kmltxt_path = [kmltxt_path newline '			<outline>0</outline>'];
kmltxt_path = [kmltxt_path newline '		</PolyStyle>'];
kmltxt_path = [kmltxt_path newline '	</Style>'];
kmltxt_path = [kmltxt_path newline '	<StyleMap id="inline2">'];
kmltxt_path = [kmltxt_path newline '		<Pair>'];
kmltxt_path = [kmltxt_path newline '			<key>normal</key>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#inline6</styleUrl>'];
kmltxt_path = [kmltxt_path newline '		</Pair>'];
kmltxt_path = [kmltxt_path newline '		<Pair>'];
kmltxt_path = [kmltxt_path newline '			<key>highlight</key>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#inline33</styleUrl>'];
kmltxt_path = [kmltxt_path newline '		</Pair>'];
kmltxt_path = [kmltxt_path newline '	</StyleMap>'];
kmltxt_path = [kmltxt_path newline '	<Style id="inline6">'];
kmltxt_path = [kmltxt_path newline '		<LineStyle>'];
kmltxt_path = [kmltxt_path newline '			<color>ff00ffff</color>'];
kmltxt_path = [kmltxt_path newline '			<width>4</width>'];
kmltxt_path = [kmltxt_path newline '		</LineStyle>'];
kmltxt_path = [kmltxt_path newline '	</Style>'];
kmltxt_path = [kmltxt_path newline '	<StyleMap id="Linestyle510">'];
kmltxt_path = [kmltxt_path newline '		<Pair>'];
kmltxt_path = [kmltxt_path newline '			<key>normal</key>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#Linestyle52</styleUrl>'];
kmltxt_path = [kmltxt_path newline '		</Pair>'];
kmltxt_path = [kmltxt_path newline '		<Pair>'];
kmltxt_path = [kmltxt_path newline '			<key>highlight</key>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#Linestyle500</styleUrl>'];
kmltxt_path = [kmltxt_path newline '		</Pair>'];
kmltxt_path = [kmltxt_path newline '	</StyleMap>'];
kmltxt_path = [kmltxt_path newline '	<Folder>'];
kmltxt_path = [kmltxt_path newline '		<name>Path</name>'];
kmltxt_path = [kmltxt_path newline '		<open>1</open>'];

% 3D Path (visibility off)
kmltxt_path = [kmltxt_path newline '		<Placemark>'];
kmltxt_path = [kmltxt_path newline '			<name>3D Path</name>'];
kmltxt_path = [kmltxt_path newline '			<visibility>0</visibility>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#Linestyle510</styleUrl>'];
kmltxt_path = [kmltxt_path newline '			<LineString>'];
kmltxt_path = [kmltxt_path newline '				<extrude>1</extrude>'];
kmltxt_path = [kmltxt_path newline '				<tessellate>1</tessellate>'];
kmltxt_path = [kmltxt_path newline '				<altitudeMode>absolute</altitudeMode>'];
kmltxt_path = [kmltxt_path newline '				<coordinates>'];
kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,%.1f %.6f,%.6f,%.1f',start_long,start_lat,start_height_m,end_long,end_lat,end_height_m)];
kmltxt_path = [kmltxt_path newline '				</coordinates>'];
kmltxt_path = [kmltxt_path newline '			</LineString>'];
kmltxt_path = [kmltxt_path newline '		</Placemark>'];

% Path
kmltxt_path = [kmltxt_path newline '		<Placemark>'];
kmltxt_path = [kmltxt_path newline '			<name>Path</name>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#inline2</styleUrl>'];
kmltxt_path = [kmltxt_path newline '			<LineString>'];
kmltxt_path = [kmltxt_path newline '				<tessellate>1</tessellate>'];
kmltxt_path = [kmltxt_path newline '				<coordinates>'];
kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,0 %.6f,%.6f,0',start_long,start_lat,end_long,end_lat)];
kmltxt_path = [kmltxt_path newline '				</coordinates>'];
kmltxt_path = [kmltxt_path newline '			</LineString>'];
kmltxt_path = [kmltxt_path newline '		</Placemark>'];

% Arrow
kmltxt_path = [kmltxt_path newline '		<Placemark>'];
kmltxt_path = [kmltxt_path newline '			<name>Arrow</name>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#inline2</styleUrl>'];
kmltxt_path = [kmltxt_path newline '			<LineString>'];
kmltxt_path = [kmltxt_path newline '				<tessellate>1</tessellate>'];
kmltxt_path = [kmltxt_path newline '				<coordinates>'];
kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,0 %.6f,%.6f,0 %.6f,%.6f,0',arrow_long1,arrow_lat1,end_long,end_lat,arrow_long2,arrow_lat2)];
kmltxt_path = [kmltxt_path newline '				</coordinates>'];
kmltxt_path = [kmltxt_path newline '			</LineString>'];
kmltxt_path = [kmltxt_path newline '		</Placemark>'];

% Closing
kmltxt_path = [kmltxt_path newline '	</Folder>'];
kmltxt_path = [kmltxt_path newline '</Document>'];
kmltxt_path = [kmltxt_path newline '</kml>'];

% change directory
cd(exportfolder)

% Write text file
fid = fopen(export_filename,'wt');
fprintf(fid, kmltxt_path);
fclose(fid);

% Log export
logformat(sprintf('Meteor path exported to %s\\%s',exportfolder,export_filename),'INFO')


% return to main folder
cd(startfolder)