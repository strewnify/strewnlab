% UNZIPDOWNLOADS Unzips manually downloaded weather files

import_ref_data

% disable downloads for future calls to get weather (assuming it failed already)
skipdownload = true

% Go to the downloads folder
cd(getSession('folders','downloads'));

for station = 1:size(EventData_IGRA_Nearby,1)
    ZipFileName = [EventData_IGRA_Nearby.StationID{station} '-data.txt.zip'];
    %ZipFileName = [EventData_IGRA_Nearby.StationID{station} '.zip'];
     
     try
        cd([getSession('folders','mainprefix') '\Downloads']);
        unzip(ZipFileName,getSession('folders','weatherfolder')); % unzip the file
        delete(ZipFileName); % delete the zip
     catch
         cd(getSession('folders','mainfolder'));
     end
end

% return to working directory
cd(getSession('folders','mainfolder')); 

clear effective_entrytime