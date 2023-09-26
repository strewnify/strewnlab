function [AMS_json] = getams_reportsforevent(AMS_EventID)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

strewnconfig
webread_options = weboptions('Timeout',webread_timeout);
URL_AMS_API_eventreports = 'https://www.amsmeteors.org/members/api/open_api/get_reports_for_event';

% Extract AMS Event ID contents
% Example: '761-2023'
if length(findstr(AMS_EventID,'-')) == 1
    event_id = extractBefore(AMS_EventID,'-');    
    year = extractAfter(AMS_EventID,'-');
else
    logformat('Invalid AMS Event ID.','ERROR')
end

% Get AMS report data
AMS_json = webread([URL_AMS_API_eventreports '?year=' year '&event_id=' event_id '&format=json&api_key=' AMS_APIkey],webread_options);

% Convert to table
%AMS_reports = json2table(AMS_json.result);

reports = fieldnames(AMS_json.result);
numreports = numel(reports);

for report_i = 1:numreports
    
    name = [AMS_json.result.(reports{report_i}).first_name ' ' AMS_json.result.(reports{report_i}).last_name];
    
    % general remarks
    remarks = AMS_json.result.(reports{report_i}).general_remarks;
    if ~isempty(remarks)
        disp(sprintf('%s: %s', name, remarks))
    end
    
    % terminal flash
    remarks = AMS_json.result.(reports{report_i}).terminal_flash_remarks;
    if ~isempty(remarks)
        disp(sprintf('%s: %s', name, remarks))
    end
end
