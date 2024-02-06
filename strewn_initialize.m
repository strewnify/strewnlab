function strewn_initialize
% Initialize the workspace

global initialized

% if the variable is new, init to false
if isempty(initialized)
    initialized = false;
end

% Only initialize, if not done this session
if ~initialized

    logformat('StrewnLAB initializing...','INFO')
    
    % Initialize settings
    datetime.setDefaultFormats('defaultdate','yyyy-MM-dd HH:mm:ss');
          
    % Initialize globals
    % Load reference data
    import_ref_data

    % Initialize session data
    % Session data is generated for each new session
    
    
    if getSession('state','userpresent')
        quest = ['Please Select a User Role:' newline newline 'Standard - Effortless success with the usual settings' newline ...
            'Advanced - Extra choices for users with understanding of physics and statistics' newline ...
            'Developer - Does not enhance simulation results, additional credentials required for website administration' newline newline];
        roles = ["Standard","Advanced","Developer"];
        
        % Get user role, saving preferences to matlab preferences
        [user_role,~] = uigetpref('strewnlab_uigetpref','role_pref','Choose User Role',quest,roles);
            
    % otherwise, query the user
    else
        user_role = 'developer';
    end
    
    % *** Credential Loading ***
    % Check for saved credentials and load to environment
    % Environment variables are used at runtime security and faster access
    % Sensitive information like passwords and API keys are saved to a
    % preferences file called strewnlab_private, which is typically
    % located in this folder:
    % C:\Users\<username>\AppData\Roaming\MathWorks\MATLAB\R20xxx\
  
    % load private preferences
    strewnlab_private = getpref('strewnlab_private');
    
    % If no credentials found, query user
    if isempty(strewnlab_private) || isempty(fieldnames(strewnlab_private))
        get_creds = true;
        
        % Setup credential query, based on user role
        switch user_role
            case 'developer'
                creds = {'GoogleMapsAPIkey' 'AMS_APIkey' 'Mailchimp_APIkey' 'Strewnify_APIkey' 'strewnlab_emailpassword' 'GoogleDrive_NotifyResponses' 'GoogleDrive_Cameras'};
            case 'advanced'
                creds = {'GoogleMapsAPIkey'};
            otherwise
                get_creds = false;
        end
        
        % Query user for credentials
        if get_creds
           for cred_i = 1:numel(creds)
               [~] = getPrivate(creds{cred_i}); % save value, do not log
           end
        
        % Load the new preferences
        strewnlab_private = getpref('strewnlab_private');
        
        else
           logformat([user_role ' user skipped credential setup.'],'USER')
       end
    end
    
    % Save preference file variables to environment variables
    if isempty(strewnlab_private)
        logformat(['No credentials found at ' prefdir '\matlabprefs.mat.'],'WARN');
    else
        private_var = fieldnames(strewnlab_private);

        % Set environment variables
        for private_i = 1:numel(private_var)
            var_name = private_var{private_i};            
            var_value = strewnlab_private.(private_var{private_i}){1};
            setenv(var_name,var_value);        
            logformat([var_name ' loaded from ' prefdir '\matlabprefs.mat.'],'INFO')
        end        
    end
    
    % clear private preferences from workspace
    % (still loaded in system env variables)
    clear strewnlab_private

    % *** Credentials Loading Complete ***
        
    logformat('StrewnLAB initialization complete.','INFO')
    
    % Set initialization complete
    initialized = true;
end

