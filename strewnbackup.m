% STREWNBACKUP Backup the StrewnLAB simulation in progress.

% Update file and folder names
syncevent

backup_filename = [SimulationName '_StrewnLAB' SimVersionSfx '.mat'];
backup_filename_old = [SimulationName '_StrewnLAB' SimVersionSfx '_old.mat'];

% Check that an event has been loaded
if exist('check_eventdataloaded','var')==1 && check_eventdataloaded

    % change directory
    cd(exportfolder)

     try
        % Rename the old file
        if exist(backup_filename,'file')==2
            
            % delete the old file
            if exist(backup_filename_old,'file')==2
                delete(backup_filename_old)
            end
            
            % rename the existing file
            movefile(backup_filename,backup_filename_old,'f');
        end
        
        % export the workspace
        save([SimulationName '_StrewnLAB' SimVersionSfx]);
        %pngfilestring = [SimulationName '_StrewnField_' datestr(nowtime,'yyyymmdd_HHMMSS') '.png'];

        % return to main folder
        cd(mainfolder)
        
        disp(['Workspace backed up to ' newline exportfolder])
     
     catch
        % return to main folder
        cd(mainfolder)
        warning('Error in simulation data backup operation.');
     end
    
    
    % Save EventData (including finds)
    % if the file does not exist, create it
    cd(eventfolder);
    if exist(SimFilename,'file') ~= 2
        save(SimFilename,'EventData_*')
    else
        save(SimFilename,'EventData_*','-append')
    end
    cd(mainfolder);

else
    error('STREWNBACKUP called, but no simulation loaded')
end