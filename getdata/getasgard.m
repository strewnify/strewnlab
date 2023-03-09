function [ ASGARD_data ] = getasgard(dayhistory)
% GETASGARD

strewnconfig

% extend wait time for slow connections
webread_options = weboptions('Timeout',webread_timeout);

% Limit start date
% ASGARD data is not available before Dec 14, 2011
mindate = datetime(2011,12,14);
nowdate = datetime('now');
startdate = datetime('now') - days(dayhistory);
if startdate < mindate
    dayhistory = days(nowdate - mindate);
end

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Open a waitbar
handleASGARD = waitbar(0,'Checking ASGARD...'); 

ASGARD_fields = {'Datetime'};
InitCells = {datetime(1900,1,1)};
ASGARD_raw = cell2table(InitCells,'VariableNames',ASGARD_fields);


event = 0;

% get data for each day
readpages = 0;
for i = 0:dayhistory
    
    % Update waitbar
    waitbar(i/dayhistory,handleASGARD,'Checking ASGARD...');
    
    clear code
    datestring = datestr(now-days(i),'yyyymmdd');
    
    % Extract date, time, speed, and altitudes from the main page
    clear maincode
    try
        % Read the ASGARD html file
        URL_eventpage = ['https://fireballs.ndc.nasa.gov/' datestring '.html'];
        maincode = webread(URL_eventpage, webread_options);
        
        % Count successful page reads
        readpages = readpages + 1;
                
       % Find all the events on the page
        event_idx = strfind(maincode,'UTC');
        num_pageevents = numel(event_idx);
        
        for j = 1:num_pageevents
            event = event + 1;
            ASGARD_raw.URL_eventpage(event,1) = {URL_eventpage};
            ASGARD_raw.ProcessDate(event,1) = datetime(datestring,'InputFormat','yyyyMMdd');
            yearstring = maincode((event_idx(j)-45):(event_idx(j)-38));
            timestring = maincode((event_idx(j)-16):(event_idx(j)-9));
            ASGARD_raw.Datetime(event,1) = datetime([yearstring ' ' timestring],'InputFormat','yyyyMMdd HH:mm:ss');
            test = maincode((event_idx(j)+63):(event_idx(j)+67));
            if test(5) == 'k'
                ASGARD_raw.Speed(event,1) = str2num(maincode((event_idx(j)+63):(event_idx(j)+66)));
            else
                ASGARD_raw.Speed(event,1) = str2num(maincode((event_idx(j)+63):(event_idx(j)+67)));
            end
            if ASGARD_raw.Speed(event,1) >= 100
                offset = 1;
            elseif ASGARD_raw.Speed(event,1) < 10
                offset = -1;
            else
                offset = 0;
            end
            ASGARD_raw.start_alt(event,1) = str2num(maincode((event_idx(j)+104+offset):(event_idx(j)+108+offset)));
            test = maincode((event_idx(j)+104+offset):(event_idx(j)+109+offset));
            if test(6) == 'k'
                ASGARD_raw.end_alt(event,1) = str2num(maincode((event_idx(j)+143+offset):(event_idx(j)+147+offset)));
            else
                ASGARD_raw.end_alt(event,1) = str2num(maincode((event_idx(j)+144+offset):(event_idx(j)+148+offset)));
            end
            
            % Update waitbar
            waitbar((i+0.5)/dayhistory,handleASGARD,'Checking ASGARD...');
                
            % Extract location from orbit page
            clear orbitcode
            try
                URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' datestr(ASGARD_raw.Datetime(event),'yyyymmdd_HHMMss') 'A/'];
                orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                ASGARD_raw.URL_summary(event,1) = {[URL_detailed 'event.png']};
            catch
                try
                    URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' datestr(ASGARD_raw.Datetime(event),'yyyymmdd_HHMMss') 'B/'];
                    orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                    ASGARD_raw.URL_summary(event,1) = {[URL_detailed 'event.png']};
                catch
                    try
                        URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' datestr(ASGARD_raw.Datetime(event),'yyyymmdd_HHMMss') 'C/'];
                        orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                        ASGARD_raw.URL_summary(event,1) = {[URL_detailed 'event.png']};
                    catch
                        try
                            URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' datestr(ASGARD_raw.Datetime(event),'yyyymmdd_HHMMss') 'D/'];
                            orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                            ASGARD_raw.URL_summary(event,1) = {[URL_detailed 'event.png']};
                        catch
                            URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' datestr(ASGARD_raw.Datetime(event),'yyyymmdd_HHMMss') 'E/'];
                            orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                            ASGARD_raw.URL_summary(event,1) = {[URL_detailed 'event.png']};
                        end
                    end
                end
            end
            try
                latidx = strfind(orbitcode,'lat');
                ASGARD_raw.LAT(event,1) = str2num(orbitcode((latidx(1)+19):(latidx(1)+28)));
                ASGARD_raw.LONG(event,1) = wrapTo180(str2num(orbitcode((latidx(1)+54):(latidx(1)+63))));
            catch
                ASGARD_raw.LAT(event,1) = NaN;
                ASGARD_raw.LONG(event,1) = NaN;
            end
        end
    end
end

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

if readpages == 0
    error('ASGARD data not found.  Server may be down.')
end

% Filter out small events
if contains('end_alt',ASGARD_raw.Properties.VariableNames) && contains('Speed',ASGARD_raw.Properties.VariableNames)
    alt_filter = find((ASGARD_raw.Speed < slowmeteor_min_kps) | ((ASGARD_raw.end_alt < end_alt_max_km) & (ASGARD_raw.Speed < Speed_max_kps)));
else
    error('ASGARD data read error. Unexpected data format.')
end
ASGARD_data = ASGARD_raw(alt_filter,:);
ASGARD_data.Altitude = ASGARD_data.end_alt;

% Estimate impact energy
for i = 1:size(ASGARD_data,1)
   if ~isnan(ASGARD_data.Altitude(i))
        ASGARD_data.ImpactEnergy_Est(i) = estimpact(ASGARD_data.Altitude(i)*1000,45);
    else
        ASGARD_data.ImpactEnergy_Est(i) = estimpact(48000,45); % average end height is 48km
    end
end

% Assign EventID
ASGARD_data.EventID = arrayfun(@eventidcalc,ASGARD_data.LAT,ASGARD_data.LONG,ASGARD_data.Datetime,'UniformOutput',false);

% Create Excel hyperlinks
ASGARD_data.Hyperlink1 = ASGARD_data.URL_summary;
ASGARD_data.Hyperlink2 = ASGARD_data.URL_eventpage;
ASGARD_data.URL_summary = [];
ASGARD_data.URL_eventpage = [];

% Log
logformat(sprintf('%0.0f records retrieved from ASGARD',size(ASGARD_data,1)),'DATA')

% close waitbar
 close(handleASGARD)