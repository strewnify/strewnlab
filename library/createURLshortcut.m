function createURLshortcut(url, folderPath, filename)
    % Ensure the folder path ends with a file separator
    if ~endsWith(folderPath, filesep)
        folderPath = [folderPath, filesep];
    end
    
    % Create the full file path
    fullPath = fullfile(folderPath, filename);
    
    % Check if the filename has the correct extension
    if ~endsWith(fullPath, '.url')
        fullPath = [fullPath, '.url'];
    end

    % Open the file for writing
    fileID = fopen(fullPath, 'w');
    
    % Check if the file opened successfully
    if fileID == -1
        error('Could not open file for writing: %s', fullPath);
    end
    
    % Write the .url file format
    fprintf(fileID, '[InternetShortcut]\n');
    fprintf(fileID, 'URL=%s\n', url);
    
    % Close the file
    fclose(fileID);
    
    % Confirmation message
    fprintf('URL file created successfully: %s\n', fullPath);
end
