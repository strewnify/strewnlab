function [ ASGARD_data ] = getasgard_test(startdate, enddate)
% GETASGARD

% Load config
strewnconfig
nowtime_utc = datetime('now','TimeZone','UTC');

% if timezone is empty, assume UTC
if isempty(startdate.TimeZone) || ~strcmp(startdate.TimeZone,'UTC')
    startdate.TimeZone = 'UTC';
end
if isempty(enddate.TimeZone) || ~strcmp(enddate.TimeZone,'UTC')
    enddate.TimeZone = 'UTC';
end

% Clip min date for source database
mindate = datetime(500,1,1,'TimeZone','UTC'); % No min date
if isnat(startdate) || startdate < mindate
    startdate = mindate;
end
if isnat(enddate) || enddate > nowtime_utc
    enddate = nowtime_utc;
end

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Open a waitbar
handleASGARD = waitbar(0,'Checking ASGARD...'); 

ASGARD_fields = {'DatetimeUTC'};
InitCells = {datetime(1900,1,1,'TimeZone','UTC')};
ASGARD_raw = cell2table(InitCells,'VariableNames',ASGARD_fields);


event = 0;

% get data for each day
readpages = 0;
for date_idx = startdate:days(1):enddate
    
    % Update waitbar
    waitbar(days(date_idx-startdate)/days(enddate-startdate),handleASGARD,'Checking ASGARD...');
    
    clear code
    datestring = datestr(date_idx,'yyyymmdd');
    
    % Extract date, time, speed, and height from the main page
    clear html_*
    try
        % Read the ASGARD html file
        nowtime = datetime('now','TimeZone','UTC');
        Hyperlink2 = ['https://fireballs.ndc.nasa.gov/' datestring '.html'];
        html_webpage = webread(Hyperlink2,webread_options);
        
        % Count successful page reads
        readpages = readpages + 1;
                
       % Find all the events on the page
        html_event_idx = strfind(html_webpage,'UTC');
        html_numevents = numel(html_event_idx);
        
        for j = 1:html_numevents
            event = event + 1;
            ASGARD_raw.Hyperlink2(event,1) = {Hyperlink2};
            ASGARD_raw.DateProcessed(event,1) = datetime(datestring,'InputFormat','yyyyMMdd','TimeZone','UTC');
            ASGARD_raw.DateAccessed(event,1) = nowtime;
            ASGARD_raw.ProcessIndex(event,1) = j;
            
            % Parse event date and time
            yearstring = html_webpage((html_event_idx(j)-45):(html_event_idx(j)-38));
            timestring = html_webpage((html_event_idx(j)-16):(html_event_idx(j)-9));
            ASGARD_raw.DatetimeUTC(event,1) = datetime([yearstring ' ' timestring],'InputFormat','yyyyMMdd HH:mm:ss','TimeZone','UTC');
            
            % Parse event data
            html_eventdata = html_webpage((html_event_idx(j)):(html_event_idx(j)+160));
            html_data_idx = strfind(html_eventdata, 'km');
            if numel(html_data_idx) == 3                
                
                % Parse speed
                html_speedstring = html_eventdata((html_data_idx(1)-8):(html_data_idx(1)));
                html_speed_idx1 = strfind(html_speedstring, '>') + 1;
                html_speed_idx2 = strfind(html_speedstring, 'k') - 2;
                ASGARD_raw.ref_Speed_kps(event,1) = str2double(html_speedstring(html_speed_idx1:html_speed_idx2));
                
                % Parse entry height
                html_startstring = html_eventdata((html_data_idx(2)-8):(html_data_idx(2)));
                html_start_idx1 = strfind(html_startstring, '>') + 1;
                html_start_idx2 = strfind(html_startstring, 'k') - 2;
                ASGARD_raw.entry_Height_km(event,1) = str2double(html_startstring(html_start_idx1:html_start_idx2));
                
                % Parse end height
                html_endstring = html_eventdata((html_data_idx(3)-8):(html_data_idx(3)));
                html_end_idx1 = strfind(html_endstring, '>') + 1;
                html_end_idx2 = strfind(html_endstring, 'k') - 2;
                ASGARD_raw.ref_Height_km(event,1) = str2double(html_endstring(html_end_idx1:html_end_idx2));
                ASGARD_raw.end_Height_km(event,1) = ASGARD_raw.ref_Height_km(event,1);
                ASGARD_raw.ref_Description(event,1) = {'End'};
            else
                warning(['Could not parse event ' num2str(j) ' data at ' Hyperlink2 '.']) 
            end
            
            
            % Update waitbar
            waitbar(days(date_idx-startdate)/days(enddate-startdate),handleASGARD,'Checking ASGARD...');
                
            % Extract location from orbit page
            clear orbitcode
            ASGARD_raw.SourceKey{event} = datestr(ASGARD_raw.DatetimeUTC(event),'yyyymmdd_HHMMss');
            
            try
                URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' ASGARD_raw.SourceKey{event} 'A/'];
                orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                ASGARD_raw.Hyperlink1(event,1) = {[URL_detailed 'event.png']};
            catch
                try
                    URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' ASGARD_raw.SourceKey{event} 'B/'];
                    orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                    ASGARD_raw.Hyperlink1(event,1) = {[URL_detailed 'event.png']};
                catch
                    try
                        URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' ASGARD_raw.SourceKey{event} 'C/'];
                        orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                        ASGARD_raw.Hyperlink1(event,1) = {[URL_detailed 'event.png']};
                    catch
                        try
                            URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' ASGARD_raw.SourceKey{event} 'D/'];
                            orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                            ASGARD_raw.Hyperlink1(event,1) = {[URL_detailed 'event.png']};
                        catch
                            URL_detailed = ['https://fireballs.ndc.nasa.gov/' 'evcorr/' datestring '/' ASGARD_raw.SourceKey{event} 'E/'];
                            orbitcode = webread([URL_detailed 'orbit.txt'],webread_options);
                            ASGARD_raw.Hyperlink1(event,1) = {[URL_detailed 'event.png']};
                        end
                    end
                end
            end
            try
                latidx = strfind(orbitcode,'lat');
                ASGARD_raw.ref_Lat(event,1) = str2double(orbitcode((latidx(1)+19):(latidx(1)+28)));
                ASGARD_raw.ref_Long(event,1) = wrapTo180(str2double(orbitcode((latidx(1)+54):(latidx(1)+63))));
            catch
                ASGARD_raw.ref_Lat(event,1) = NaN;
                ASGARD_raw.ref_Long(event,1) = NaN;
            end
        end
    catch
        warning(['Could not read ' Hyperlink2 ' Skipping to next...'])
    end
end



if readpages == 0
    error('ASGARD data not found.  Server may be down.')
end

% Filter out small events
if contains('end_Height_km',ASGARD_raw.Properties.VariableNames) && contains('ref_Speed_kps',ASGARD_raw.Properties.VariableNames)
    alt_filter = (ASGARD_raw.end_Height_km < end_alt_max_km) & (ASGARD_raw.ref_Speed_kps < Speed_max_kps);
else
    error('ASGARD data read error. Unexpected data format.')
end
ASGARD_data = ASGARD_raw(alt_filter,:);

% Post processing - complex functions for each record
ASGARD_numrecords = size(ASGARD_data,1);
for event_i = 1:ASGARD_numrecords

    % Estimate impact energy
    if ~isnan(ASGARD_data.end_Height_km(event_i))
        ASGARD_data.ImpactEnergyEst_kt(event_i) = estimpact(ASGARD_data.end_Height_km(event_i)*1000,45);
    else
        ASGARD_data.ImpactEnergyEst_kt(event_i) = estimpact(48000,45); % average end height is 48km
    end
end

% Assign EventID
ASGARD_data.EventID_nom = arrayfun(@eventid,ASGARD_data.ref_Lat,ASGARD_data.ref_Long,ASGARD_data.DatetimeUTC,'UniformOutput',false);

% Filter events before dayhistory
ASGARD_data = ASGARD_data(ASGARD_data.DatetimeUTC >= startdate & ASGARD_data.DatetimeUTC <= enddate,:);

% Standardize output data
ASGARD_data.DateAccessed(:) = nowtime_utc; % Add timestamp
ASGARD_data = standardize_tbdata(ASGARD_data); % Convert units and set column order

% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

% Log
logformat(sprintf('%0.0f records retrieved from ASGARD',size(ASGARD_data,1)),'DATA')

% close waitbar
 close(handleASGARD)