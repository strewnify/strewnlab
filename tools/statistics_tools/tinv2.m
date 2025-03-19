function [multiplier] = tinv2(confidence, samples)
%TINV2 Calculates the 2-sided multiplicative factor for standard deviation,
%given desired confidence inverval (0.95, 0.90, 0.80, etc) and number of samples.
% Example - standard deviation multiplier for 3 observations, with an 80%
% confidence interval: tinv2(0.80,3) = 1.8856
% Based on explanations found here:
% https://stats.stackexchange.com/questions/230171/is-it-meaningful-to-calculate-standard-deviation-of-two-numbers
% https://sites.science.oregonstate.edu/~gablek/CH361/ttest.htm

df = samples - 1;
confidence2 = (confidence + 1)./2;
multiplier  = tinv(confidence2,df);

