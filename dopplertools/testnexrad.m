opmodes = [{'VCP31'} {'VCP34'} {'VCP35'} {'VCP212'} {'VCP215'}]

% Define range of distances (5 km to 1000 km)
distances_km = linspace(5, 500, 200); % 100 points from 5 km to 500 km

% Define meteorite masses (grams)
meteorite_masses_g = [1, 10, 100]; % Masses in grams
meteorite_masses_kg = meteorite_masses_g / 1000; % Convert to kg

% Assume spherical meteorites with density of 3300 kg/m³
density_kg_m3 = 3380; % Chondrite density

for modnum = 1:numel(opmodes)

    opmode = opmodes{modnum};
    
    % ELEV
    ELEV_deg = 0.5;  % first elevation
    ELEV_rad = deg2rad(ELEV_deg);

    % Compute altitude using spherical Earth model
    altitudes_km = sqrt(6371^2 + distances_km.^2 + 2 * 6371 .* distances_km .* sin(ELEV_rad)) - 6371;
    
    % Calculate object diameters from mass: V = (4/3)*pi*(r^3), m = density*V
    object_radii_m = ((3 * meteorite_masses_kg) ./ (4 * pi * density_kg_m3)).^(1/3);
    object_diameters_m = 2 * object_radii_m;
    object_areas_m2 = pi * object_radii_m.^2; % Compute cross-sectional area
        
    % Initialize probability storage
    P_d_values = zeros(length(object_diameters_m), length(distances_km));

       
    % Compute detection probabilities
    for i = 1:length(object_diameters_m)
        for j = 1:length(distances_km)
            term_vel_mps(i, j) = terminal_velocity(meteorite_masses_g(i), altitudes_km(j));
            residence_time_s(i, j) = beam_residence_time(distances_km(j), 0, ELEV_deg, 0, 0, term_vel_mps(i, j));
            P_d_values(i, j) = P_NEXRAD_detect(object_areas_m2(i), distances_km(j)) * P_NEXRAD_visible(distances_km(j),0,ELEV_deg,0,0,term_vel_mps(i, j),opmode);
            %P_d_values(i, j) = 1 * P_NEXRAD_visible(distances_km(j),0,4,0,0,50,'VCP31');
        end
    end

    % Plot results
    figure;
    plot(distances_km, P_d_values(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(distances_km, P_d_values(2, :), 'g', 'LineWidth', 2);
    plot(distances_km, P_d_values(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Distance (km)');
    ylabel('Probability of Detection');
    title(['NEXRAD Detection Probability' newline getNEXRAD('mode_type',opmode) ': ' opmode ]);
    axis([0 500 0 0.1]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left
end

    % Plot Termninal Velocity
    figure;
    plot(distances_km, term_vel_mps(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(distances_km, term_vel_mps(2, :), 'g', 'LineWidth', 2);
    plot(distances_km, term_vel_mps(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Distance (km)');
    ylabel('Terminal Velocity, m/s');
    title(['Meteorite Terminal Velocity' newline sprintf('Radar Elevation = %.1f%s', ELEV_deg, char(176)) ]);
    axis([0 500 0 500]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left
    
    % Plot Beam Residence
    figure;
    plot(distances_km, residence_time_s(1, :), 'r', 'LineWidth', 2);
    hold on;
    plot(distances_km, residence_time_s(2, :), 'g', 'LineWidth', 2);
    plot(distances_km, residence_time_s(3, :), 'b', 'LineWidth', 2);
    hold off;

    grid on;
    xlabel('Distance (km)');
    ylabel('Residence Time, seconds');
    title(['Radar Beam Residence Time' newline sprintf('Radar Elevation = %.1f%s', ELEV_deg, char(176)) ]);
    axis([0 500 0 60]);
    legend('1g meteorite', '10g meteorite', '100g meteorite', 'Location', 'northwest'); % Legend in bottom left