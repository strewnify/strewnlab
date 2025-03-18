function terminal_velocity_mps = terminal_velocity(mass_kg, altitude_km, cubicity)
% TERMINAL_VELOCITY Computes the terminal velocity of a meteorite.
%
% Inputs:
%   mass_kg     - Mass of the projectile (kg)
%   altitude_km - Altitude above Earth's surface (km)
%
% Output:
%   terminal_velocity_mps - Terminal velocity (m/s)
%
% Assumptions:
% - Projectile is a sphere
% - No wind influence
% - Motion is strictly vertical (straight down)
% - Chondritic density of 3380 kg/m³
% - Initial Mach number assumption of 0.2 for iteration

    % Assumptions
    %obj_density_kg_m3 = 917;  % Ice
    obj_density_kg_m3 = 3380;  % Average meteorite density is 3380 kg/m^3
        
    if nargin < 3
        cubicity = 0.5;  % 0 for sphere, 1 for cube
        frontalareamult = 1;  % typically between 0.4 to 1.6
    else
        if cubicity > 0.5
            frontalareamult = 1 + ((cubicity - 0.5)/(1 - 0.5))*(1.6 - 1); % interpolate frontal area multiplier between 1 and 1.6
        else
            frontalareamult = 1;  % don't consider odd "needle" shapes
        end
    end
    
    % Calculate atmosphere
    altitude_m = altitude_km .* 1000;
    ground = 0;
    pbaro = 101325;
    TrefC = 20;
    [ ~, air_temperature_C, rho_kg_m3] = barometric( pbaro, TrefC, ground, altitude_m);
    
    % Calculate gravity
    planet = getPlanet();
    g = getConstant('G_constant') .* planet.mass_kg ./ (planet.ellipsoid_m.MeanRadius + altitude_m).^2;
    
    % Calculate radius of the sphere from mass and rock density
    radius_m = (3 .* mass_kg / (4 .* pi .* obj_density_kg_m3)).^(1/3);

    % Compute frontal area (cross-sectional area)
    frontal_area_m2 = pi .* radius_m.^2 .* frontalareamult;
    
    % Initialize mach number
    % Iterate below to solve
    machnum = 0.2;
    
    % Iterate mach number to solve terminal velocity
    for idx = 1:10
        % Drag coefficient for a sphere
        CD = dragcoef(machnum, cubicity);

        % Calculate terminal velocity
        terminal_velocity_mps = sqrt((2 * mass_kg * g) ./ (CD .* rho_kg_m3 .* frontal_area_m2));

        % Recalculate mach number
        speedsound = 20.05*sqrt(air_temperature_C + 273.15); % local speed of sound, air temp converted to Kelvin
        machnum = terminal_velocity_mps/speedsound;
    end
