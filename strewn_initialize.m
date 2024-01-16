function strewn_initialize
% Initialize the  workspace

global initialized 

% if the variable is new, init to false
if isempty(initialized)
    initialized = false;
end

% Only initialize, if not done this session
if ~initialized
    
    logformat('StrewnLAB initializing...','INFO')
    
    ellipsoid_unit = 'meters';

    % Initialize settings
    datetime.setDefaultFormats('defaultdate','yyyy-MM-dd HH:mm:ss');
          
    % Initialize globals
    % Load reference data
    global ref_data
    global ref_planet
    global ref_config
    ref_data = load('ref_data.mat');
    ref_planet = load('earth_data.mat');
    ref_config = load('ref_config.mat');
    
    % Calculate derived planet data
    ref_planet.ellipsoid_m = referenceEllipsoid('earth',ellipsoid_unit);  % reference ellipsoid used by mapping/aerospace tools, DO NOT CHANGE units
    ref_planet.angular_vel_rps = 2 * pi / ref_planet.sidereal_period_s;
    logformat(['Planet initialized to Earth.  Ellipsoid units are in ' ellipsoid_unit '.'],'INFO')

    % If user is not present
    if exist('userpresent') && ~userpresent
        user_role = 'developer';
    
    % otherwise, query the user
    else
        quest = ['Please Select a User Role:' newline newline 'Standard - Effortless success with the usual settings' newline ...
            'Advanced - Extra choices for users with understanding of physics and statistics' newline ...
            'Developer - Does not enhance simulation results, additional credentials required for website administration' newline newline];
        roles = ["Standard","Advanced","Developer"];
        [user_role,~] = uigetpref('strewnlab','role_pref','Choose User Role',quest,roles);
    end
    
    % *** Credential Loading ***
    % Check for saved credentials and load to environment
    % Environment variables are used at runtime security and faster access
    % Sensitive information like passwords and API keys are saved to a
    % preferences file called strewnlab_private, which is typically
    % located in this folder:
    % C:\Users\<username>\AppData\Roaming\MathWorks\MATLAB\R20xxx\
  
    % load private preferences
    pref_private = 'strewnlab_private';
    strewnlab_private = getpref(pref_private);
    
    % If no credentials found, query user
    if isempty(strewnlab_private) || isempty(fieldnames(strewnlab_private))
        get_creds = true;
        
        % Setup credential query, based on user role
        switch user_role
            case 'developer'
                quest = ["User credentials have not been set up.  Would you like to enter them now?"];
                user_cred = ["Enter Credentials","Skip"];
                creds = {'GoogleMapsAPIkey' 'AMS_APIkey' 'Mailchimp_APIkey' 'Strewnify_APIkey' 'strewnlab_emailpassword' 'GoogleDrive_NotifyResponses' 'Timezone_API_token'};
            case 'advanced'
                quest = ["Advanced users are recommended to setup API credentials.  Proceed?"];
                user_cred = ["Proceed","Skip"];
                creds = {'GoogleMapsAPIkey'};
            otherwise
                get_creds = false;
        end
        
        % Query user for credentials
        if get_creds
           for cred_i = 1:numel(creds)
               [~,success] = getPrivate(pref_private,creds{cred_i}); % save value, do not log
           end
        
        % Sace the new preferences
        strewnlab_private = getpref(pref_private);
        
        else
           success = false;
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
            logformat([var_name 'loaded from ' prefdir '\matlabprefs.mat.'],'INFO')
        end
        clear private_pref
    end

    % *** Credentials Loading Complete ***
        
    logformat('StrewnLAB initialization complete.','INFO')
    
    % Set initialization complete
    initialized = true;
end

