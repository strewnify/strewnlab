% function [newcontacts] = importcontacts()
%IMPORTCONTACTS  Import contact data from file.
%   IMPORTCONTACTS allows the user to select a CSV file and import contact
%   data into the Strewnify Database

% Load settings
strewnconfig
min_radius_km = 200; % minimum allowed search radius
max_radius_km = getPlanet('ellipsoid_m').MeanRadius*2*pi/2/1000;
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
    websave(FILENAME,['https://docs.google.com/spreadsheet/ccc?key=' getPrivate('GoogleDrive_NotifyResponses') '&output=csv&pref=1'],weboptions);
    dateFormat = 'MM/dd/yyyy h:mm:SS aa';
    cd(getSession('folders','mainfolder'))
    logformat(sprintf('%s retrieved from Google Drive',FILENAME),'INFO')

catch
    cd(getSession('folders','mainfolder'))
    logformat('Google Drive download failed, manual file download required.','DEBUG')
    
    % Import the contact file
    [FILENAME, PATHNAME, FILTERINDEX] = uigetfile({'*.csv;*.xls;*.xlsx'});
    if FILTERINDEX == 0
        error('No file selected for import.')
    end
    dateFormat = 'yyyy/MM/dd h:mm:SS aa z';
end

% import the data
[~,~,contactdata] = xlsread([PATHNAME FILENAME]);

% Start logging
diary([getSession('folders','logfolder') '\strewnnotify_log.txt'])        
diary on 
logformat(sprintf('Importing contacts from %s',FILENAME),'INFO')

% Map import data columns
col_time = 1;
col_email = 2;
col_name = 3;
col_loc = 4;
col_cat = 5;
col_rad = 6;
col_sugg = 7;

% Prepare for import, find latest entry
importsize = size(contactdata,1);
db_start_idx = size(sdb_Contacts.TimeAdded,1) + 1;

% Find the first import entry newer than the last database entry
start_idx = find((datetime(contactdata(:,col_time),'InputFormat',dateFormat,'TimeZone','UTC') > sdb_Contacts.TimeAdded(end)) == true,1);
if isempty(start_idx)
    start_idx = size(contactdata,1) + 1;
end

for idx = start_idx:importsize
    import_email = contactdata{idx,col_email};
    matchcnt = size(find(strcmp(sdb_Contacts.Email,import_email)),1);
    if matchcnt > 0
        warning([import_email ' already exists in database, adding duplicate record.'])
    end
    
    % Convert radius
    if isnan(contactdata{idx,col_rad})
        radius_km = max_radius_km;
    else
        radius_km = min(max(min_radius_km, contactdata{idx,col_rad}),max_radius_km); % clip search radius between min and max
    end
    
    % Add record
    sdb_Contacts.TimeAdded(end+1) = nowtime_utc;
    switch contactdata{idx,col_cat}
        case 'ALL global fireball events (may be several per day)'
            sdb_Contacts.Category(end) = 'all';
            sdb_Contacts.Radius_km(end) = max_radius_km;
        
        case 'Major events only'
            sdb_Contacts.Category(end) = 'major';
            sdb_Contacts.Radius_km(end) = radius_km;
            
        case 'Events near me (Provide radius below)'
            sdb_Contacts.Category(end) = 'all';
            sdb_Contacts.Radius_km(end) = radius_km;
           
        otherwise
            error('Unexpected category!')
    end
    sdb_Contacts.Email(end) = contactdata{idx,col_email};
    
    % Split first and last name
    NAME = contactdata{idx,col_name};
    ALTNAME = contactdata{idx,col_email};
    ALTNAME = ALTNAME(1:strfind(ALTNAME,'@')-1);
    if isnan(NAME)
        sdb_Contacts.FirstName(end) = ALTNAME;
        sdb_Contacts.LastName(end) = "";
    else
        sdb_Contacts.FirstName(end) = NAME(1:(strfind(NAME,' ')-1));
        sdb_Contacts.LastName(end) = NAME((strfind(NAME,' ')+1):end);
    end
    
    % Resolve location
    sdb_Contacts.Location(end) = validplace(contactdata{idx,col_loc},sdb_placenames,false);
    [sdb_Contacts.LAT(end), sdb_Contacts.LONG(end) ] = getcoordinates(char(sdb_Contacts.Location(end)));
        
    sdb_Contacts.notify(end) = true;
    
    % Add to mailchimp mailing list
    addmailchimp(sdb_Contacts.FirstName(end), sdb_Contacts.LastName(end), sdb_Contacts.Email(end));
end
db_end_idx = size(sdb_Contacts.TimeAdded,1);

if db_start_idx > db_end_idx
    logformat('No new records found')
else
    openvar('sdb_Contacts')
    if  db_end_idx == db_start_idx
        logformat('1 new record imported')
        logformat(['Please review record ' num2str(db_start_idx) '!'],'USER')
    else
        logformat([num2str(db_end_idx - db_start_idx + 1) ' new records imported.'])
        logformat(['ACTION REQUIRED: Review records ' num2str(db_start_idx) ' to ' num2str(db_end_idx) '!'])        
    end
    
    % Remind user to manually tag Mailchimp records
    logformat('ACTION SUGGESTED: Verify new records are tagged as ''StrewnNotify'': <a href = "https://www.mailchimp.com">Go to Mailchimp</a>','USER')

end



% Re-enable table warnings
warning ('on','MATLAB:table:RowsAddedExistingVars')

% Save Database
save_database
logformat('Contact importing complete.','DATABASE')

% Stop logging
diary off


