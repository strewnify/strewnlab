function [position_pct] = pctFOV(minAZ, maxAZ, testAZ)
% pctFOV Determine if an azimuth is visible to a camera and what position in the frame
% [position_pct] = pctFOV(minAZ, maxAZ, testAZ)  Calculate the position of
% the testAZ in the FOV of the camera, from left to right.  If testAZ is on
% the left edge of the frame, position_pct will be reported as 0.  If 
% testAZ is on the right edge of the frame, position_pct will be reported as 100.

% check inputs for errors
if ~isempty(find(minAZ < 0,1)) || ~isempty(find(minAZ > 360,1)) ||...
    ~isempty(find(maxAZ < 0,1)) || ~isempty(find(maxAZ > 360,1)) ||...    
    ~isempty(find(testAZ < 0,1)) || ~isempty(find(testAZ > 360,1))
    error('Inputs must be between 0 and 360')
end

% convert 360 to 0
minAZ(minAZ == 360) = 0;
maxAZ(maxAZ == 360) = 0;
testAZ(testAZ == 360) = 0;

% Calculate angles
FOV = wrapTo360(maxAZ - minAZ);
left_delta = wrapTo360(testAZ - minAZ);
right_delta = wrapTo360(maxAZ - testAZ);

position_pct = left_delta./FOV;

filt = left_delta > FOV & left_delta > right_delta;
position_pct(filt) = -wrapTo360(minAZ(filt) - testAZ(filt))./FOV(filt);

position_pct = position_pct.*100;

% Default infinite values to NaN
position_pct(isinf(position_pct)) = NaN;
    
end

