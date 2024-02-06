function [main_path] = getinstallpath(install_foldername)
%GETINSTALLPATH Returns the full path of the installation directory

% Get the full path of this function file
full_path = mfilename('fullpath');

% Get the root directory
root_path = extractBefore(full_path,install_foldername);

% If the install folder is not found, error
if isempty(root_path)
    logformat(['Install folder ''' install_foldername ''' not found.'],'ERROR')
end

% Re-assemble the path
main_path = [root_path install_foldername];

end

