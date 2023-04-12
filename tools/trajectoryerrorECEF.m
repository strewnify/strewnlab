function [Bearing_AZ_deg,ZenithAngle_deg, Speed_kps, err_AZ, err_ZenithAngle, err_Speed] = trajectoryerrorECEF(LAT, LONG, vx_ECEF_kps,vy_ECEF_kps,vz_ECEF_kps,vx_err_pct, vy_err_pct, vz_err_pct, samplesize)
% TRAJECTORYERROR Calculates angle uncertainty from 3D space error bars
%
%[Bearing_AZ_deg,ZenithAngle_deg, Speed_kps, err_AZ, err_ZenithAngle, err_Speed] = trajectoryerrorECEF(LAT, LONG, vx_ECEF_kps,vy_ECEF_kps,vz_ECEF_kps,vx_err_pct, vy_err_pct, vz_err_pct, samplesize)

planet = getPlanet();

if nargin < 9
    samplesize = 100000;
end

% Check array inputs
if ~(isvector(LAT) &&...
        isvector(LONG) &&...
        isvector(vx_ECEF_kps) &&...
        isvector(vy_ECEF_kps) &&...
        isvector(vz_ECEF_kps) &&...
        isequal(length(LAT), length(LONG), length(vx_ECEF_kps),length(vy_ECEF_kps),length(vz_ECEF_kps)) &&...
        isequal(length(vx_err_pct), length(vy_err_pct), length(vz_err_pct)))
    
    error('Inputs must be vectors of equal size')
end

% Check error inputs
if length(vx_err_pct) > 1 && ~isequal(length(LAT),length(vx_err_pct))
    error('Error vectors must be equal in length to other inputs')
end

% Create error vectors for scalar inputs
if length(LAT) > 1 && length(vx_err_pct) == 1
    vx_err_pct = repmat(vx_err_pct,size(LAT));    
    vy_err_pct = repmat(vy_err_pct,size(LAT));
    vz_err_pct = repmat(vz_err_pct,size(LAT));
end

% Open a waitbar
handleTraj = waitbar(0,'Calculating trajectory error...');

% preallocate arrays
numrecords = length(LAT);
err_AZ = nan(size(LAT));
err_ZenithAngle = nan(size(LAT));


% Calculate nominal angles
[vNorth_kps,vEast_kps,vDown_kps] = ecef2nedv(vx_ECEF_kps,vy_ECEF_kps,vz_ECEF_kps,LAT,LONG);
Bearing_AZ_deg = wrapTo360(90 - atan2d(vNorth_kps,vEast_kps)); % bearing angle (heading azimuth)
ZenithAngle_deg = atand(sqrt((vNorth_kps).^2+(vEast_kps).^2)./vDown_kps);  % incidence angle from vertical

% Calculate speed as the norm of the velocity vectors
if size(vx_ECEF_kps,2) == 1 % column vectors
    Speed_kps = vecnorm([vx_ECEF_kps vy_ECEF_kps vz_ECEF_kps],2,2);
else % row vectors
    Speed_kps = vecnorm([vx_ECEF_kps; vy_ECEF_kps; vz_ECEF_kps],2,1);
end

% Array support
for record_i = 1:numrecords
    % Update waitbar
    waitbar(record_i/numrecords,handleTraj,['Calculating Trajectory Error... Record ' num2str(record_i) ' of ' num2str(numrecords)]);
        
    % random error samples
    % random number generator is initialized with the same seed each time to allow repeatable results
    rng(50,'twister')
    vx_err = vx_ECEF_kps(record_i) .* randbetween(-vx_err_pct(record_i)/100,vx_err_pct(record_i)/100,samplesize);
    rng(51,'twister')
    vy_err = vx_ECEF_kps(record_i) .* randbetween(-vy_err_pct(record_i)/100,vy_err_pct(record_i)/100,samplesize);
    rng(52,'twister')
    vz_err = vx_ECEF_kps(record_i) .* randbetween(-vz_err_pct(record_i)/100,vz_err_pct(record_i)/100,samplesize);
        
    [vNorth_kps,vEast_kps,vDown_kps] = ecef2nedv(vx_ECEF_kps(record_i) + vx_err, vy_ECEF_kps(record_i) + vy_err, vz_ECEF_kps(record_i) + vz_err, LAT(record_i),LONG(record_i));
    AZ_data = wrapTo360(90 - atan2d(vNorth_kps,vEast_kps)); % bearing angle (heading azimuth)
    ZenithAngle_data = atand(sqrt((vNorth_kps).^2+(vEast_kps).^2)./vDown_kps);  % incidence angle from vertical
    
    % Calculate speed as the norm of the velocity vectors
    if size(vx_ECEF_kps,2) == 1 % column vectors
        Speed_data = vecnorm([(vx_ECEF_kps + vx_err) (vy_ECEF_kps + vy_err) (vz_ECEF_kps + vz_err)],2,2);
    else % row vectors
        Speed_data = vecnorm([(vx_ECEF_kps + vx_err); (vy_ECEF_kps + vy_err); (vz_ECEF_kps + vz_err)],2,1);
    end

    % error values are one standard deviation, rounded to 3 significant digits
    % rounding is necessary to prevent unnecessary import, due to random differences
    err_AZ(record_i) = round(std(AZ_data),3,'significant');
    err_ZenithAngle(record_i) = round(std(ZenithAngle_data),3,'significant');
    err_Speed(record_i) = round(std(Speed_data),3,'significant');
end

% close waitbar
close(handleTraj)

