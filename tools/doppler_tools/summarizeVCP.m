function summarizeVCP(VCPmode)
    % summarizeVCP Summarizes the details of a given VCP mode by calling the getNEXRAD function.
    %
    % Inputs:
    %   VCPmode: The Volume Coverage Pattern (VCP) mode to summarize (e.g., 'VCP31', 'VCP34').
    %
    % Outputs:
    %   None. Displays the summary of the VCP mode and includes a plot of beam height vs curve distance with beam width shown.

    % Get the name of the VCP
    vcpName = getNEXRAD('name', VCPmode);
    
    % Get the duration of the VCP
    vcpDuration = getNEXRAD('vcp_duration_s', VCPmode);
    
    % Get the elevation angles for the VCP
    elevations = getNEXRAD('elevations', VCPmode);
    
    % Get the reflectivity information for the VCP
    reflectivity = getNEXRAD('reflectivity', VCPmode);
    
    % Get the spin rates for the VCP
    spinRates = getNEXRAD('spin_rates_deg_s', VCPmode);
    
    % Get the mode type (Clear-air or Precipitation)
    modeType = getNEXRAD('mode_type', VCPmode);
    
    sweep_time_s = 360./spinRates;
    
    range_reflectivity_km = getNEXRAD('range_reflectivity_km',VCPmode);
    
    % Determine the dynamic separator length
    separatorLength = 20 + min(150, numel(elevations) * 7);
    separator = repmat('-', 1, separatorLength);

    % Display summary
    fprintf('VCP Mode:  %s\n', vcpName);
    fprintf('Mode Type: %s\n', modeType);
    fprintf('Duration:  %.0f seconds\n', vcpDuration);
    fprintf('%s\n', separator);
    letters = repmat('v', size(reflectivity)); % Default to 'v'
    letters(reflectivity) = 'r'; % Set 'r' where true

    fprintf('Elevation Scans:    ');
    for i = 1:numel(elevations)
        fprintf('%5.1f%c ', elevations(i), letters(i)); % Use %c for character formatting
    end
    fprintf('\n');

    fprintf('Spin Rates (deg/s):');
    fprintf('%6.1f ', spinRates); % Prints all values in a single line
    fprintf('\n');

    fprintf('Sweep Time (s):    ');
    fprintf('%6.1f ', sweep_time_s); % Prints all values in a single line
    fprintf('\n');
    fprintf('%s\n', separator);
    
    % Plot Beam Height vs Curve Distance with varying beam width
    figure;
    hold on;
    for i = 1:length(elevations)
        ELEV_deg = elevations(i);  % Get each elevation angle
        ELEV_rad = deg2rad(ELEV_deg);
        
        % Define range of distances (5 km to 1000 km)
        slantRanges_km = linspace(1, range_reflectivity_km, 1000); % 1000 points along the range
        slantRanges_m = slantRanges_km .* 1000;

        % Import planet ellipsoid
        planet = getPlanet();
        
        % Compute altitude at each slant range using aer2geodetic
        [LAT, LON, altitudes_m] = aer2geodetic(0, ELEV_deg, slantRanges_m, 42, -82, 0, planet.ellipsoid_m);
        altitudes_km = altitudes_m ./ 1000;  % Convert altitudes to km

        % Compute the curve distance (horizontally along the Earth's surface)
        [curve_distances_m, ~] = distance(42, -82, LAT, LON, planet.ellipsoid_m);  % small offset for distance calc
        curve_distances_km = curve_distances_m ./ 1000;  % Convert to km

        % Simulate beam width (this can be adjusted as per the specific beam spread model)
        beam_width = 0.008 * curve_distances_km;  % Example width factor (adjust as needed)

        % Create a shaded region for the beam
        % The beam width changes as a function of the curve distance
        fill([curve_distances_km, fliplr(curve_distances_km)], ...
             [altitudes_km - beam_width, fliplr(altitudes_km + beam_width)], ...
             'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Shaded area

        % Plot beam height vs curve distance for this elevation with black lines and thinner width
        plot(curve_distances_km, altitudes_km, 'k', 'LineWidth', 1, 'DisplayName', sprintf('ELEV = %.1f°'));
        
        % Label the rightmost point of each beam path
        text(curve_distances_km(end), altitudes_km(end), sprintf(' %.1f°', ELEV_deg), ...
        'FontSize', 10, 'Color', 'k', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

        axis([0 500 0 180])
    
    end
    hold off;
    
    % Label the plot
    xlabel('Ground Distance, km');
    ylabel('Altitude, km');
    title(['Volume Coverage Pattern (VCP) Summary' newline vcpName ': ' modeType]);
    grid on;

end

