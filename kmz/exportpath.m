%EXPORTPATH Exports the trajectory path to a kml file, in both 2D and 3D format.

% kml text
kmltxt_path = '<?xml version="1.0" encoding="UTF-8"?>';
kmltxt_path = [kmltxt_path newline '<kml xmlns="http://www.opengis.net/kml/2.2">'];
kmltxt_path = [kmltxt_path newline '<Document>'];
kmltxt_path = [kmltxt_path newline '	<name>' SimulationName '_Path.kml</name>'];
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
kmltxt_path = [kmltxt_path newline '		<Placemark>'];
kmltxt_path = [kmltxt_path newline '			<name>3D Path</name>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#Linestyle510</styleUrl>'];
kmltxt_path = [kmltxt_path newline '			<LineString>'];
kmltxt_path = [kmltxt_path newline '				<extrude>1</extrude>'];
kmltxt_path = [kmltxt_path newline '				<tessellate>1</tessellate>'];
kmltxt_path = [kmltxt_path newline '				<altitudeMode>absolute</altitudeMode>'];
kmltxt_path = [kmltxt_path newline '				<coordinates>'];
kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,%.1f %.6f,%.6f,%.1f',nom_startlocation(2),nom_startlocation(1),nom_startaltitude,nom_darklocation(2),nom_darklocation(1),darkflight_elevation)];
kmltxt_path = [kmltxt_path newline '				</coordinates>'];
kmltxt_path = [kmltxt_path newline '			</LineString>'];
kmltxt_path = [kmltxt_path newline '		</Placemark>'];
kmltxt_path = [kmltxt_path newline '		<Placemark>'];
kmltxt_path = [kmltxt_path newline '			<name>Path</name>'];
kmltxt_path = [kmltxt_path newline '			<styleUrl>#inline2</styleUrl>'];
kmltxt_path = [kmltxt_path newline '			<LineString>'];
kmltxt_path = [kmltxt_path newline '				<tessellate>1</tessellate>'];
kmltxt_path = [kmltxt_path newline '				<coordinates>'];
kmltxt_path = [kmltxt_path newline sprintf('					%.6f,%.6f,0 %.6f,%.6f,0',nom_startlocation(2),nom_startlocation(1),nom_darklocation(2),nom_darklocation(1))];
kmltxt_path = [kmltxt_path newline '				</coordinates>'];
kmltxt_path = [kmltxt_path newline '			</LineString>'];
kmltxt_path = [kmltxt_path newline '		</Placemark>'];
kmltxt_path = [kmltxt_path newline '	</Folder>'];
kmltxt_path = [kmltxt_path newline '</Document>'];
kmltxt_path = [kmltxt_path newline '</kml>'];

% change directory
cd(exportfolder)

% Write text file
fid = fopen([SimulationName '_Path' SimVersionSfx '.kml'],'wt');
fprintf(fid, kmltxt_path);
fclose(fid);

% return to main folder
cd(mainfolder)