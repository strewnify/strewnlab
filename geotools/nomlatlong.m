function [LAT,LONG] = nomlatlong(ref_Bearing_deg, ref_ZenithAngle_deg, ref_Lat, ref_Long, ref_Height_km)
% NOMLATLONG Extrapolates a nominal point from a trajectory, at a
% nominal height (40km).  This function is critical for database matching
% of multiple sources, which may or may not record the same points on a
% trajectory.  For earth grazers that don't reach the nominal height, minimum height is used. 
%
% [LAT,LONG] = aer2geosolve(Bearing_AZ_deg, ZenithAngle_deg, ref_Lat, ref_Long, ref_Height_km) 

% Logging option
logthis = true; % turn on/off logging for this file
if ~logthis && strcmp(get(0,'Diary'),'on')
       diary off     
       resetdiary = true;
else
    resetdiary = false;
end

% Load spheroid and nominal height
planet = getPlanet();  % reference ellipsoid
nom_height_m = 40000; % height for nominal LAT/LONG determination. DO NOT CHANGE, requires database rebuild

% Check array inputs
if ~(isvector(ref_Bearing_deg) &&...
        isvector(ref_ZenithAngle_deg) &&...
        isvector(ref_Lat) &&...
        isvector(ref_Long) &&...
        isvector(ref_Height_km) &&...
        isequal(length(ref_Bearing_deg), length(ref_ZenithAngle_deg), length(ref_Lat), length(ref_Long), length(ref_Height_km)))
    error('Inputs must be vectors of equal size')
end

numrecords = length(ref_Lat);

% Open a waitbar
handleNom = waitbar(0,'Extrapolating Nominal Points...');

% Preallocate out arrays
LAT = nan(size(ref_Lat));
LONG = nan(size(ref_Lat));

% Process each record
for record_i = 1:numrecords

    waitbar(record_i/numrecords,handleNom,['Extrapolating Nominal Points... Record ' num2str(record_i) ' of ' num2str(numrecords)]);
    
    slantRange_m = inf;
    default = false;

    % Error checking and logging
    if isnan(ref_Bearing_deg(record_i))
        wrnmsg = sprintf('Bearing is %0.1f', ref_Bearing_deg(record_i));
        default = true;
    elseif isnan(ref_ZenithAngle_deg(record_i))
        wrnmsg = sprintf('Zenith angle is %0.1f', ref_ZenithAngle_deg(record_i));
        default = true;
    elseif isnan(ref_Lat(record_i)) || isnan(ref_Long(record_i))
        wrnmsg = sprintf('Lat/Long is %0.3f/%0.3f', ref_Lat(record_i), ref_Long(record_i));
        default = true;
    elseif isnan(ref_Height_km(record_i))
        wrnmsg = sprintf('Height is %0.1f', ref_Height_km(record_i));
        default = true;

    % Generate nominal LAT and LONG
    else
        test_height_m = nom_height_m;

        error_count = 0;
        while error_count < 100
            try
                [LAT(record_i), LONG(record_i), slantRange_m] = aer2geosolve(ref_Bearing_deg(record_i),ref_ZenithAngle_deg(record_i) - 90,ref_Lat(record_i),ref_Long(record_i),ref_Height_km(record_i)*1000,test_height_m,planet.ellipsoid_m);
                break
            catch
                error_count = error_count + 1;

                if (ref_Height_km(record_i) * 1000) > test_height_m
                    test_height_m = test_height_m + 1000;
                else
                    error_count = 100;
                end            
            end
        end
    end

    % Check for extrapolation failure
    if ~default
        if slantRange_m == Inf
            wrnmsg = sprintf('Extrapolation failure', slantRange_m);
            default = true;
        elseif slantRange_m > 400000
            wrnmsg = sprintf('Solution is %0.0f km from reference point', slantRange_m/1000);
            default = true;
        elseif isnan(LAT(record_i)) || isnan(LONG(record_i))
            wrnmsg = sprintf('Solution lat/long is %0.3f/%0.3f', LAT(record_i), LONG(record_i));
            default = true;
        end
    end

    if default
        logformat([wrnmsg ', input coordinates used.'],'WARN')
        LAT(record_i) = ref_Lat(record_i);
        LONG(record_i) = ref_Long(record_i);
    end 
end

% close waitbar
close(handleNom)

if resetdiary
    diary on
end

