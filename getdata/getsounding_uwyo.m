function [data_table] = getsounding_uwyo()
%GETSOUNDING_UWYO Download radiosonde data from the Univesity of Wyoming server
% DRAFT TBD

preventAbuse(5,50) % rate limit requests to every 5 seconds, max of max calls

% Get a timestamp for the data
nowtime = datetime('now','TimeZone','UTC');

% Send an HTML request in the request required by the server
% Examples:
% https://weather.uwyo.edu/cgi-bin/sounding?region=africa&TYPE=TEXT%3ALIST&YEAR=2024&MONTH=12&FROM=1212&TO=1212&STNM=61024
% https://weather.uwyo.edu/cgi-bin/sounding?region=europe&TYPE=TEXT%3ALIST&YEAR=2024&MONTH=12&FROM=1212&TO=1212&STNM=26298
% https://weather.uwyo.edu/cgi-bin/sounding?region=naconf&TYPE=TEXT%3ALIST&YEAR=2024&MONTH=12&FROM=1212&TO=1212&STNM=72215
% https://weather.uwyo.edu/cgi-bin/sounding?region=pac&TYPE=TEXT%3ALIST&YEAR=2024&MONTH=12&FROM=1212&TO=1212&STNM=94802

STNM = '72215';

URL_UWYO = 'https://weather.uwyo.edu/cgi-bin/sounding?region=';

% Download the data to a file in the Downloads folder
filepath = [getSession('folders','downloads') '\' STNM '.txt'];
html_webtext = websave(filepath, [URL_UWYO 'naconf&TYPE=TEXT%3ALIST&YEAR=2024&MONTH=12&FROM=1212&TO=1212&STNM=' STNM]);

% Data quality check
while

            % Update waitbar
            waitbar(stationprogress/globalstationcount,WaitbarHandle,'Reviewing WeatherStation Inventory');

            % Get the next line from the file
            line = fgetl(FID);

%testing
data_table = html_webtext;
