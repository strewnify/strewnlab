function [LAT,LONG] = nomlatlong(ref_Bearing_deg, ref_ZenithAngle_deg, ref_Lat, ref_Long, ref_Height_km)
%[LAT,LONG] = aer2geosolve(BEARING, ZENITH_ANGLE_DEG,REF_LAT,REF_LONG,REF_ALT_KM) Extrapolate meteor trajectory to nominal height (40km) or min height

% Logging option
logthis = false; % turn on/off logging for this file
if ~logthis && strcmp(get(0,'Diary'),'on')
       diary off     
       resetdiary = true;
else
    resetdiary = false;
end

LAT = NaN;
LONG = NaN;
slantRange_m = inf;
default = false;

% Error checking and logging
if isnan(ref_Bearing_deg)
    wrnmsg = sprintf('Bearing is %0.1f', ref_Bearing_deg);
    default = true;
elseif isnan(ref_ZenithAngle_deg)
    wrnmsg = sprintf('Zenith angle is %0.1f', ref_ZenithAngle_deg);
    default = true;
elseif isnan(ref_Lat) || isnan(ref_Long)
    wrnmsg = sprintf('Lat/Long is %0.3f/%0.3f', ref_Lat, ref_Long);
    default = true;
elseif isnan(ref_Height_km)
    wrnmsg = sprintf('Height is %0.1f', ref_Height_km);
    default = true;

% Generate nominal LAT and LONG
else
    % Load spheroid and nominal height
    planet = referenceEllipsoid('earth','meters');  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
    nom_height_m = 40000; % height for nominal LAT/LONG determination. DO NOT CHANGE, requires database rebuild
    test_height_m = nom_height_m;

    error_count = 0;
    while error_count < 100
        try
            [LAT, LONG, slantRange_m] = aer2geosolve(ref_Bearing_deg,ref_ZenithAngle_deg - 90,ref_Lat,ref_Long,ref_Height_km*1000,test_height_m, planet);
            break
        catch
            error_count = error_count + 1;

            if (ref_Height_km * 1000) > test_height_m
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
    elseif isnan(LAT) || isnan(LONG)
        wrnmsg = sprintf('Solution lat/long is %0.3f/%0.3f', LAT, LONG);
        default = true;
    end
end

if default
    logformat([wrnmsg ', input coordinates used.'],'WARN')
    LAT = ref_Lat;
    LONG = ref_Long;
end 

if resetdiary
    diary on
end

end

