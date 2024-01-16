function [private_data] = getPrivate(group, varname)
%GETPRIVATE Get user private data, like credentials, from saved 
% preferences.  If the requested variable has not been saved, the user
% will be queried to enter the information.  Private data is saved in the 
% strewnlab_private file, typically located in this folder:
% C:\Users\<username>\AppData\Roaming\MathWorks\MATLAB\R20xxx\
% To locate the preferences file, enter 'prefdir' in the command window

if nargin ~= 2
    logformat('Private data access requires group and variable name','ERROR')
end

% Check that private preferences are stored separately
if ~contains(group,'private','IgnoreCase',true)
    logformat('Private data inproperly stored. Debug code.','ERROR')
end

% default value is false
success = false;
dataavailable = false;

% If the private data is not available, get it from the user
if ~ispref(group, varname) || isempty(getpref(group, varname))
    
    switch varname
        case 'GoogleMapsAPIkey'
            
            dlg_title = 'Google Maps Setup';
            warn_quest = ['Google Maps API key not found. Some location services, like ground elevation, will force manual entry if Google Maps is unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://developers.google.com/maps/documentation/embed/get-api-key';
            getData_linkmsg = 'Use API Keys';
            getData_msg = 'for instructions on how to obtain a Google Maps API key';
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter Google Maps API key:';
            dlgtitle = 'Google Maps Services Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            log_msg = 'Google Maps API key entered by user.';
            
        case 'AMS_APIkey'
            dlg_title = 'AMS API Setup';
            warn_quest = ['AMS API key not found. Without setup, AMS data will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.amsmeteors.org/members/user/login';
            getData_linkmsg = 'AMS Members Area';
            getData_msg = 'to retrieve your API key';
            help_msg = ['Please visit the <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your AMS API key:';
            dlgtitle = 'AMS Data Services Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            log_msg = 'AMS API key entered by user.';
            
        case 'Mailchimp_APIkey'
            dlg_title = 'Mailchimp API Setup';
            warn_quest = ['Mailchimp API key not found. Without setup, Mailchimp services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://mailchimp.com/help/about-api-keys/';
            getData_linkmsg = 'Mailchimp API Keys';
            getData_msg = 'to retrieve your Mailchimp API key';
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Mailchimp API key:';
            dlgtitle = 'Mailchimp Setup';
            dims = [1 43];
            definput = {'Enter API key'};
            log_msg = 'Mailchimp API key entered by user.';
        case 'Strewnify_APIkey'
            dlg_title = 'Strewnify API Setup';
            warn_quest = ['Strewnify API key not found. Without setup, Strewnify web services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.strewnify.com/login';
            getData_linkmsg = 'Strewnify API Keys';
            getData_msg = 'to retrieve your Strewnify API key';
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Strewnify API key:';
            dlgtitle = 'Strewnify Setup';
            dims = [1 43];
            definput = {'Strewnify API key'};
            log_msg = 'Strewnify API key entered by user.';
            
        case 'strewnlab_emailpassword'
            dlg_title = 'StrewnLAB Email Setup';
            warn_quest = ['StrewnLAB email login not found. Without setup, email services will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://cpanel.strewnlab.com/';
            getData_linkmsg = 'StrewnLAB.com Email Login';
            getData_msg = 'to retrieve your StrewnLAB email login';
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your email password:';
            dlgtitle = 'Email Setup';
            dims = [1 43];
            definput = {'Enter email password'};
            log_msg = 'Email password entered by user.';
            
        case 'GoogleDrive_NotifyResponses'
            dlg_title = 'StrewnNotify Setup';
            warn_quest = ['Google Forms URL not found. Without setup, contact import will be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter URL','Skip'};
            
            getData_URL = 'https://docs.google.com/forms/';
            getData_linkmsg = 'Strewn Notify Setup';
            getData_msg = 'to retrieve your URL';
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = 'Enter your Google Drive URL:';
            dlgtitle = 'Email Setup';
            dims = [1 100];
            definput = {'Enter Google Drive URL'};
            log_msg = 'Google Forms URL entered by user.';
            
        otherwise
            dlg_title = [ varname ' Setup'];
            warn_quest = [varname ' not found. Without setup, features may be unavailable.' newline ...
                'Would you like to set it up now?'];
            pbtns = {'Enter Credentials','Skip'};
            
            getData_URL = 'https://www.strewnify.com/';
            getData_linkmsg = [varname 'Credential'];
            getData_msg = ['to retrieve your ' varname ' credential'];
            help_msg = ['Please visit <a href = "' getData_URL '">' getData_linkmsg '</a> ' getData_msg '.'];
            prompt = ['Enter your ' varname ' credential:'];
            dlgtitle = [varname ' Setup'];
            dims = [1 43];
            definput = {['Enter ' varname ' credential' ]};
            log_msg = [ varname 'credential entered by user.'];
            
    end

    % Query the user to load credentials
    varname_pref = [varname '_pref']; % variable name for uigetpref preferences
    [user_selection,dlg_opened] = uigetpref('strewnlab',varname_pref,dlg_title,warn_quest,pbtns);
    
    switch user_selection
        case lower(pbtns{1})

            % Display a link in the command window for help
            disp(help_msg)
            
            % Prompt the user to enter the data
            opts.WindowStyle = 'normal';
            setpref(group, varname, inputdlg(prompt,dlgtitle,dims,definput,opts));
            
            % Check for invalid entry
            saved_pref = getpref(group, varname); 
            if isempty(saved_pref) || isempty(saved_pref{1}) || strcmp(saved_pref{1},definput)
                rmpref(group, varname); % remove bad entry
                logformat(['Invalid entry in ' varname '.'],'ERROR');
            else
                logformat(log_msg,'USER');
                success = true;
                dataavailable = true;
            end
            
        case 'skip'
            % do nothing 
            
        otherwise
            logformat('Unknown preference selection.','ERROR')
    end
    
    % Display a message to the user
    if success
        logformat([varname 'data saved to ' prefdir],'USER')
    else
        logformat([varname ' not set by user.'],'WARN')
    end

else
    dataavailable = true;
end

 % Get the user preference data
 if dataavailable
     private_data = getpref(group,varname);
     
     % Check data format and extract from cell
     if isempty(private_data) || numel(private_data) > 1
         logformat(['Invalid ' varname ' private data stored in ' prefdir '\matlabprefs.mat'],'ERROR')
         private_data = [];
     else
         private_data = private_data{1};
     end     
 else
     logformat(['User skipped data entry for ' varname '.'],'USER')
     private_data = [];
 end


