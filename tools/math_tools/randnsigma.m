function [ random ] = randnsigma( mean, stdev, sigma_thresh, minvalue, maxvalue )
%RANDNSIGMA(MEAN, STDEV, SIGMA_THRESH, MINVALUE, MAXVALUE)    Generate random number, with a normal
%distribution centered between min and max.  Standard deviation will be 
%clipped, such that min and max values will be clipped between sigma limits (3 sigma is 0.3% probability).  

switch nargin
    case 2
        sigma_thresh = 3;
        minvalue = -inf;
        maxvalue = inf;
    case 3
        minvalue = -inf;
        maxvalue = inf;
    case 5
        % Do nothing
    otherwise
        error('Invalid number of arguments.');        
end

randomraw = inf;
while randomraw < (mean - sigma_thresh * stdev) || randomraw > (mean + sigma_thresh * stdev) ||...
        randomraw < minvalue || randomraw > maxvalue
    randomraw = mean + randn(1,1) .* stdev;
end

random = randomraw;

end

