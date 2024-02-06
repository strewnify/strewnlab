function setUserPresent(value)
%SETUSERPRESENT(VALUE) Set user presence to true or false

% The struct group where userpresent is stored
group = 'state';
varname = 'userpresent';

% Import reference data
global ref_session

% Check for missing initialization
if isempty(ref_session)      
    logformat('Session data not loaded, run IMPORT_REF_DATA.','ERROR')    
else
    if value == ref_session.(group).(varname)
        % do nothing, if desired value is already set
        logformat(sprintf('Requested unnecessary change to global: ref_session.%s.%s',group, varname),'DEBUG') 
    else
        switch value
            case true
                logformat('User is present at console.  Prompts may appear.','USER')
                ref_session.(group).(varname) = value;
            case false
                logformat('User not present at console.  Prompts will be suppressed.','USER')
                ref_session.(group).(varname) = value;
            otherwise
                logformat('User presence unknown.','ERROR')    
        end
    end
end