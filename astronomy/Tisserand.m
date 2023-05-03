function [T_j] = Tisserand(semimajor_AU,eccentricity,incl_deg)
%TISSERAND Calculate Tisserand's parameter, with respect to Jupiter

semimajor_Jupiter_AU = 5.20336301

T_j =  semimajor_Jupiter_AU./semimajor_AU + 2.*cosd(incl_deg).*sqrt((semimajor_AU./semimajor_Jupiter_AU).*(1-eccentricity.^2));



