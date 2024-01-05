function [position_pct] = pctVertFOV(minELEV, maxELEV, testELEV)
% pctVertFOV Determine if an azimuth is visible to a camera and what position in the frame
% [position_pct] = pctVertFOV(minELEV, maxELEV, testELEV)  Calculate the position of
% the testELEV in the vertical FOV of the camera, from bottom to top.  If testELEV is on
% the bottom edge of the frame, position_pct will be reported as 0.  If 
% testELEV is on the top edge of the frame, position_pct will be reported as 100.

% check inputs for errors
if ~isempty(find(minELEV < -180,1)) || ~isempty(find(minELEV > 180,1)) ||...
    ~isempty(find(maxELEV < -180,1)) || ~isempty(find(maxELEV > 180,1)) ||...    
    ~isempty(find(testELEV < -180,1)) || ~isempty(find(testELEV > 180,1))
    error('Inputs must be between -180 and 180')
end

% Calculate angles
FOV = wrapTo360(maxELEV - minELEV);
bottom_delta = wrapTo360(testELEV - minELEV);
top_delta = wrapTo360(maxELEV - testELEV);

position_pct = bottom_delta./FOV;

filt = bottom_delta > FOV & bottom_delta > top_delta;
position_pct(filt) = -wrapTo360(minELEV(filt) - testELEV(filt))./FOV(filt);

position_pct = position_pct.*100;

% Default infinite values to NaN
position_pct(isinf(position_pct)) = NaN;
    
end

