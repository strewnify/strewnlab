function p = albedopdf(albedo)
%ALBEDOPDF  Near earth object albedo probability density function.
%   Y = albedopdf(X) returns the probability density function of near
%   earth object albedo, with parameter B at the values in X.
%
%   The size of Y is the common size of X and B. A scalar input   
%   functions as a constant matrix of the same size as the other input.    

% Reference: Edward L. Wright et al 2016 AJ 152 79, THE ALBEDO DISTRIBUTION OF NEAR EARTH ASTEROIDS
% https://iopscience.iop.org/article/10.3847/0004-6256/152/4/79

fD = 0.253;
d = 0.03;
b = 0.168;

p = fD.*(albedo.*exp(-0.5.*albedo.^2./d^2)./d^2)+(1-fD).*(albedo.*exp(-0.5.*albedo.^2./b^2)./b^2);

figure;
plot(albedo,p)
