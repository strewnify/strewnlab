function [private_data, success] = getPrivate(group, varname)
%GETPRIVATE Get user private data, like credentials, from saved 
% preferences.  If the requested variable has not been saved, the user
% will be queried to enter the information.  Private data is saved in the 
% strewnlab_private filem typically located in this folder:
% C:\Users\<username>\AppData\Roaming\MathWorks\MATLAB\R20xxx\
% To locate the preferences file, enter 'prefdir' in the command window

% default value is false
success = false;

% If the private data is not available, get it from the user
if ~ispref(group, varname) || isempty(getpref(group, varname))
    
    dataavailable = false;
    
    switch varname
        case 'GoogleMapsAPIkey'
            
            dlg_title = 'Google Maps Setup';
            warn_quest = ['Google Maps API key not found. Some location services, like ground elevation, will force manual entry if Google Maps is unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://developers.google.com/maps/documentation/embed/get-api-key';
            getData_linkmsg = 'Use API Keys';
            getData_msg = 'for instructions on how to obtain a Google Maps API key';
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter Google Maps API key:';
            dlgtitle = 'Google Maps Services Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            logmsg = 'Google Maps API key entered by user.';
            
        case 'AMS_APIkey'
            dlg_title = 'AMS API Setup';
            warn_quest = ['AMS API key not found. Without setup, AMS data will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.amsmeteors.org/members/user/login';
            getData_linkmsg = 'AMS Members Area';
            getData_msg = 'to retrieve your API key';
            log_msg = ['Please visit the <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your AMS API key:';
            dlgtitle = 'AMS Data Services Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            logmsg = 'AMS API key entered by user.';
            
        case 'Mailchimp_APIkey'
            dlg_title = 'Mailchimp API Setup';
            warn_quest = ['Mailchimp API key not found. Without setup, Mailchimp services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://mailchimp.com/help/about-api-keys/';
            getData_linkmsg = 'Mailchimp API Keys';
            getData_msg = 'to retrieve your Mailchimp API key';
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Mailchimp API key:';
            dlgtitle = 'Mailchimp Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            logmsg = 'Mailchimp API key entered by user.';
        case 'Strewnify_APIkey'
            dlg_title = 'Strewnify API Setup';
            warn_quest = ['Strewnify API key not found. Without setup, Strewnify web services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.strewnify.com/login';
            getData_linkmsg = 'Strewnify API Keys';
            getData_msg = 'to retrieve your Strewnify API key';
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Strewnify API key:';
            dlgtitle = 'Mailchimp Setup';
            dims = [1 43];
            definput = {'Strewnify API key'};
            logmsg = 'Strewnify API key entered by user.';
            
        case 'strewnlab_emailpassword'
            dlg_title = 'StrewnLAB Email Setup';
            warn_quest = ['StrewnLAB email login not found. Without setup, email services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://cpanel.strewnlab.com/';
            getData_linkmsg = 'StrewnLAB.com Email Login';
            getData_msg = 'to retrieve your StrewnLAB email login';
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your email password:';
            dlgtitle = 'Email Setup';
            dims = [1 43];
            definput = {'Enter email password'};
            logmsg = 'Email password entered by user.';
            
        case 'GoogleDrive_NotifyResponses'
            dlg_title = 'StrewnNotify Setup';
            warn_quest = ['Google Forms URL not found. Without setup, contact import will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter URL','Skip'};
            
            getData_URL = 'https://cpanel.strewnlab.com/';
            getData_linkmsg = 'StrewnLAB.com Email Login';
            getData_msg = 'to retrieve your URL';
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Google Drive URL:';
            dlgtitle = 'Email Setup';
            dims = [1 43];
            definput = {'Enter Google Drive URL'};
            logmsg = 'Google Forms URL entered by user.';
            
        otherwise
            dlg_title = [ varname ' Setup'];
            warn_quest = [varname ' not found. Without setup, features may be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.strewnify.com/';
            getData_linkmsg = [varname 'Credential'];
            getData_msg = ['to retrieve your ' varname ' credential'];
            log_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = ['Enter your ' varname ' credential:'];
            dlgtitle = [varname ' Setup'];
            dims = [1 43];
            definput = {['Enter ' varname ' credential' ]};
            logmsg = [ varname 'credential entered by user.'];
            
    end

    % Query the user to load credentials
    [user_selection,~] = uigetpref('strewnlab',varname,dlg_title,warn_quest,pbtns);
    
    switch user_selection
        case lower(pbtns{1})

            % Prompt the user to enter the data
            setpref(group, varname, inputdlg(prompt,dlgtitle,dims,definput));
            
            % Check for invalid entry
            saved_pref = getpref(group, varname); 
            if isempty(saved_pref{1}) || strcmp(saved_pref{1},definput)
                    rmpref(group, varname); % remove bad entry
                    logformat(['Invalid entry in ' varname '.'],'ERROR');                    
            else
                    dataavailable = true;
            end
            
        case 'skip'
            % do nothing
            
        otherwise
            logformat('Unknown preference selection.','ERROR')
    end
    
    % Display a message to the user
    if success
        logformat(logmsg,'USER')
    else
        logformat([varname ' not set by user.'],'WARN')
    end

else
    dataavailable = true;
end

 % Get the user preference data
 if dataavailable
     private_data = getpref(group,varname);
     success = true;
 else
     logformat(['User skipped data entry for ' varname '.'],'USER')
     private_data = -1;
 end


