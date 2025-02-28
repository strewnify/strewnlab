%ZONEPLOT  Update strewn field zone plot.

clear latitudes
clear longitudes
clear binindices
clear bin
clear filtered_strewndata

filtered_strewndata = strewndata(filter,:);


% Create a zoneplot folder, if it doesn't exist
if exist([exportfolder '\zoneplots'])~=7
    mkdir([exportfolder '\zoneplots']) % create folder
end

%Create/update figure 4
fig_zoneplot = figure;
hold on
title([SimulationName ' Mass Zones'])
xlabel('Longitude');
ylabel('Latitude');
axis([MINLONG MAXLONG MINLAT MAXLAT]);

% Fix plot aspect ratio
daspect([1/long_metersperdeg 1/lat_metersperdeg 1])

% Plot zones
bin = [0.000001 0.00001 0.0001 0.001 0.01 0.1 1 10 100 1000 10000 100000 1000000 10000000 100000000 1000000000 10000000000 ];
numbins = numel(bin) - 1;
color = {[0.5 0 1],'g','b','m',[0 0.4 0],[1 0.5 0],[1 1 0.95],'c','r','y','w','k','w','k','w','k','w'};

zoneplot_i = 0;

for i = 1:numbins
    try
        [longitudes, latitudes] = strewnzone(filtered_strewndata,bin(i),bin(i+1),11);
        fill(longitudes,latitudes,color{i})
        if bin(i) >= 1000
            temp_bin1 = [num2str(bin(i)/1000) 'tonne'];
        elseif bin(i) >= 1
            temp_bin1 = [num2str(bin(i)) 'kg'];
        else
            temp_bin1 = [num2str(bin(i)*1000) 'g'];
        end    
        
        if bin(i+1) >= 1000
            temp_bin2 = [num2str(bin(i+1)/1000) 'tonne'];
        elseif bin(i+1) >= 1
            temp_bin2 = [num2str(bin(i+1)) 'kg'];
        else
            temp_bin2 = [num2str(bin(i+1)*1000) 'g'];
        end
        
        zonename_short = [temp_bin1 '_to_' temp_bin2];
        zonename_plot = [temp_bin1 ' to ' temp_bin2];
        zonename = ['MassZone' char(64+i) '_' zonename_short '_' SimFilename SimVersionSfx];
        
        % save strewn area to variable        
        eval(['strewnarea_km2_' zonename_short ' = areaint(latitudes,longitudes,getPlanet(''ellipsoid_m'').MeanRadius/1000)']) 
        
        % change directory
        cd([exportfolder '\zoneplots'])
        
        % write zoneplot file
        kmlwritepolygon([zonename '.kml'],latitudes,longitudes,'Name',zonename,'FaceColor',color{i},'FaceAlpha',0.8)
        
        % return to main folder
        cd(getSession('folders','mainfolder'))
        
        % save legend name
        zoneplot_i = zoneplot_i + 1;
        zonenames{zoneplot_i} = zonename_plot;
        
    catch
        % return to main folder
        cd(getSession('folders','mainfolder'))
        i = i+1;
    end
end

% Create legend
switch ceil(bearing/90)
    case 0
        ornt = 'southwest';
    case 1
        ornt = 'southwest';
    case 2
        ornt = 'northwest';
    case 3
        ornt = 'northeast';
    case 4
        ornt = 'southeast';
    otherwise
        ornt = 'northwest';
end
if exist('zonenames','var')
    legend(zonenames,'Location',ornt)
end