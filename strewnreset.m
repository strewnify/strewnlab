% STREWNRESET Reset StrewnLAB preferences

logformat('User requested StrewnLAB preferences reset','USER')

% Initialize preferences to false
rm_strewnlab = false;
rm_strewnlab_uigetpref = false;
rm_strewnlab_private = false;

switch questdlg("StrewnLAB Preferences Reset Requested!  Session data will be lost and StrewnLAB preferences will be reset to factory defaults!","Choose Reset Type","Preferences","Preferences & Private Keys","Cancel","Cancel");

    case 'Preferences'
        logformat('User selected to reset ''Preferences''','USER')
        rm_strewnlab = true;
        rm_strewnlab_uigetpref = true;
                
    case 'Preferences & Private Keys'
        logformat('User selected to reset ''Preferences & Private Keys''','USER')
        rm_strewnlab = true;
        rm_strewnlab_uigetpref = true;
        rm_strewnlab_private = true;
                
    otherwise
        logformat('User cancelled reset.  No changes made.','INFO')
end

% If Selected, Reset Preferences
if rm_strewnlab
    if ispref('strewnlab')
        rmpref('strewnlab') % preferences
        logformat('StrewnLAB preferences group ''strewnlab'' reset!','INFO')
    else
        logformat('Preferences group ''strewnlab'' not found.','WARN')
    end
end

% If Selected, Reset uigetpref Preferences
if rm_strewnlab_uigetpref
    if ispref('strewnlab_uigetpref')
        rmpref('strewnlab_uigetpref')
        logformat('StrewnLAB preferences group ''strewnlab_uigetpref'' reset!','INFO')
    else
        logformat('Preferences group ''strewnlab_uigetpref'' not found.','WARN')
    end
end

% If Selected, Reset Private Keys
if rm_strewnlab_private
    if ispref('strewnlab_private')
        rmpref('strewnlab_private')
        logformat('StrewnLAB preferences group ''strewnlab_private'' reset!','INFO')
    else
        logformat('Preferences group ''strewnlab_private'' not found.','WARN')
    end
end

if rm_strewnlab || rm_strewnlab_uigetpref || rm_strewnlab_private
    clear
    clear global
    import_ref_data
else
    clear rm_*
end
