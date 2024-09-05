function p = albedopdf()
%ALBEDOPDF  Near earth object albedo probability density function.
%   Y = albedopdf(X) returns the probability density function of near
%   earth object albedo, with parameter B at the values in X.
%
%   The size of Y is the common size of X and B. A scalar input   
%   functions as a constant matrix of the same size as the other input.    

%   Reference: Edward L. Wright et al 2016 AJ 152 79, THE ALBEDO DISTRIBUTION OF NEAR EARTH ASTEROIDS

fD = 0.253;
d = 0.03;
b = 0.168;
x = [0:0.001:1];

p = fD.*(x.*exp(-0.5.*x.^2./d^2)./d^2)+(1-fD).*(x.*exp(-0.5.*x.^2./b^2)./b^2);

figure;
plot(x,p)
