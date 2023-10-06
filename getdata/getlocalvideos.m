function [tb_filedata] = getlocalvideos(rootdir)
% GETLOCALVIDEOS Scan local events folder for videos and summarize
% [tb_videodata] = getlocalvideos(rootdir)
% Scans the root directory and all subfolders and generates a summary table
% of all video files

% Accepted file types
filetypes = {'.mp4' '.mov' '.wmv' '.avi' '.avchd' '.flv' '.f4v' '.swf' '.mkv'};

% Get list of files and folders in any subfolder
filelist = dir(fullfile(rootdir, '**\*.*'));
filelist = filelist(~[filelist.isdir]); 
tb_filedata = struct2table(filelist);
tb_filedata = tb_filedata(contains(tb_filedata.name,filetypes),:);

% Set timestamps
nowtime_utc = datetime('now','TimeZone','UTC');
tb_filedata.DateAccessed(:) = nowtime_utc;

% Hash Data 
for file_i = 1:size(tb_filedata,1)
    tb_filedata.Hash(file_i) = {DataHash( [tb_filedata.folder{file_i} '\' tb_filedata.name{file_i}], 'MD5', 'hex', 'file')};
end