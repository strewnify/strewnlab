function [data_out] = getSession(group,varname)
%GETSESSION Get session data from global struct variable

% Import reference data
global ref_session

% Check for missing initialization
if isempty(ref_session)      
    logformat('Session data not loaded, run IMPORT_REF_DATA.','ERROR')    
else

    % Store output
    if nargin == 0
        data_out = ref_session;
    else
        data_out = ref_session.(group).(varname);
    end
end