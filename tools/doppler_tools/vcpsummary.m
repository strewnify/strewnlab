% Extract field names (VCP modes)
vcp_modes = fieldnames(mode_data);

% Scatter plot for spin rates vs elevations
figure;
hold on;
colors = lines(length(vcp_modes)); % Generate distinct colors for each VCP mode
legendEntries = []; % Initialize an empty array for legend handles
legendLabels = {};  % Initialize an empty cell array for labels

% Loop through each VCP mode and plot data if detailed spin rates are available
for i = 1:length(vcp_modes)
    mode = mode_data.(vcp_modes{i});
    
    if isfield(mode, 'detailed_spin_rates') && length(mode.elevations) == length(mode.detailed_spin_rates)
        h = scatter(mode.elevations, mode.detailed_spin_rates, 50, colors(i, :), 'filled', 'DisplayName', mode.name); 
        legendEntries = [legendEntries, h]; % Store handle for legend
        legendLabels{end+1} = mode.name; % Store label
    end
end

xlabel('Elevation Angle (degrees)');
ylabel('Spin Rate (deg/s)');
title('Radar VCP Mode Spin Rates vs Elevation Angles');

% Ensure legend only includes valid entries
if ~isempty(legendEntries)
    legend(legendEntries, legendLabels, 'Location', 'best'); 
end

grid on;
hold off;

% Define durations and spin rates
durations = [327.2, 570.1, 565.5, 660, 420, ...
             269.4, 216.5, 330, 330, 276, 360];
spin_rates = [11.339, 5.039, 4.961, 5.5, 12, ...
              18.675, 21.150, 18, 29.301, 18, 15];

% Calculate Sweep duration for each mode based on its spin rate
sweep_durations = 360 ./ spin_rates;

% Create bar chart for VCP modes' sweep durations and total scan durations
figure;
bar_data = [sweep_durations; durations]'; % Sweep durations on the left, total scan durations on the right
bar(bar_data);
xticks(1:length(vcp_modes));
xticklabels(vcp_modes);
ylabel('Duration / Sweep Duration (s)');
title('VCP Mode Sweep Durations and Total Scan Durations');

% Add a legend indicating which bars represent sweep durations and which represent total scan durations
legend({'Sweep Duration', 'Total Scan Duration'}, 'Location', 'best');

% Display values on top of each bar with a higher offset
for i = 1:length(vcp_modes)
    % Display sweep duration values
    text(i, bar_data(i, 1) + 20, num2str(round(bar_data(i, 1))), 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    % Display total scan duration values
    text(i, bar_data(i, 2) + 20, num2str(round(bar_data(i, 2))), 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

grid on;
