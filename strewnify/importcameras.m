% function [newcontacts] = importcontacts()
%IMPORTCAMERAS  Import camera registration data
%   IMPORTCAMERAS allows the user to import camera registration 
%   data into the Strewnify Database

logformat('Camera Import Function Not Complete.','ERROR')

% Load settings
strewnconfig
nowtime_utc = datetime('now','TimeZone','UTC'); 
datetimestring = datestr(now,'yyyymmddHHMM');

% Turn off table warning
warning('off','MATLAB:table:RowsAddedExistingVars');

%Load the database
load_database

try
    
    % Attempt to download the file
    cd([getSession('folders','mainprefix') '\Downloads\'])
    FILTERINDEX = 1;
    PATHNAME = [getSession('folders','mainprefix') '\Downloads\'];
    FILENAME = ['strewn_contacts' datetimestring '.csv'];
    options = weboptions('MediaType', 'application/json', 'ArrayFormat', 'csv');
    websave(FILENAME,['https://docs.google.com/spreadsheet/ccc?key=' getPrivate('GoogleFormsCam_key') '&output=csv&pref=1'],weboptions);
    dateFormat = 'MM/dd/yyyy h:mm:SS aa';
    cd(getSession('folders','mainfolder'))
    logformat(sprintf('%s retrieved from Google Drive',FILENAME),'INFO')

catch
    cd(getSession('folders','mainfolder'))
    logformat('Google Drive download failed, manually download file.','DEBUG')
    
    % Import the contact file
    [FILENAME, PATHNAME, FILTERINDEX] = uigetfile({'*.csv;*.xls;*.xlsx'});
    if FILTERINDEX == 0
        error('No file selected for import.')
    end
    dateFormat = 'yyyy/MM/dd h:mm:SS aa z';
end

% import the data
[~,~,cameradata] = xlsread([PATHNAME FILENAME]);

% Start logging
diary([getSession('folders','logfolder') '\strewnnotify_log.txt'])        
diary on 
logformat(sprintf('Importing camera registration data from %s',FILENAME),'INFO')

% Map import data columns
cols_time = 1;
cols_email = 2;
cols_firstname = 3;
cols_lastname = 3;
cols_address = 4;
cols_cat = 5;
cols_rad = 6;

% Prepare for import, find latest entry
importsize = size(cameradata,1);
db_start_idx = size(sdb_Contacts.TimeAdded,1) + 1;

% Find the first import entry newer than the last database entry
start_idx = find((datetime(cameradata(:,cols_time),'InputFormat',dateFormat,'TimeZone','UTC') > sdb_Contacts.TimeAdded(end)) == true,1);
if isempty(start_idx)
    start_idx = size(cameradata,1) + 1;
end
% 
% for idx = start_idx:importsize
%     import_email = cameradata{idx,cols_email};
%     matchcnt = size(find(strcmp(sdb_Contacts.Email,import_email)),1);
%     if matchcnt > 0
%         warning([import_email ' already exists in database, adding duplicate record.'])
%     end
%     
%     % Convert radius
%     if isnan(cameradata{idx,cols_rad})
%         radius_km = max_radius_km;
%     else
%         radius_km = min(max(min_radius_km, cameradata{idx,cols_rad}),max_radius_km); % clip search radius between min and max
%     end
%     
%     % Add record
%     sdb_Contacts.TimeAdded(end+1) = nowtime_utc;
%     switch cameradata{idx,cols_cat}
%         case 'ALL global fireball events (may be several per day)'
%             sdb_Contacts.Category(end) = 'all';
%             sdb_Contacts.Radius_km(end) = max_radius_km;
%         
%         case 'Major events only'
%             sdb_Contacts.Category(end) = 'major';
%             sdb_Contacts.Radius_km(end) = radius_km;
%             
%         case 'Events near me (Provide radius below)'
%             sdb_Contacts.Category(end) = 'all';
%             sdb_Contacts.Radius_km(end) = radius_km;
%            
%         otherwise
%             error('Unexpected category!')
%     end
%     sdb_Contacts.Email(end) = cameradata{idx,cols_email};
%     
%     % Split first and last name
%     NAME = cameradata{idx,col_name};
%     ALTNAME = cameradata{idx,cols_email};
%     ALTNAME = ALTNAME(1:strfind(ALTNAME,'@')-1);
%     if isnan(NAME)
%         sdb_Contacts.FirstName(end) = ALTNAME;
%         sdb_Contacts.LastName(end) = "";
%     else
%         sdb_Contacts.FirstName(end) = NAME(1:(strfind(NAME,' ')-1));
%         sdb_Contacts.LastName(end) = NAME((strfind(NAME,' ')+1):end);
%     end
%     
%     % Resolve location
%     sdb_Contacts.Location(end) = validplace(cameradata{idx,cols_address},sdb_placenames,false);
%     [sdb_Contacts.LAT(end), sdb_Contacts.LONG(end) ] = getcoordinates(char(sdb_Contacts.Location(end)));
%         
%     sdb_Contacts.notify(end) = true;
%     
%     % Add to mailchimp mailing list
%     addmailchimp(sdb_Contacts.FirstName(end), sdb_Contacts.LastName(end), sdb_Contacts.Email(end));
% end
% db_end_idx = size(sdb_Contacts.TimeAdded,1);
% 
% if db_start_idx > db_end_idx
%     logformat('No new records found')
% else
%     openvar('sdb_Contacts')
%     if  db_end_idx == db_start_idx
%         logformat('1 new record imported')
%         logformat(['Please review record ' num2str(db_start_idx) '!'],'USER')
%     else
%         logformat([num2str(db_end_idx - db_start_idx + 1) ' new records imported.'])
%         logformat(['ACTION REQUIRED: Review records ' num2str(db_start_idx) ' to ' num2str(db_end_idx) '!'])        
%     end
%     
%     % Remind user to manually tag Mailchimp records
%     logformat('ACTION REQUIRED: Manually tag new records as ''StrewnNotify'': <a href = "https://www.mailchimp.com">Go to Mailchimp</a>','USER')
% 
% end



% Re-enable table warnings
warning ('on','MATLAB:table:RowsAddedExistingVars')

% Save Database
% save_database
logformat('Camera importing complete.','DATABASE')

% Stop logging
diary off


