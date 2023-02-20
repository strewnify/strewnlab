% GETSAT  get satellite imagery for a location

latlim = [MINLAT MAXLAT]; 
lonlim = [MINLONG MAXLONG];

% Find the USGS high-resolution orthoimagery layer by reading the 
% capabilities document from the server. The server may be busy, so try to
% connect multiple times.
numberOfAttempts = 5;
attempt = 0;
info = [];
serverURL = 'http://basemap.nationalmap.gov/ArcGIS/services/USGSImageryOnly/MapServer/WMSServer?';
while(isempty(info))
    try
        info = wmsinfo(serverURL);
        orthoLayer = info.Layer(1);
    catch e 
        
        attempt = attempt + 1;
        if attempt > numberOfAttempts
            throw(e);
        else
            fprintf('Attempting to connect to server:\n"%s"\n', serverURL)
        end        
    end
end

% Retrieve the map from the server and display it in a UTM projection.
imageLength = 1024;
[A,R] = wmsread(orthoLayer,'Latlim',latlim, ...
                           'Lonlim',lonlim, ...
                           'ImageHeight',imageLength, ...
                           'ImageWidth',imageLength);


axesm('utm', ...
      'Zone',utmzone(latlim, lonlim), ...
      'MapLatlimit', latlim, ...
      'MapLonlimit', lonlim, ...
      'Geoid', wgs84Ellipsoid)
geoshow(A,R)
axis off
title({'San Francisco','Northern Section of Golden Gate Bridge'})
