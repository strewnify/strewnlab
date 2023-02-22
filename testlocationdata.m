lat = [35.0305 41.0847 42.9114 40.8 31.2809 31.2830 31.3868 31.2890 31.2841]
lon = [19.5659 27.4240 21.7017 -73.9 121.8074 121.4523 121.7142 121.0260 121.3131]

% collect data
for idx = 1:numel(lat)
    
    % loc_raw(idx) = {webread(['https://maps.googleapis.com/maps/api/geocode/json?latlng=' num2str(lat(idx)) ',' num2str(lon(idx)) '&key=' GoogleMapsAPIkey])};

    name = getlocation_test(lat(idx),lon(idx),elevation(idx), loc_raw{idx});
end
