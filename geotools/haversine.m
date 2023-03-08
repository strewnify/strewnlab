function [a,d,dlat,dlon]=haversine(radius, lat1,lon1,lat2,lon2)
%[anglerad distance dlat lon] = HAVERSINE(lat1,lon1,lat2,lon2)
%Calculate haversine angle and distance between two points on a sphere

    dlat = deg2rad(lat2-lat1);
    dlon = deg2rad(lon2-lon1);
    lat1 = deg2rad(lat1);
    lat2 = deg2rad(lat2);
    a = (sin(dlat./2)).^2 + cos(lat1) .* cos(lat2) .* (sin(dlon./2)).^2;
    d = 2 .* radius .* asin(sqrt(a));
end