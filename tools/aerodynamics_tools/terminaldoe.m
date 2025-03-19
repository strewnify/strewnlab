densities = [3380]; % [stony, iron] densities in kg/m^3
density_labels = {'Stony'}; % Labels for the legend

% densities = [3380, 7500]; % [stony, iron] densities in kg/m^3
% density_labels = {'Stony', 'Iron'}; % Labels for the legend

num_densities = length(densities);

altitudes_km = [0]; % Altitudes (km)
num_altitudes = length(altitudes_km);

masses_g = logspace(log10(0.5), log10(50000), 500);
masses_kg = masses_g / 1000;
num_masses = length(masses_g);

cubicity_main = 0.5;
cubicity_error = [0, 1];
masses_error_g = [1, 10, 100, 1000, 10000];
masses_error_kg = masses_error_g / 1000;

% Preallocate results matrices
terminal_velocities_mps = zeros(num_masses, num_altitudes, num_densities); % Added density dimension
terminal_velocities_mps_error = zeros(length(masses_error_g), num_altitudes, length(cubicity_error), num_densities); % Added density dimension

% Calculate terminal velocities for main lines (cubicity = 0.5)
for dens_idx = 1:num_densities
    for alt_idx = 1:num_altitudes
        for mass_idx = 1:num_masses
            terminal_velocities_mps(mass_idx, alt_idx, dens_idx) = terminal_velocity(masses_kg(mass_idx), densities(dens_idx), altitudes_km(alt_idx), cubicity_main);
        end
    end
end

% Calculate terminal velocities for error bars (cubicity = 0 and 1)
for dens_idx = 1:num_densities
    for alt_idx = 1:num_altitudes
        for cub_idx = 1:length(cubicity_error)
            for mass_idx = 1:length(masses_error_g)
                terminal_velocities_mps_error(mass_idx, alt_idx, cub_idx, dens_idx) = ...
                    terminal_velocity(masses_error_kg(mass_idx), densities(dens_idx), ...
                    altitudes_km(alt_idx), cubicity_error(cub_idx));
            end
        end
    end
end

% Plotting
figure;
hold on;
colors = lines(num_densities); % Colors for densities

% Plot main lines (cubicity = 0.5)
for dens_idx = 1:num_densities
    for alt_idx = 1:num_altitudes
        plot(masses_g, terminal_velocities_mps(:, alt_idx, dens_idx), 'Color', colors(dens_idx, :), 'LineWidth', 2);
    end
end

% Add labels only for x-tick values
x_ticks_g = [1, 10, 100, 1000, 10000];
x_tick_labels = {'1 gram', '10 gram', '100 gram', '1 kg', '10 kg'};
for i = 1:length(x_ticks_g)
    tick_val = x_ticks_g(i);
    tick_label = x_tick_labels{i};
    [~, closest_idx] = min(abs(masses_g - tick_val));
    for dens_idx = 1:num_densities
        ms_val = terminal_velocities_mps(closest_idx, :, dens_idx);
        mph_val = ms_val * 2.23694;
        plot(masses_g(closest_idx), ms_val, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
        for alt_idx = 1:num_altitudes
            text(masses_g(closest_idx)*1.1, ms_val(alt_idx), sprintf('%s\n%.0f m/s\n%.0f mph', tick_label, ms_val(alt_idx), mph_val(alt_idx)), ...
                'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'FontSize', 10);
        end
    end
end

% Plot error bars
for dens_idx = 1:num_densities
    for alt_idx = 1:num_altitudes
        for mass_idx = 1:length(masses_error_g)
            y_error_upper = terminal_velocities_mps_error(mass_idx, alt_idx, 1, dens_idx);
            y_error_lower = terminal_velocities_mps_error(mass_idx, alt_idx, 2, dens_idx);
            y_error_center = mean([y_error_lower y_error_upper]);
            x_error = masses_error_g(mass_idx);
            y_error_center = terminal_velocity(masses_error_kg(mass_idx), densities(dens_idx), altitudes_km(alt_idx), cubicity_main);
            errorbar(x_error, y_error_center, abs(y_error_center-y_error_lower), abs(y_error_upper-y_error_center), 'k.');

            if masses_error_g(mass_idx) == 1000 && altitudes_km(alt_idx) == altitudes_km(1)
                text(x_error * 0.90, y_error_lower, {'unusual', 'shape'}, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
                text(x_error * 0.90, y_error_center, 'typical', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
                text(x_error * 0.90, y_error_upper, {'perfect', 'sphere'}, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
            end
        end
    end
end

% Constant Kinetic Energy Lines
kinetic_energies_joules = [13.6 22, 32, 76];
line_styles = {'r:', 'm--', 'g-.', 'b:'};
ke_labels = {"Human Skull", "Tempered Auto Glass", "House Shingled Roof", "18 GA Steel"}; % Define your labels
ke_angles = [-72, -72, -72, -72]; % Angles in degrees for each label

% Get the x-axis limits
xlims = xlim;
xmin = xlims(1);
xmax = xlims(2);

% Get the y-axis limits
ylims = ylim;
ymin = ylims(1);
ymax = ylims(2);

% Manual label positions (adjust these values as needed)
label_x_positions = [2.7, 4.4, 6.5, 15]; % X-coordinates (in grams)
label_y_positions = [100, 100, 100, 100]; % Y-coordinates (in m/s)

for ke_idx = 1:length(kinetic_energies_joules)
    kinetic_energy_joules = kinetic_energies_joules(ke_idx);
    constant_ke_velocity_mps = sqrt((2 * kinetic_energy_joules) ./ masses_kg);
    plot(masses_g, constant_ke_velocity_mps, line_styles{ke_idx}, 'LineWidth', 2);

    % Manually place and rotate the label
    text(label_x_positions(ke_idx), label_y_positions(ke_idx), ke_labels(ke_idx), ...
        'Rotation', ke_angles(ke_idx), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold', 'FontSize', 14, 'Color', line_styles{ke_idx}(1));
end

% Main title
title('Stony Meteorite Terminal Velocity', 'FontSize', 16);

%Subtitle
subtitle_text = 'w/ Penetration Estimate of Various Materials';
annotation('textbox', [0.18, 0.88, 0.7, 0.05], ... % [left bottom width height]
    'String', subtitle_text, ...
    'FontSize', 12, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'LineStyle', 'none');

xlabel('Meteorite Mass', 'FontWeight', 'bold');
ylabel('Terminal Velocity (m/s)', 'FontWeight', 'bold');
grid on;
xticks([1, 10, 100, 1000, 10000]);
xticklabels(x_tick_labels);
xlim([0.7, 35000]);

% Determine the maximum terminal velocity value
max_terminal_velocity = max(terminal_velocities_mps(:));

% Set y-axis limits, only including the terminal velocity lines.
ylim([0, max_terminal_velocity * 1.02]); % Add a 10% buffer

% Add right y-axis for mph
ax1 = gca;
set(gca, 'XScale', 'log');

% Generate clean y-axis ticks for m/s
y_min_ms = floor(min(ax1.YLim) / 10) * 10;
y_max_ms = ceil(max(ax1.YLim) / 10) * 10;
y_ticks_ms = y_min_ms:5:y_max_ms;
ax1.YTick = y_ticks_ms;

ax2 = axes('Position', ax1.Position, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none');
ax2.XLim = ax1.XLim;
ax2.YLim = ax1.YLim * 2.23694; % Set mph limit based on m/s limit

% Generate corresponding mph ticks
mph_ticks = round(y_ticks_ms * 2.23694);
ax2.YTick = mph_ticks;
ylabel(ax2, 'Terminal Velocity, mph', 'FontWeight', 'bold');

hold off;