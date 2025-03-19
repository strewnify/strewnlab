function [LAT,LONG,slantRange] = aer2geosolve(AZ, ELEV, LAT0, LONG0, H0, H_target, SPHEROID)
% [LAT,LONG,slantRange] = aer2geosolve(Bearing, ELEV, LAT0, LONG0, H0, H_target, SPHEROID)
% transforms point locations in 3-D from local spherical coordinates to geodetic
% coordinates, solving for height at the endpoint.  The geodetic coordinates refer
% to the reference body specified by the spheroid object, SPHEROID. The ellipsoidal
% height H0 must be expressed in the same length unit as the spheroid.  
% Ellipsoidal height H will be expressed in this unit, also.  The input azimuth and
% elevation angles, are in degrees.

if (numel(AZ) > 1) || (numel(ELEV) > 1) || (numel(LAT0) > 1) || (numel(LONG0) > 1) || (numel(H0) > 1) || (numel(H_target) > 1)
    error('Array inputs not accepted.')
end

% Is this check needed?
if (ELEV > 90) || (ELEV < -90)
    error('Invalid slope.')
end

if (ELEV == 0) && (H_target < H0)
    error('No solution on current slope.')
end

% Set solver accuracy, in meters
err_stop_m = 1; % 1 meter accuracy

% Automatically calculate slope error in input units
err_stop = err_stop_m * unitsratio(SPHEROID.LengthUnit,'meters');

% Calculate initial error
err = abs(H_target-H0);

% Check direction to closest solution
if err < err_stop
    logformat('No iteration required, inputs meet solution criteria.')
    LAT = LAT0;
    LONG = LONG0;
    slantRange = 0;
    return
    
elseif ((H_target > H0) && (ELEV < 0)) || ((H_target < H0) && (ELEV > 0))
    AZ = wrapTo360(AZ + 180);
    ELEV = -ELEV;
    flipped_direction = true;
else
    flipped_direction = false;
end

% Init solver
LAT_solve = LAT0;
LONG_solve = LONG0;
err = (H_target-H0);
slantRange_solve = err;
abs_err = abs(err);
first = true;

% Convergence Rate
converge = min(0.9,abs(ELEV)/20);
n = 0;
% figure
% hold on

% Iterate toward the solution
while abs_err > err_stop
    
    % Calculate a position
    [LAT_solve, LONG_solve, H_solve] = aer2geodetic(AZ, ELEV, slantRange_solve, LAT0, LONG0, H0, SPHEROID);
    
    % Calculate new error
    err = H_target - H_solve;
    abs_err = abs(err);
    
%     % plot
%     n = n +1;
%     plot(n,err,'k.');
    
    % Rate of change
    new_slant = slantRange_solve + slantest(err, ELEV);
    
    % Calculate new slant range
    slantRange_solve = slantRange_solve + converge * (new_slant - slantRange_solve);    
    slantRange_solve_prev = slantRange_solve;
    H_solve_prev = H_solve;
    
end

LAT = LAT_solve;
LONG = LONG_solve;
if flipped_direction
    slantRange = -slantRange_solve;
else
    slantRange = slantRange_solve;
end

if isnan(LAT) || isnan(LONG) || isnan(slantRange)
    error('No solution, trajectory may not reach expected height')
end

    function [s_est] = slantest(h_in,elev_in)
        
        min_angle = 0.01;
        
        if abs(elev_in) < min_angle
            error('Not yet supported by solver.')
        else
            s_est = h_in/sin(deg2rad(elev_in));
        end
    end

end
