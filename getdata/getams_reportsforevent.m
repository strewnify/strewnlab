function [AMS_json] = getams_reportsforevent(AMS_EventID,path_export)
%GETAMS_REPORTSFOREVENT Get verbatim reports from AMS

% load API key
strewnconfig

% AMS connectivity disable
if getConfig('ams_disable')
    logformat('AMS connectivity is disabled by default until further notice.','ERROR')

% Run the GETAMS script
else

    % Add a slash to the export path, if missing
    if path_export(end) ~= '\' || path_export(end) ~= '/'
        path_export = [path_export '\'];
    end

    webread_options = weboptions('Timeout',webread_timeout);
    URL_AMS_API_eventreports = 'https://www.amsmeteors.org/members/api/open_api/get_reports_for_event';

    % Extract AMS Event ID contents
    % Example: '761-2023'
    if length(strfind(AMS_EventID,'-')) == 1
        event_id = extractBefore(AMS_EventID,'-');    
        year_str = extractAfter(AMS_EventID,'-');
    else
        logformat('Invalid AMS Event ID.','ERROR')
    end

    try
        % Get AMS report data
        AMS_json = webread([URL_AMS_API_eventreports '?year=' year_str '&event_id=' event_id '&format=json&api_key=' getPrivate('AMS_APIkey')],webread_options);

        % Convert to table
        %AMS_reports = json2table(AMS_json.result);

        reports = fieldnames(AMS_json.result);
        numreports = numel(reports);

        % Create a file to save the verbatim data
        datetimestring = datestr(now,'yyyymmddHH');
        FILENAME = ['AMS_Event' event_id '-' year_str '_Verbatims_Ver' datetimestring '.txt'];
        filepath_export = [path_export FILENAME];
        FID  = fopen(filepath_export,'w');

        for report_i = 1:numreports

            reportid = extractAfter(reports{report_i},'_');
            name = [AMS_json.result.(reports{report_i}).first_name ' ' AMS_json.result.(reports{report_i}).last_name];

            % general remarks
            remarks = AMS_json.result.(reports{report_i}).general_remarks;
            if ~isempty(remarks)

                % Write to file
                fprintf(FID,'%s (%s): %s\n',reportid, name, remarks);

                % Display to command window
                disp(sprintf('%s (%s): %s\n',reportid, name, remarks))
            end

            % terminal flash
            remarks = AMS_json.result.(reports{report_i}).terminal_flash_remarks;
            if ~isempty(remarks)

                % Write to file
                fprintf(FID,'%s (%s): %s\n', reportid, name, remarks);

                % Display to command window
                disp(sprintf('%s (%s): %s\n', reportid, name, remarks))
            end
        end
    catch
        logformat('AMS reports download failed.','DEBUG')
    end

    if exist('FID','var')
        fclose(FID);
    end
end