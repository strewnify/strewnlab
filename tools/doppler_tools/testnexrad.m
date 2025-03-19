opmodes = [{'VCP31'} {'VCP34'} {'VCP35'} {'VCP212'} {'VCP215'}]
opmodes = [{'VCP21'} {'VCP31'} {'VCP32'} {'VCP34'} {'VCP35'} {'VCP11'} {'VCP12'} {'VCP112'} {'VCP121'} {'VCP212'} {'VCP215'}]

planet = getPlanet();
earthRadius_km = planet.ellipsoid_m.MeanRadius / 1000;

maxDistance_km = 400;
maxProbability = 0.5;

% ELEV
ELEV_deg = 0.5;  % first elevation
ELEV_rad = deg2rad(ELEV_deg);

% Define range of distances (5 km to 1000 km)
slantRanges_km = linspace(1, 1000, 1000); % 100 points from 1 to 1000km
slantRanges_m = slantRanges_km .* 1000;
[LAT, LON, altitudes_m] = aer2geodetic(0, ELEV_deg, slantRanges_m, 42, -82, 0, planet.ellipsoid_m);
altitudes_km = altitudes_m ./ 1000;
[curve_distances_m, ~] = distance(42, -82, LAT, LON, planet.ellipsoid_m);
curve_distances_km = curve_distances_m ./ 1000;

% Compute slant range using the corrected formula
beamdiameter_m = 2 * slantRanges_m .* tan(deg2rad(getNEXRAD('beamwidth_deg')) / 2);

% Define meteorite masses (grams)
meteorite_masses_g = [1, 10, 100]; % Masses in grams
meteorite_masses_kg = meteorite_masses_g / 1000; % Convert to kg

% Assume spherical meteorites with density of 3300 kg/m³
density_kg_m3 = 3380; % Chondrite density

for modnum = 1:numel(opmodes)

    opmode = opmodes{modnum};
        
    % Calculate object diameters from mass: V = (4/3)*pi*(r^3), m = density*V
    object_radii_m = ((3 * meteorite_masses_kg) ./ (4 * pi * density_kg_m3)).^(1/3);
    object_diameters_m = 2 * object_radii_m;
    object_areas_m2 = pi * object_radii_m.^2; % Compute cross-sectional area
        
    % Initialize probability storage
    P_d_values = zeros(length(object_diameters_m), length(slantRanges_km));

    % Compute detection probabilities
    for i = 1:length(object_diameters_m)
        for j = 1:length(slantRanges_km)
            term_vel_mps(i, j) = terminal_velocity(meteorite_masses_kg(i), altitudes_km(j));
            residence_time_s(i, j) = beam_residence_time(slantRanges_km(j), 0, ELEV_deg, 0, 0, term_vel_mps(i, j));
            P_d_values(i, j) = P_NEXRAD_detect(object_areas_m2(i), slantRanges_km(j)) * P_NEXRAD_visible(slantRanges_km(j),0,ELEV_deg,0,0,term_vel_mps(i, j),opmode);
            %P_d_values(i, j) = 1 * P_NEXRAD_visible(distances_km(j),0,4,0,0,50,'VCP31');
        end
    end

    % Plot results
    figure;
    plot(curve_distances_km, P_d_values(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(curve_distances_km, P_d_values(2, :), 'g', 'LineWidth', 2);
    plot(curve_distances_km, P_d_values(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Distance (km)');
    ylabel('Probability of Detection');
    title(['NEXRAD Detection Probability' newline getNEXRAD('mode_type',opmode) ': ' opmode ]);
    axis([0 maxDistance_km 0 maxProbability]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left
end

    % Plot Beam Altitude
    figure;
    plot(curve_distances_km, altitudes_km, 'k', 'LineWidth', 2);
    
    grid on;
    xlabel('Ground Distance (km)');
    ylabel('Altitude, km');
    title(['Radar Beam Altitude' newline sprintf('Radar Elevation = %.1f%s', ELEV_deg, char(176)) ]);
    axis([0 maxDistance_km 0 20]);
    
    % Plot Beam Diameter
    figure;
    plot(curve_distances_km, beamdiameter_m, 'k', 'LineWidth', 2);
    
    grid on;
    xlabel('Ground Distance (km)');
    ylabel('Beam Width, meters');
    title(['Radar Beam Diameter' newline sprintf('Radar Beam Width = %.3f%s', getNEXRAD('beamwidth_deg'), char(176)) ]);
    axis([0 maxDistance_km 0 7000]);
    
    % Plot Termninal Velocity
    figure;
    plot(curve_distances_km, term_vel_mps(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(curve_distances_km, term_vel_mps(2, :), 'g', 'LineWidth', 2);
    plot(curve_distances_km, term_vel_mps(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Ground Distance (km)');
    ylabel('Terminal Velocity, m/s');
    title(['Meteorite Terminal Velocity' newline sprintf('Radar Elevation = %.1f%s', ELEV_deg, char(176)) ]);
    axis([0 maxDistance_km 0 125]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left
    
    % Plot Beam Residence
    figure;
    plot(curve_distances_km, residence_time_s(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(curve_distances_km, residence_time_s(2, :), 'g', 'LineWidth', 2);
    plot(curve_distances_km, residence_time_s(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Ground Distance (km)');
    ylabel('Residence Time, seconds');
    title(['Radar Beam Residence Time' newline sprintf('Radar Elevation = %.1f%s', ELEV_deg, char(176)) ]);
    axis([0 maxDistance_km 0 180]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left