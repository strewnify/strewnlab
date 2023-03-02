function [environment] = getenvironment
%GETENVIRONMENT Get user environment info
% This function uses verious methods to obtaiun user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Init struct
environment = struct;

% Get timezone
try
    URL = ['https://timezoneapi.io/api/ip/?token=' Timezone_API_token];
    systeminfo_raw = webread(URL);
    environment.location = systeminfo_raw.data;
catch
    environment.location.timezone.id = 'Etc/UTC';
end

try
    % Get operating system
    environment.systeminfo.OS = getenv('OS');
catch
    environment.systeminfo.OS = 'unknown';
end

% Get monitor size
try
    %Sets the units of your root object (screen) to pixels
    set(0,'units','pixels');

    %Obtains this pixel information
    Pix_SS = get(0,'screensize');
    Pix_SS = Pix_SS(Pix_SS > 1);
    
    %Sets the units of your root object (screen) to inches
    set(0,'units','inches');

    %Obtains this inch information
    Inch_SS = get(0,'screensize');
    Inch_SS = Inch_SS(Inch_SS > 1);
    
    % Store data to output
    environment.systeminfo.screen_w_pix = Pix_SS(1);
    environment.systeminfo.screen_h_pix = Pix_SS(2);
    environment.systeminfo.screen_w_in = Inch_SS(1);
    environment.systeminfo.screen_h_in = Inch_SS(2);
    environment.systeminfo.
    
end

try
    % get IPv4 address
    [~, result] = system('ipconfig');
    ip_delimiter = 'IPv4 Address. . . . . . . . . . . : ';
    offset = length(ip_delimiter);
    start_idx = findstr(result,ip_delimiter)+offset;

    % line break after delimiter
    line_breaks = findstr(result(start_idx:end),char(10));

    end_idx = start_idx + line_breaks(1) - 2;

    ip_address = result(start_idx:end_idx);
end


