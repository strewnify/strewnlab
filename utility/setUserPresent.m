function setUserPresent(value)
%SETUSERPRESENT(VALUE) Set user presence to true or false

% Import reference data
global ref_session

% Check for missing initialization
if isempty(ref_session)      
    logformat('Session data not loaded, run IMPORT_REF_DATA.','ERROR')    
else
    switch value
        case true
            logformat('User is present at console.  Prompts may appear.','USER')
            ref_session.userpresent = true;
        case false
            logformat('User not present at console.  Prompts will be suppressed.','USER')
            ref_session.userpresent = false;
        otherwise
            logformat('User presence unknown.','ERROR')    
    end
end