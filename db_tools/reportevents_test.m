function [ report ] = reportevents_test( eventdatabase, EventIDs, Sources, Records )
%[REPORT] = REPORTEVENTS(EVENT_TABLE) Summarize meteor events.
%   Takes database entries and creates text suitable for email
%   notification.

strewnconfig
email = false;
% eventdatabase = MeteorData;
% %EventIDs = [{'Y20200228_09Z_33T'} {'Y20200210_23Z_43R'} {'Y20191105_11Z_07L'}];

if nargin == 1
    EventIDs = fieldnames(eventdatabase)';
end
Sources = [{'CNEOS'} {'AMS'} {'Goodall'} {'MetBull'} {'NEOB'} {'ASGARD'} {'GMN'}];
Records = [1 2 3 4 5];

% Edit this section to add or remove fields
fields_formatted = [{'Location:'} {'eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).Location(max(1,end-column_width+3):end)'};...
    {'Date:'} {'datestr(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).DatetimeUTC,''mm/dd/yyyy'')'};...
    {'Time:'} {'datestr(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).DatetimeUTC,''HH:MM:ss UTC'')'};...
    {'Latitude:'} {'sprintf(''%1.4f'', eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).LAT)'};...
    {'Longitude:'} {'sprintf(''%1.4f'', eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).LONG)'};...
    {'Duration:'} {'sprintf(''%.3g s'', eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).duration_s)'};...
    {'Speed:'} {'sprintf(''%.3g km/s'', eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).entry_Speed_kps)'};...
    {'Bearing:'} {'[num2str(round(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).Bearing_deg,1)) 176 ''('' compassdir(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).Bearing_deg) '')'']'};...
    {'Slope:'} {'[num2str(round(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).ZenithAngle_deg,1)) 176 '' from vertical'']'};...
    {'Altitude:'} {'[num2str(round(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).ref_Height_km,2)) '' km'']'};...
    {'Energy Est:'} {'[num2str(round(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).ImpactEnergyEst_kt,2,''significant'')) '' kt'']'};...
    {'Mass Est:'} {'[num2str(round(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).entry_Mass_kg,2,''significant'')) '' kg'']'};...
    {'Cams/Reports:'} {'num2str(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).NumStations)'};...
    {'Source Key:'} {'eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).SourceKey'};...
    {'Hyperlink 1:'} {'eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).Hyperlink1'};...
    {'Hyperlink 2:'} {'eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).Hyperlink2'};...
    {'Google Map:'} {'HyperMap{1}'};...
    {'DateProcessed:'} {'datestr(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).DateProcessed,''mm/dd/yyyy'')'};...
    ];

% Get sizes
num_events = numel(EventIDs);
num_sources = numel(Sources);
num_records = numel(Records);
num_fields = size(fields_formatted,1);

% Table report init
t_row = 1;
MeteorDataExport = table;
EventID_fieldname = 'EventID';
Source_fieldname = 'ImportSource';
Record_fieldname = 'Record';

% Text report config
formatspec = ['%-' num2str(column_width) 's']; % format = '%18s' 

% Email header
if email
    switch num_events
        case 0
            report = 'No new events found.';
        case 1
            report = ['Since the last report, one meteor event has' newline 'been added to the Strewnify database:  '];
        otherwise
            report = ['Since the last report, ' num2str(num_events) ' meteor events have' newline 'been added to the Strewnify database:  '];
    end
    report = [report newline newline];
else
    report = '';
end
    
% Text Report
for event_i = 3:num_events
    if isfield(eventdatabase, EventIDs{event_i}) % if the event exists
        
        % Start building the header
        header = sprintf('%-13s  ', 'Source:');
        eventsummary = '';
        
        % Report each desired field
        for n = 1:num_fields
            
            % Start the row with a label
            row = sprintf('%-13s  ', fields_formatted{n,1});
            
            % Report each desired source
            column = 0;
            rowcontent = false(0); % create empty logical array
            
            for source_i = 1:num_sources
                
                if isfield(eventdatabase.(EventIDs{event_i}).Trajectory,Sources{source_i}) % if the source exists

                    % Report each desired record
                    for record_i = Records
                        
                        % Initialize row content check
                        column = column + 1;
                        rowcontent(column) = true;
                        
                        % Check if the record exists
                        temp_size = size(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i}),2);
                        if record_i > temp_size
                            % warning([EventIDs{event_i} '.Trajectory.' Sources{source_i} '(' num2str(record_i) ') not found!'])
                            break
                        else

                            % Generate Google map link
                            if ~isnan(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).LONG(1))
                                HyperMap = {['https://maps.google.com/?q=' num2str(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).LAT(1),'%f') '%20' num2str(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).LONG(1),'%f')]};
                            else
                                HyperMap = {''};
                            end

                            % Add a record heading for each record
                            if n == 1
                                if temp_size > 1
                                    header = [header sprintf(formatspec,[Sources{source_i} '(' num2str(record_i) ')'])];
                                else
                                    header = [header sprintf(formatspec,Sources{source_i})];
                                end
                            end
                            
                            % Attempt to read field data and add to report
                            try

                                % Retrieve data for the label, in specified format
                                eval(['data = sprintf(formatspec,' fields_formatted{n,2} ');']);
                                row = [row data]; 
                                
                                if contains(data,'NaN')
                                    rowcontent(column) = false;
                                end

                            % If data does not exist, show a warning
                            catch
                                logformat(['Failed to retrieve "' fields_formatted{n,1}(1:(end-1)) '" for ' EventIDs{event_i} '.Trajectory.' Sources{source_i} '(' num2str(record_i) ')'])                    
                                row = [row sprintf(formatspec,'')]; %empty column filler
                                rowcontent(column) = false;
                            end    
                        end
                        clear temp_*
                    end
                else
                    %warning(['No ' Sources{source_i} ' record found for ' EventIDs{event_i} ' !'])
                end
            end
            
            % Add the new row to the report
            if any(rowcontent)
                eventsummary = [eventsummary newline row];
            end
            clear rowcontent
        end
        report = [report '(' num2str(event_i) ') Meteor Event - ' EventIDs{event_i} newline newline header eventsummary newline newline newline];
        clear header
        clear eventsummary
    else
    warning([EventIDs{event_i} ' not found!'])
        
    end
end

% Email footer
if email
    if num_events > 0
        report = [report newline 'Note that some reports may contain events that are not actually new, only updated.' newline];
    end

    report = [report newline 'This is an automated message, contact Jim Goodall (james.a.goodall@gmail.com) with any questions.' newline];
end

% Table Report

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

for event_i = 3:num_events
    if isfield(eventdatabase, EventIDs{event_i}) % if the event exists

        % Report each desired source
        for source_i = 1:num_sources
            if isfield(eventdatabase.(EventIDs{event_i}).Trajectory,Sources{source_i}) % if the source exists

                % Report each desired record
                for record_i = Records 

                    % Check if the record exists
                    temp_size = size(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i}),2);
                    if record_i > temp_size
                        % warning([EventIDs{event_i} '.Trajectory.' Sources{source_i} '(' num2str(record_i) ') not found!'])
                    else
                        temp_fields = fields(eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i}));
                        MeteorDataExport.(EventID_fieldname)(t_row,1) = EventIDs(event_i);
                        MeteorDataExport.(Source_fieldname)(t_row,1) = Sources(source_i);
                        MeteorDataExport.(Record_fieldname)(t_row,1) = record_i;
                        for temp_i = 1:numel(temp_fields)
                            exportdata = eventdatabase.(EventIDs{event_i}).Trajectory.(Sources{source_i})(record_i).(temp_fields{temp_i});
                            if ~isempty(exportdata)
                                if ischar(exportdata)
%                                     temp_i
%                                     EventIDs{event_i}
%                                     Sources{source_i}
%                                     record_i
%                                     temp_fields{temp_i}
%                                     t_row
%                                     dadata = {exportdata}
%                                     test = exportdata
                                    
                                    MeteorDataExport.(temp_fields{temp_i})(t_row,1) = {exportdata};
                                elseif isstruct(exportdata)
                                    MeteorDataExport.(temp_fields{temp_i})(t_row,1) = {'struct'};
                                elseif max(size(exportdata)) > 1 || (iscell(exportdata) && (max(size(exportdata{1}))) > 1)
                                    MeteorDataExport.(temp_fields{temp_i})(t_row,1) = {'data'};
                                else
                                    MeteorDataExport.(temp_fields{temp_i})(t_row,1) = {exportdata};
                                end
                            end
                        end
                        t_row = t_row + 1;

                    end
                    clear temp_*
                end
            else
                %warning(['No ' Sources{source_i} ' record found for ' EventIDs{event_i} ' !'])
            end
        end
    else
    warning([EventIDs{event_i} ' not found!'])
        
    end
end


% Re-enable table row assignment warning
warning('on','MATLAB:table:RowsAddedExistingVars');

warning('DEV: Table display broken for missing data')

% Write the table to a CSV file 
% temporary = MeteorDataExport;
% temporary.Datetime = exceltime([temporary.Datetime{:}]');
% MeteorEvent_xlsdata = [temporary.Properties.VariableNames; table2cell(temporary)];
% clear temporary
% xlswrite('MeteorEventExport',MeteorEvent_xlsdata);
