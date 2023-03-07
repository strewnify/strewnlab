function masszone(strewndata, filter)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

masszones = [0.001 0.01 0.1 1];
colors = ['wybr'];

persistent gx
if isempty(gx) || ~isgraphics(gx)
    gx = geoaxes('Basemap','satellite');
    hold on
end

for idx = 1:(numel(masszones)-1)
    mass_filt = filter & strewndata.mass > masszones(idx) & strewndata.mass < masszones(idx + 1);
    [vertices_lat, vertices_lon, ~] = polyarea(strewndata.Latitude(mass_filt),strewndata.Longitude(mass_filt));

    geoplot(vertices_lat,vertices_lon,colors(idx))
end

end

