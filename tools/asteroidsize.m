function [diameter_m] = asteroidsize(abs_magnitude,albedo)
%ASTEROIDSUZE Estimate asteroid diameter from observed magnitude and albedo
% [diameter_m] = asteroidsize(abs_magnitude, albedo)
%
% The expression for diameter d in meters as a function of absolute 
% magnitude H and geometric albedo a is given by the following equation.
% d = 10^[ 6.1236 - 0.5 log10(a) - 0.2H ]
% The expression assumes a spherical object with a uniform surface 
% (no albedo variation). When using this expression to estimate the size of
% an object, it is important to consider the uncertainty in H (typically 
% 0.5 mag.) as well as the uncertainty in albedo (typically assumed based 
% on some spectral class corresponding to an assumed composition of the 
% object - e.g., S-class asteroid with an assumed albedo of 0.15).
% As is evident in the table above, an error in the assumed albedo can 
% result in a significantly erroneous diameter. For example, let’s say you
% assumed an albedo of 0.15 for H=22 but the actual albedo was much closer
% to 0.05, your estimated diameter would be too small by a factor of 
% almost 2 (~1.7).
%
% Absolute magnitude is the visual magnitude an observer would record if 
% the asteroid were placed 1 Astronomical Unit (au) away, and 1 au from the
% Sun and at a zero phase angle.
%
% Albedo is ratio of the light received by a body to the light reflected by
% that body. Albedo values range from 0 (pitch black) to 1 (perfect reflector).
% The albedo range of asteroids is from about 0.02 to more than 0.5. 
% Asteroids are classified into groups based on their albedo:
% Low: 0.02–0.07
% Intermediate: 0.08–0.12
% Moderate: 0.13–0.28
% High: Greater than 0.28 
%  
% Asteroids are also classified by their spectra, which are related to 
% their chemical composition. Some of the main types of asteroids include: 
% C-type - Very dark, albedo of 0.03 – 0.09. They make up over 75% of known
%          asteroids and are located in the outer regions of the main belt. 
% S-type - Bright, albedo of 0.10 – 0.22. They make up about 17% of known 
%          asteroids and are located in the inner asteroid belt. 
% M-type - Bright, albedo of less than 0.18. Pure nickel-iron. 
% V-type - Bright, albedo of 0.20 – 0.5.  An asteroid whose spectral type is
%          that of 4 Vesta. Roughly 6% of main-belt asteroids are vestoids.
 
% References
% https://cneos.jpl.nasa.gov/tools/ast_size_est.htm
% E. Bowell et al. (1989) in “Asteroids II”, pp. 524-556.
% A. Harris and A. Harris (1997) Icarus 126:450-454.
%
% See also .

% Ensure albedo values are in valid range
if any(albedo < 0 | albedo > 1)
    error('Albedo values range from 0 (pitch black) to 1 (perfect reflector)');
end

% Ensure abs_magnitude values are in typical range
if any(abs_magnitude > 50 | abs_magnitude < 0)
    warning('Typical values for absolute magnitude are 18 to 35');
end

% Calculate the diameter in meters, allowing for array inputs
diameter_m = 10.^(6.123525 - 0.5.*log10(albedo) - 0.2.*abs_magnitude);

end


