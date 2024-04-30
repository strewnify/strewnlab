% STREWNBACKUP Backup the StrewnLAB simulation in progress.

diary([getSession('folders','logfolder') '\strewnlab_log.txt'])    
diary on
clc
SimMonitor
logformat('Simulation interrupted. Saving progress...','INFO')

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
        cd(getSession('folders','mainfolder'))
        
        logformat(['Workspace backed up to ' newline exportfolder],'INFO')
     
     catch
        % return to main folder
        cd(getSession('folders','mainfolder'))
        logformat('Error in simulation data backup operation.','WARN');
     end
    
    
    % Save EventData (including finds)
    % if the file does not exist, create it
    cd(eventfolder);
    if exist(SimFilename,'file') ~= 2
        save(SimFilename,'EventData_*')
    else
        save(SimFilename,'EventData_*','-append')
    end
    cd(getSession('folders','mainfolder'));

else
    logformat('STREWNBACKUP called, but no simulation loaded','ERROR')
end
