function geoplot_sensor(LAT0,LON0,RADIUS,AZ,PLANET,label,color)
%GEOPLOT_SENSOR(LAT,LON,RADIUS,AZ,PLANET) Plot filled circles or arcs on a map
%RADIUS = radius of the circle or arc, in units defined by the ellipsoid PLANET
%AZ = azimuth array.  For circles, use [].  For arcs, use [MIN_AZ MAX_AZ]
%PLANET = an ellipsoid defined by the referenceEllipsoid function

% Calculate a circle or arc
[LATs,LONs] = scircle1(LAT0,LON0,RADIUS,AZ,PLANET);
LONs
LONs = unwrapLON(LONs)

% Additional points for arcs, to create a filled polygon
if ~isempty(AZ)
    
    % Center point
    LATs(end+1) = LAT0;
    LONs(end+1) = LON0;
    
    % Complete the arc
    LATs(end+1) = LATs(1);
    LONs(end+1) = LONs(1);
end

% Plot the figure
geoplot(LATs,LONs,color);

% Display text label
text(mean([min(LATs) max(LATs)]),mean([min(LONs) max(LONs)]),label,'Color',color,'HorizontalAlignment','center')

end

