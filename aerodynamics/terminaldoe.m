% Terminal Velocity DOE Script

% Altitudes (km) - Reversed order
%altitudes_km = [15, 0];
altitudes_km = [0];
num_altitudes = length(altitudes_km);

% Masses (grams) - Log scale from 0.5 gram to 50000 g
masses_g = logspace(log10(0.5), log10(50000), 500);
masses_kg = masses_g / 1000;
num_masses = length(masses_g);

% Cubicity values for main lines
cubicity_main = 0.5;

% Cubicity values for error bars
cubicity_error = [0, 1];

% Masses for error bars (grams)
masses_error_g = [1, 10, 100, 1000, 10000];
masses_error_kg = masses_error_g / 1000;

% Preallocate results matrices
terminal_velocities_mps_main = zeros(num_masses, num_altitudes);
terminal_velocities_mps_error = zeros(length(masses_error_g), num_altitudes, length(cubicity_error));

% Calculate terminal velocities for main lines (cubicity = 0.5)
for alt_idx = 1:num_altitudes
    for mass_idx = 1:num_masses
        terminal_velocities_mps_main(mass_idx, alt_idx) = terminal_velocity(masses_kg(mass_idx), altitudes_km(alt_idx), cubicity_main);
    end
end

% Calculate terminal velocities for error bars (cubicity = 0 and 1)
for alt_idx = 1:num_altitudes
    for cub_idx = 1:length(cubicity_error)
        for mass_idx = 1:length(masses_error_g)
            terminal_velocities_mps_error(mass_idx, alt_idx, cub_idx) = ...
                terminal_velocity(masses_error_kg(mass_idx), ...
                altitudes_km(alt_idx), cubicity_error(cub_idx));
        end
    end
end

% Plotting
figure;
hold on;
colors = flipud(lines(num_altitudes));

% Plot main lines (cubicity = 0.5)
for alt_idx = 1:num_altitudes
    h = plot(masses_g, terminal_velocities_mps_main(:, alt_idx), 'Color', colors(alt_idx, :), 'LineWidth', 2);
    if altitudes_km(alt_idx) == 0 % Keep handle for the sea level line.
        sea_level_handle = h;
    end
end

% Add labels only for x-tick values
x_ticks_g = [1, 10, 100, 1000, 10000]; % X-tick values in grams
x_tick_labels = {'1 gram', '10 gram', '100 gram', '1 kg', '10 kg'}; % X-tick labels
for i = 1:length(x_ticks_g)
    tick_val = x_ticks_g(i);
    tick_label = x_tick_labels{i};
    [~, closest_idx] = min(abs(masses_g - tick_val)); % Find closest index
    ms_val = terminal_velocities_mps_main(closest_idx, :);
    mph_val = ms_val * 2.23694;
    plot(masses_g(closest_idx), ms_val, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4); % Black, filled, larger points
    for alt_idx = 1:num_altitudes
        text(masses_g(closest_idx)*1.1, ms_val(alt_idx), sprintf('%s\n%.0f m/s\n%.0f mph', tick_label, ms_val(alt_idx), mph_val(alt_idx)), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'FontSize', 10); % Moved down and right
    end
end

% Re-plot the sea level line to ensure it is a line
set(sea_level_handle, 'Color', colors(end, :), 'LineWidth', 2);

% Plot error bars
for alt_idx = 1:num_altitudes
    for mass_idx = 1:length(masses_error_g)
        y_error_upper = terminal_velocities_mps_error(mass_idx, alt_idx, 1);
        y_error_lower = terminal_velocities_mps_error(mass_idx, alt_idx, 2);
        y_error_center = mean([y_error_lower y_error_upper]);
        x_error = masses_error_g(mass_idx);
        y_error_center = terminal_velocity(masses_error_kg(mass_idx), altitudes_km(alt_idx), cubicity_main);
        errorbar(x_error, y_error_center, abs(y_error_center-y_error_lower), abs(y_error_upper-y_error_center), 'k.');

        % Add error bar labels only for 1kg and 15km, move left
if masses_error_g(mass_idx) == 1000 && altitudes_km(alt_idx) == altitudes_km(1)
    text(x_error * 0.90, y_error_lower, {'unusual', 'shape'}, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10,'FontWeight', 'bold');
    text(x_error * 0.90, y_error_center, 'typical', 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
    text(x_error * 0.90, y_error_upper, {'perfect', 'sphere'}, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
end
    end
end

title('Meteorite Terminal Velocity', 'FontSize', 16);
xlabel('Meteorite Mass (grams)', 'FontWeight', 'bold');
ylabel('Terminal Velocity (m/s)', 'FontWeight', 'bold');
grid on;
xticks([1, 10, 100, 1000, 10000]);
xticklabels(x_tick_labels);
xlim([0.7, 35000]);

% Create legend (reverse order), make it bigger
if length(altitudes_km) > 1
    legend_labels = cell(1, num_altitudes);
    for alt_idx = 1:num_altitudes
        if altitudes_km(alt_idx) == 0
            legend_labels{alt_idx} = 'Sea Level';
        else
            legend_labels{alt_idx} = [num2str(altitudes_km(alt_idx)), ' km Altitude'];
        end
    end
    legend(flipud(legend_labels), 'Location', 'northwest', 'FontSize', 12);
end

% Add right y-axis for mph
ax1 = gca;
set(gca, 'XScale', 'log');
ax2 = axes('Position', ax1.Position, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none');
ax2.XLim = ax1.XLim;
ax2.YLim = ax1.YLim * 2.23694;

% Generate clean y-axis ticks for m/s
y_min_ms = floor(min(ax1.YLim) / 10) * 10; % Round down to nearest 10
y_max_ms = ceil(max(ax1.YLim) / 10) * 10;  % Round up to nearest 10
y_ticks_ms = y_min_ms:5:y_max_ms; % Increments of 20 m/s, adjust as needed.
ax1.YTick = y_ticks_ms;

% Generate corresponding mph ticks
mph_ticks = round(y_ticks_ms * 2.23694);
ax2.YTick = mph_ticks;
ylabel(ax2, 'Terminal Velocity, mph', 'FontWeight', 'bold');

hold off;