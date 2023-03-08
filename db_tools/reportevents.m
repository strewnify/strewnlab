function [ eventreport ] = reportevents( eventdata )
%[REPORT] = REPORTEVENTS(EVENT_TABLE) Summarize meteor events.
%   Takes database entries and creates text suitable for email
%   notification.

colwidth = 45;
formatspec = ['%-' num2str(colwidth) 's']; % format = '%18s' 
numevents = size(eventdata,1);


Labels = [{'Location:'} {'Date:'} {'Time:'} {'Latitude:'} {'Longitude:'} {'Speed'} {'Bearing:'} {'Slope:'} {'Altitude:'} {'Mass:'} {'Report count:'} {'Hyperlink 1:'} {'Hyperlink 2:'} {'Map Link:'}];
idx = [{'Location'} {'Datetime'} {'LAT'} {'LONG'} {'Bearing'} {'Incidence'} {'Altitude'} {'Hyperlink1'} {'Hyperlink2'} {'HyperMap'}];
dataformat = [{'eventdata.Location{event}(max(1,end-colwidth+3):end)'}...
    {'datestr(eventdata.Datetime(event),''mm/dd/yyyy'')'}...
    {'datestr(eventdata.Datetime(event),''HH:MM:ss UTC'')'}...
    {'sprintf(''%1.4f'', eventdata.LAT(event))'}...
    {'sprintf(''%1.4f'', eventdata.LONG(event))'}...
    {'[num2str(round(eventdata.Speed(event),2)) '' km/s'']'}...
    {'[num2str(round(eventdata.Bearing(event),1)) 176 ''('' compassdir(eventdata.Bearing(event)) '')'']'}...
    {'[num2str(round(eventdata.Incidence(event),1)) 176 '' from vertical'']'}...
    {'[num2str(round(eventdata.Altitude(event),2)) '' km'']'}...
    {'[num2str(round(eventdata.Mass(event),2)) '' kg'']'}...
    {'num2str(eventdata.NumReports(event))'}...
    {'eventdata.Hyperlink1{event}'}...
    {'eventdata.Hyperlink2{event}'}...
    {'eventdata.HyperMap{event}'}...
    ];

% Email header
if numevents == 0
    eventreport = 'No new events found.';
else
    eventreport = '';
end
eventreport = [eventreport newline newline];
    
for event = 1:numevents
    
    EventID = eventdata.EventID{event};
    EventID = ['Y' EventID(2:end)];
    eventreport = [eventreport '(' num2str(event) ') ' eventdata.DataSource{event} ' Meteor Event - ' EventID newline];
        
    for n = 1:numel(dataformat)
        
        % Start the row with a label
        row = sprintf('%-13s  ',[Labels{n}]);

        eval(['data = sprintf(formatspec,' dataformat{n} ');']);
        row = [row data];   

        % Add the new row to the report
        if isempty(strfind(row,'NaN'))
            eventreport = [eventreport newline row];
        end
    end
    eventreport = [eventreport newline newline];
end

if numevents > 0
    eventreport = [eventreport newline 'Note that some reports may contain events that are not actually new, only updated. '];
end

eventreport = [eventreport 'This is an automated message, contact Jim Goodall (james.a.goodall@gmail.com) with any questions.' newline newline];
eventreport = [eventreport 'More info and strewn field maps at: www.strewnify.com' newline];
eventreport = [eventreport 'Join the discussion on Discord at: https://discord.gg/hXj37dbgPx' newline];