% SYNCEVENT updates simulation name variables and creates folders, if necessary

% Initialize simulation name history
if exist('SimulationName_OLD','var') == 0
    SimulationName_OLD = {};
end

% Assign data permissions, if exporting
if ~exist('Permissions','var') || getSession('state','exporting')
    querydatapermissions
end

% Create a default filename, without special characters
SimFilename = matlab.lang.makeValidName(SimulationName,'ReplacementStyle','delete');

% Check if the event is CONFIDENTIAL
if CONFIDENTIAL
    eventfolder = getSession('folders','secreteventsfolder');
else
    eventfolder = getSession('folders','meteoreventsfolder');
end

% Check for existing folder
switch size(dir([eventfolder '\' SimEventID '*']),1)
    
    % if the event id is not in the directory, create a new folder
    case 0
        eventfolder = [eventfolder '\' SimEventID '_' SimFilename];
        mkdir(eventfolder) % create folder
        foldercreated = true;
        
    % if there is a single folder with matching ID, use the existing name
    case 1
        foldercreated = false;
        SimulationNameExisting = dir([eventfolder '\' SimEventID '*']).name((numel(SimEventID)+2):end);
        if ~strcmp(SimulationNameExisting,SimulationName)
            SimulationName_OLD(size(SimulationName_OLD,1)+1,1) = {SimulationName};
            SimulationName = SimulationNameExisting;
        end
        eventfolder = [eventfolder '\' SimEventID '_' SimulationName];
    
    % if multiple folders exist for the Event ID, exit with error
    otherwise
        logformat(['In directory, ' eventfolder ', duplicate subfolders exist with the name ' SimEventID '*.  Resolve invalid folder structure before restarting.'],'ERROR'); 
end

% Get a version number from the user
if ~exist('SimVersion','var')
    SimVersion = input('Enter version number: ','s');
end

% Create a filename version suffix, replacing periods with 'p' and whitespace with '_'
SimVersionSfx = ['_V' SimVersion];
SimVersionSfx = regexprep(SimVersionSfx,'\.','p');
SimVersionSfx = regexprep(SimVersionSfx,'\s*','_');

% Update file and folder names, in case they changed above
SimFilename = matlab.lang.makeValidName(SimulationName,'ReplacementStyle','delete');
exportfoldername = [SimFilename '_StrewnLAB_' getSession('user','export_username') '_export' SimVersionSfx];
exportfolder = [eventfolder '\' exportfoldername];

% create an export subfolder in the event folder
if ~(exist(exportfolder)==7)
    mkdir(eventfolder,exportfoldername);
end

% not a CONFIDENTIAL event, but secret finds exist, create a CONFIDENTIAL folder
if ~CONFIDENTIAL && exist('EventData_Finds','var') && ~(numel(Permissions) == 1 && Permissions == "Public") && size(dir([getSession('folders','secreteventsfolder') '\' SimEventID '*']),1) == 0
    mkdir([getSession('folders','secreteventsfolder') '\' SimEventID '_' SimFilename '_CONFIDENTIAL'])
end