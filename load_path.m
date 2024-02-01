function [main_path] = getmainpath(install_folder)
% LOAD_PATH Get the path of the install folder and 

% Get the full path of this function file
full_path = mfilename('fullpath');

% Get the root directory
root_path = extractBefore(full_path,install_folder);

% Re-assemble the path
main_path = [root_path install_folder];

end

