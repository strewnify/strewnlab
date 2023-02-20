function [localpath] = ftpsave(filename,URL)
%FTPSAVE Downloads files from an FTP server

% Parse URL
split1 = strsplit(URL,'/');
serverURL = split1{2};
remotepath = char;
for idx = 3:numel(split1)-1
    remotepath = [remotepath split1{idx} '/'];
end

% Get file
obj = ftp(serverURL);
cd(obj, remotepath);
localpath  = mget(obj, filename);
close(obj);

end

