function [ Events_tb ] = convertevents_test( eventdatabase)
%[REPORT] = REPORTEVENTS(EVENT_TABLE) Summarize meteor events.
%   Takes database entries and creates text suitable for email
%   notification.

WaitbarHandle = waitbar(0,'Please wait...');

strewnconfig

EventIDs = fieldnames(eventdatabase)';
Sources = [{'CNEOS'} {'AMS'} {'Goodall'} {'MetBull'} {'NEOB'} {'ASGARD'} {'GMN'}];
Records = [1];

% Get sizes
num_events = numel(EventIDs);
num_sources = numel(Sources);
num_records = numel(Records);

% Table report init
t_row = 1;
Events_tb = table;
EventID_fieldname = 'EventID';
Source_fieldname = 'ImportSource';
Record_fieldname = 'Record';
    
% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

for event_i = 10000:num_events
    
    % Update waitbar
    waitbar(event_i/num_events,WaitbarHandle,sprintf('Reading Event %0.0f of %0.0f', event_i, num_events));

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
                    Events_tb.(EventID_fieldname)(t_row,1) = EventIDs(event_i);
                    Events_tb.(Source_fieldname)(t_row,1) = Sources(source_i);
                    Events_tb.(Record_fieldname)(t_row,1) = record_i;
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

                                Events_tb.(temp_fields{temp_i})(t_row,1) = {exportdata};
                            elseif isstruct(exportdata)
                                Events_tb.(temp_fields{temp_i})(t_row,1) = {'struct'};
                            elseif max(size(exportdata)) > 1 || (iscell(exportdata) && (max(size(exportdata{1}))) > 1)
                                Events_tb.(temp_fields{temp_i})(t_row,1) = {'data'};
                            else
                                Events_tb.(temp_fields{temp_i})(t_row,1) = {exportdata};
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

close(WaitbarHandle);