function setUserPresent(value)
%SETUSERPRESENT(VALUE) Set user presence to true or false

% The struct group where userpresent is stored
group = 'state';
varname = 'userpresent';

% Initialize global variable
% Don't overwrite userpresent value!
global ref_session
if isempty(ref_session)
    ref_session = struct;
end

% Check for undefined value
if isfield(ref_session,group) && isfield(ref_session.(group),varname) && value == ref_session.(group).(varname)
    % do nothing, if desired value is already set
    logformat(sprintf('Requested unnecessary change to global: ref_session.%s.%s = %s',group, varname, mat2str(value)),'DEBUG') 
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
