function load_session 
% LOAD_SESSION Load session data
% This function uses verious methods to obtain user location and system
% information, including timezone, coordinates, operating system, and
% screen size and resolution.

% Log initialization
logformat('Loading session and user environment data...','INFO')

% Initialize global variable
% Any existing data will be overwritten
global ref_session
ref_session = struct;

% default user present
ref_session.userpresent = true;

% Get timezone
try
    URL = ['https://timezoneapi.io/api/ip/?token=' Timezone_API_token];
    systeminfo_raw = webread(URL);
    ref_session.env.location = systeminfo_raw.data;
catch
    ref_session.env.location.timezone.id = 'Etc/UTC';
end

try
    % Get operating system
    ref_session.env.systeminfo.OS = getenv('OS');
catch
    ref_session.env.systeminfo.OS = 'unknown';
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
    ref_session.env.systeminfo.screen_w_pix = Pix_SS(1);
    ref_session.env.systeminfo.screen_h_pix = Pix_SS(2);
    ref_session.env.systeminfo.screen_w_in = Inch_SS(1);
    ref_session.env.systeminfo.screen_h_in = Inch_SS(2);
%     ref_session.env.systeminfo.
    
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

    ref_session.env.ip_address = result(start_idx:end_idx);
end

% Log temporary code fix, need to improve this function
% Need more logging of data in this function
logformat('Session data loaded from temporary file.  Need fix.','DEBUG')