function [dipangle,curvedist] = horizon(lat, long, altitude, AZ,planet)
%[DIPANGLE, DISTANCE] = HORIZON(LAT, LONG, ALTITUDE) Calculate distance to
%the horizon and dip angle.  This function assumes the terrain is flat.

% degree step for dip angle
step_deg = 10;
start_angle = 90;

while step_deg > 0.000001
    for tilt = start_angle:-step_deg:0
        [h_lat,h_lon,slantrange] = lookAtSpheroid(lat,long,altitude,AZ,tilt,planet);
        if ~isnan(slantrange)
            break
        end
    end
    start_angle = tilt + step_deg;
    step_deg = step_deg / 2;
end

curvedist = distance(lat,long,h_lat,h_lon,planet);
dipangle = 90-tilt;

end

