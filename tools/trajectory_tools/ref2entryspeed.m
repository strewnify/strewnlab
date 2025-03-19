function [entry_Speed_kps, err_entry_Speed_kps] = ref2entryspeed(ref_Speed_kps,err_ref_Speed_kps, ref_Height_km, speed_type)
%REF2ENTRYSPEED Estimates entry speed and error, based on reference point speed, height, and speed error.
% [entry_Speed_kps, err_entry_Speed_kps] = ref2entryspeed(ref_Speed_kps,err_ref_Speed_kps, ref_Height_km, speed_type)
% The model is based on a simulated dataset, and assumes entry height is
% 100km.  Variation in speed is less than 2% between 60 km
% speed_type is either 'average' or 'instant'

% Extreme limits of meteor speed
min_extreme_kps = 9;
max_extreme_kps = 70;

% Model data
height_km = [-999 3 10 12 15 20 25 30 35 40 50 60 70 80 999];

if nargin == 3
    speed_type = 'average';
end

% Choose model data
switch speed_type
    case 'average'
        minmult = [1.0729 1.0729 1.0177 1.0128 1.0079 1.0001 0.9964 0.995 0.9912 0.9893 0.9895 0.9913 0.9934 1 1];
        maxmult = [119.8 119.8 55.75 43.71 26.89 8.206 3.2338 1.3619 1.0778 1.0279 1.0032 1 1 1 1]; 
    case 'instant'
        minmult = [2.164 2.164 1.2696 1.1877 1.1169 1.0523 1.020 1.0063 1.001 0.9989 0.9974 0.9973 0.9976 1 1];
        maxmult = [1339 1339 653.3 562.5 446.6 344.0 146.4 14.159 2.480 1.435 1.075 1.0015 1.0001 1 1]; 
    otherwise
        error('Unknown speed type')
end

% Lookup model multipliers
minlookup = griddedInterpolant(height_km, minmult);
maxlookup = griddedInterpolant(height_km, maxmult);

% Calculate min and max entry speed
min_entry = (ref_Speed_kps - err_ref_Speed_kps) .* minlookup(ref_Height_km);
max_entry = (ref_Speed_kps + err_ref_Speed_kps) .* maxlookup(ref_Height_km);

% Clip extreme values
min_entry(min_entry < min_extreme_kps) = min_extreme_kps;
max_entry(max_entry > max_extreme_kps) = max_extreme_kps;

entry_Speed_kps = mean(cat(3,min_entry,max_entry),3); % average min and max element-wise
err_entry_Speed_kps = entry_Speed_kps - min_entry;

