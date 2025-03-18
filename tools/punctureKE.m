function KE_J = PunctureKE(shield_material)
% PunctureKE Estimates kinetic energy required for penetration based on KE = k*x.
%   KE_J = PunctureKE(shield_material) calculates the kinetic energy (Joules)
%   required to penetrate a shield material based on the linear model KE = k*x.
%   Material thicknesses are hardcoded within the function.
%
%   Inputs:
%       shield_material - String specifying the material ('18 gauge steel',
%                         'roof decking', 'tempered glass').
%
%   Outputs:
%       KE_J - Estimated kinetic energy in Joules.

shield_material = lower(shield_material); % Case-insensitive comparison

switch shield_material
    case '18ga steel'
        k_MPa = 1000; % MPa (Measured constant)
        gauge = 18;
        shield_thickness_cm = gauge_to_cm(gauge);

    case 'roof'
        k_MPa = 60; % MPa (Measured constant)
        shield_thickness_in = 0.5; % 1/2 inch
        shield_thickness_cm = shield_thickness_in * 2.54;

    case 'tempered glass'
        k_MPa = 50; % MPa (Measured constant)
        shield_thickness_cm = 0.5; % 0.5 cm

    otherwise
        KE_J = NaN;
        disp('Material not recognized. Please use ''18 gauge steel'', ''roof decking'', or ''tempered glass''.');
        return;
end

% Calculate kinetic energy
KE_J = k_MPa * shield_thickness_cm;

end

function thickness_cm = gauge_to_cm(gauge)
    % gauge_to_cm Converts gauge to thickness in centimeters.
    %   thickness_cm = gauge_to_cm(gauge) converts the input gauge to
    %   thickness in centimeters.

    % Standard steel gauge conversion (approximate):
    thickness_in = 0.0598; % 18 gauge in inches.
    thickness_cm = thickness_in * 2.54; % Convert inches to centimeters

    %You can add more gauge conversions here.
end