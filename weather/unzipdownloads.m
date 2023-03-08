% UNZIPDOWNLOADS Unzips manually downloaded weather files

% disable downloads for future calls to get weather (assuming it failed already)
skipdownload = true

% Go to the downloads folder
cd([mainprefix '\Downloads']);

for station = 1:size(EventData_IGRA_Nearby,1)
    ZipFileName = [EventData_IGRA_Nearby.StationID{station} '-data.txt.zip'];
    %ZipFileName = [EventData_IGRA_Nearby.StationID{station} '.zip'];
     
     try
        cd([mainprefix '\Downloads']);
        unzip(ZipFileName,weatherfolder); % unzip the file
        delete(ZipFileName); % delete the zip
     catch
         cd(mainfolder);
     end
end

% return to working directory
cd(mainfolder); 
