function [vertices_lat, vertices_lon, area_km2] = polyarea(lat, lon)

planet = getPlanet();

% Create a polygon object
idx = boundary(lon, lat);

% Return the vertices and area
vertices_lat = lat(idx);
vertices_lon = lon(idx);

% Calculate the area of the polygon in square kilometers
area_km2 = areaint(lat(idx), lon(idx), planet.ellipsoid_m) / 1e6;


end

