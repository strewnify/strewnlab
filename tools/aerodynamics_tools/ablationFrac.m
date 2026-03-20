function [ablationFrac] = ablationFrac(entrySpeed_kps, material)
% ABLATIONFRAC Calculates the fraction of mass remaining after atmospheric ablation.
% This function estimates the maximum possible mass fraction of meteorites 
% produced by an observed fall based on single-body ablation theory (Öpik 1958). 
%
% Note: The actual strewn mass is often significantly lower due to factors 
% such as fragmentation, entry angle, and material structural integrity.
%
% The calculation uses the exponential mass loss equation:
% Remaining Fraction = 1 / (e ^ ((0.05 * (Velocity_m/s)^2) / AblationHeat))
%
% Inputs:
%   entrySpeed_kps - Entry velocity in kilometers per second (km/s)
%   material       - String matching a case in materialprops.m (e.g., 'h chondrite')
%
% Output:
%   ablationFrac   - The dimensionless fraction of initial mass remaining (0.0 to 1.0)

    % Retrieve the specific Heat of Ablation from the material library
    [~, ~, ~, AblationHeat, ~, ~, ~] = materialprops(material);

    % Convert entry speed from km/s to m/s for standard units
    velocity_mps = entrySpeed_kps * 1000;

    % Calculate the remaining mass fraction
    % This represents the ratio of final mass to initial entry mass (Mf / Mi).
    exponentTerm = (0.05 * (velocity_mps^2)) / AblationHeat;
    ablationFrac = 1 / exp(exponentTerm);

end