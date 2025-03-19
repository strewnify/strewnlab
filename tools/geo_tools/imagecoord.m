function [lats, lons] = imagecoord(NW_lat, NW_lon, NE_lat, NE_lon, SW_lat, SW_lon, SE_lat, SE_lon)
%IMAGECOORD Geolocates points on a map image

% Import the contact file
[FILENAME, PATHNAME, FILTERINDEX] = uigetfile({'*.jpg;*.tif;*.png;*.gif;*.png;'});
if FILTERINDEX == 0
    error('No file selected for import.')
end

% Display a file
I = imread([PATHNAME,FILENAME]);
imshow(I);

% Get image size
[y_max, x_max, ~] = size(I);

% Get points from user
title('Choose points from map image')
[X,Y] = ginput()
Y = y_max - Y; % flip Y axis

% Calculate the transformation matrix from image to map coordinates
image_corners = [0 0; 0 y_max; x_max y_max; x_max 0];
map_corners = [SW_lon,SW_lat; NW_lon,NW_lat; NE_lon,NE_lat; SE_lon,SE_lat];

% Transform the point from image to map coordinates
% This method is substituted for the exact method using projective
% transforms, that requires the image processing toolbox...
lon1 = interp1([0 x_max],[SW_lon SE_lon],X);
lon2 = interp1([0 x_max],[NW_lon NE_lon],X);
lat1 = interp1([0 y_max],[SW_lat NW_lat],Y);
lat2 = interp1([0 y_max],[SE_lat NE_lat],Y);

% Extract the x and y coordinates from the transformed point
lons = lon1 + (Y - 0).*((lon2 - lon1)./(y_max - 0));
lats = lat1 + (X - 0).*((lat2 - lat1)./(x_max - 0));

geoscatter(lats,lons)

% Transpose for polygon feature use
lats = lats';
lons = lons';

end

