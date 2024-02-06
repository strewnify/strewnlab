function [Bearing_AZ_deg,ZenithAngle_deg, PathLength_km, err_AZ, err_ZenithAngle, err_PathLength_km] = trajectoryerror(startLAT, startLON, startH_m, endLAT, endLON, endH_m,startLAT_ERR, startLON_ERR, startH_ERR, endLAT_ERR, endLON_ERR, endH_ERR, samplesize)
% TRAJECTORYERROR Calculates angle uncertainty from 3D space error bars
%
%[Bearing_AZ_deg,ZenithAngle_deg, PathLength_km, err_AZ, err_ZenithAngle, err_PathLength_km] = trajectoryerror(startLAT, startLON, startH, endLAT, endLON, endH,startLAT_ERR, startLON_ERR, startH_ERR, endLAT_ERR, endLON_ERR, endH_ERR)

planet = getPlanet();

if nargin < 13
    samplesize = 100000;
end

% Check array inputs
if ~(isvector(startLAT) &&...
        isvector(startLON) &&...
        isvector(startH_m) &&...
        isvector(endLAT) &&...
        isvector(endLON) &&...
        isvector(endH_m) &&...
        isvector(startLAT_ERR) &&...
        isvector(startLON_ERR) &&...
        isvector(startH_ERR) &&...
        isvector(endLAT_ERR) &&...
        isvector(endLON_ERR) &&...
        isvector(endH_ERR) &&...
        isequal(length(startLAT), length(startLON), length(startH_m), length(endLAT), length(endLON), length(endH_m), length(startLAT_ERR), length(startLON_ERR), length(startH_ERR), length(endLAT_ERR), length(endLON_ERR), length(endH_ERR)))
    
    error('Inputs must be vectors of equal size')
end

% Open a waitbar
handleTraj = waitbar(0,'Calculating trajectory error...');

% preallocate arrays
numrecords = length(startLAT);
err_AZ = nan(size(startLAT));
err_ZenithAngle = nan(size(startLAT));


% Calculate nominal angles
[AZ_raw,ELEV_nom,slantrange_nom_m] = geodetic2aer(startLAT, startLON, startH_m, endLAT, endLON, endH_m,getPlanet('ellipsoid_m'));
PathLength_km = slantrange_nom_m ./ 1000;
ZenithAngle_deg = 90 - ELEV_nom;

% Adjust for direction
Bearing_AZ_deg = wrapTo360(AZ_raw + 180);

% Array support
for record_i = 1:numrecords
    % Update waitbar
    waitbar(record_i/numrecords,handleTraj,['Calculating Trajectory Error... Record ' num2str(record_i) ' of ' num2str(numrecords)]);
        
    % random error samples
    % random number generator is initialized with the same seed each time to allow repeatable results
    rng(50,'twister')
    lat_err = randbetween(-startLAT_ERR(record_i),startLAT_ERR(record_i),samplesize);
    rng(51,'twister')
    lon_err = randbetween(-startLON_ERR(record_i),startLON_ERR(record_i),samplesize);
    rng(52,'twister')
    h_err = randbetween(-startH_ERR(record_i),startH_ERR(record_i),samplesize);
    rng(53,'twister')
    lat_err0 = randbetween(-endLAT_ERR(record_i),endLAT_ERR(record_i),samplesize);
    rng(54,'twister')
    lon_err0 = randbetween(-endLON_ERR(record_i),endLON_ERR(record_i),samplesize);
    rng(55,'twister')
    h_err0 = randbetween(-endH_ERR(record_i),endH_ERR(record_i),samplesize);
    
    [AZ,ELEV,slantrange_m] = geodetic2aer(startLAT(record_i) + lat_err, startLON(record_i) + lon_err, startH_m(record_i) + h_err, endLAT(record_i) + lat_err0, endLON(record_i) + lon_err0, endH_m(record_i) + h_err0,getPlanet('ellipsoid_m'));
    
    % error values are one standard deviation, rounded to 3 significant digits
    % rounding is necessary to prevent unnecessary import, due to random differences
    err_AZ(record_i) = round(std(AZ),3,'significant');
    err_ZenithAngle(record_i) = round(std(ELEV),3,'significant');
    err_PathLength_km(record_i) = round(std(slantrange_m) ./ 1000,3,'significant');
    
end

% close waitbar
close(handleTraj)

