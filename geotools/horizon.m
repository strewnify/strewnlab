function [dipangle,curvedist_km] = horizon(lat, long, altitude_km, AZ)
%[DIPANGLE, DISTANCE] = HORIZON(LAT, LONG, ALTITUDE) Calculate distance to
% the horizon and dip angle.  This function assumes the terrain is flat.

planet = getPlanet();

% degree step for dip angle
step_deg = 10;
start_angle = 90;
altitude_m = altitude_km .* 1000;

while step_deg > 0.000001
    for tilt = start_angle:-step_deg:0
        [h_lat,h_lon,slantrange] = lookAtSpheroid(lat,long,altitude_m,AZ,tilt,getPlanet('ellipsoid_m'));
        if ~isnan(slantrange)
            break
        end
    end
    start_angle = tilt + step_deg;
    step_deg = step_deg / 2;
end

curvedist_km = distance(lat,long,h_lat,h_lon,getPlanet('ellipsoid_m')) ./ 1000;
dipangle = 90-tilt;

end

