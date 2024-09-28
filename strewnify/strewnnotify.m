% STREWNNOTIFY

logformat('Strewnify Meteor Event Notification service started.','INFO')

% Initialize session
import_ref_data
strewnconfig

% Load contacts from database
load('StrewnifyDatabase.mat','sdb_Contacts')

% Settings
devmode = false;
numdays = 15;
major_energythresh = 0.01; % estimated energy threshold in kilotons
earth_km = referenceEllipsoid('earth','km'); % all contacts currently live on Earth
email_subject = 'Strewnify Automated Meteor Report';

% Dev mode selection
switch devmode
    case false
        numrecipients = size(sdb_Contacts,1);
    case true
        numrecipients = 1;
    otherwise
        ErrorMsg = 'There was an error in STREWNNOTIFY, unknown devmode';
        logformat(ErrorMsg,'ERROR')        
end

% Attempt to retrieve meteor events and report any error to developer
try
    [NewEvents, attachment, numevents] = getnew(numdays);    
catch
    numevents = -1;
    ErrorMsg = 'There was an error in GETNEW, check code.';
    logformat(ErrorMsg,'ERROR');
end



if numevents > 0
    
    % TEMPORARY CODE
    NewEvents.ImpactEnergy_Est(:) = 1;
    
    for i = 1:numrecipients
        if sdb_Contacts.notify(i)

            % Time for log file
            nowstring = datestr(datetime('now','TimeZone',getSession('env','TimeZone')),'yyyy/mm/dd HH:MM PM');
            
            % Clear previous results
            emailcontent = '';
            if numevents > 0
                NewEvents.distance(:) = inf;
                NewEvents.azimuth(:) = NaN;
            end
            clear inradius
            clear major
            clear numevents_contact
            clear homelocation
            clear eventlocation

            % Set home location
            homelocation = [sdb_Contacts.LAT(i) sdb_Contacts.LONG(i)];

            % Calculate distance from home for user
            for n = 1:numevents
                eventlocation = [NewEvents.LAT(n) NewEvents.LONG(n)];
                [NewEvents.distance(n),NewEvents.azimuth(n)] = distance(homelocation,eventlocation,earth_km);
            end

            % Sort and get filters
            NewEvents = sortrows(NewEvents,'distance','ascend');
            inradius = NewEvents.distance < sdb_Contacts.Radius_km(i);
            major = NewEvents.ImpactEnergy_Est > major_energythresh;
            numevents_contact = numel(inradius(inradius));

            % Generate custom report for each contact
            if sdb_Contacts.Category(i) == 'admin'
                emailcontent = reportevents(NewEvents);
            elseif numevents_contact > 0
                if sdb_Contacts.Category(i) == 'all'
                    % if the entire earth is included, send events with no location
                    if sdb_Contacts.Radius_km > 20000
                        emailcontent = reportevents(NewEvents);
                    % otherwise send in-radius events only
                    else
                        emailcontent = reportevents(NewEvents(inradius,:));
                    end
                elseif sdb_Contacts.Category(i) == 'major'
                    emailcontent = reportevents(NewEvents(major & inradius,:));
                else
                    emailcontent = reportevents(NewEvents);
                    logformat(['Invalid notification category set for ' sdb_Contacts.FirstName{i} ' ' sdb_Contacts.LastName{i} '.'],'DEBUG')
                end
            end

            % If content was generated, send email
            if ~isempty(emailcontent)
                try   
                    if numevents_contact == 1
                        header = ['Hello ' sdb_Contacts.FirstName{i} ',' newline newline 'Since the last report, one meteor event has been added to the Strewnify database'];
                    else
                        header = ['Hello ' sdb_Contacts.FirstName{i} ',' newline newline 'Since the last report, ' num2str(numevents_contact) ' meteor events have been added to the Strewnify database'];
                    end
                    if sdb_Contacts.Radius_km(i) < 20000
                        header = [header ', within ' num2str(sdb_Contacts.Radius_km(i)) ' km of your home location in ' convertStringsToChars(sdb_Contacts.Location(i)) ];
                    end                   
                    emailcontent = [header ':' newline emailcontent];
                    
                    % Log email header
                    logformat(sprintf('Queuing email for %s %s: %s...',sdb_Contacts.FirstName{i}, sdb_Contacts.LastName{i}, replace(header,char(10),' ')),'INFO')
                    
                    % Send email to contact
                    strewnmail(emailcontent,sdb_Contacts.Email(i),email_subject,99)
                    
                catch
                    ErrorMsg = ['There was an error in sending mail to ' sdb_Contacts.FirstName{i} ' ' sdb_Contacts.LastName{i} ', check code.'];
                    logformat(ErrorMsg,'ERROR')                    
                end
            end
        end
    end
end

if devmode
    strewnmail('Development mode active!',getConfig('webmaster'),'StrewnLAB Dev Mode',1)    
end

% Save log file
logformat('Strewnify Meteor Event Notification service complete.')






