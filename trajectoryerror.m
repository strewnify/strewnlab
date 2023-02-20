function [AZ_nom,ELEV_nom,AZ_ERR, ELEV_ERR, slantrange_nom] = trajectoryerror(startLAT, startLON, startH, endLAT, endLON, endH,startLAT_ERR, startLON_ERR, startH_ERR, endLAT_ERR, endLON_ERR, endH_ERR)
% [AZ_nom,ELEV_nom,AZ_ERR, ELEV_ERR, slantrange_nom] = TRAJECTORYERROR(startLAT, startLON, startH, endLAT, endLON, endH,LAT_ERR, LON_ERR, H_ERR,  endLAT_ERR, endLON_ERR, endH_ERR)
% TRAJECTORYERROR Calculates angle uncertainty from 3D space error bars

strewnconfig
sigma = 4;
samplesize = 100000;

[AZ_raw,ELEV_nom,slantrange_nom] = geodetic2aer(startLAT, startLON, startH, endLAT, endLON, endH, planet);

% Adjust for direction
AZ_nom = wrapTo360(AZ_raw + 180);

% random error samples
for idx = 1:samplesize
    lat_err = randbetween(-startLAT_ERR,startLAT_ERR);
    lon_err = randbetween(-startLON_ERR,startLON_ERR);
    h_err = randbetween(-startH_ERR,startH_ERR);
    lat_err0 = randbetween(-endLAT_ERR,endLAT_ERR);
    lon_err0 = randbetween(-endLON_ERR,endLON_ERR);
    h_err0 = randbetween(-endH_ERR,endH_ERR);
    [AZ(idx),ELEV(idx),slantrange(idx)] = geodetic2aer(startLAT + lat_err, startLON + lon_err, startH + h_err, endLAT + lat_err0, endLON + lon_err0, endH + h_err0,planet);
end

AZ_ERR = sigma * std(AZ);
ELEV_ERR = sigma * std(ELEV);

end

