function setExporting(value)
%SETEXPORTING(VALUE) Set exporting state to true or false

% Exporting state is stored in state variables
group = 'state';
varname = 'exporting';

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
                logformat('Export in progress...','USER')
                ref_session.(group).(varname) = value;
            case false
                logformat('Export complete.','USER')
                ref_session.(group).(varname) = value;
            otherwise
                logformat('Exporting state unknown.','ERROR')    
        end
    end
end