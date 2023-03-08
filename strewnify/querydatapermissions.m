% QUERYDATAPERMISSIONS
% Query the user for data export permissions

clear permission_filter
clear Permissions
clear DataPermissionsTitle
clear DataPermissionsFilename
clear DataPermissions

% Create a list of permission levels
FinderNames = unique(EventData_Finds.Finder(EventData_Finds.CONFIDENTIAL)); %list of finders with confidential finds
DataPermissionLevels = ["Public";"Full Access"; FinderNames];

% Query user to select permissions
[DataPermissions,usercontinue] = listdlg('ListString',DataPermissionLevels,'Name','CONFIDENTIAL Data Permissions','ListSize',[350 160],'InitialValue',2,'PromptString','Choose data access level (you may select multiple)','OKString','Continue');
Permissions = DataPermissionLevels(DataPermissions);

% If the user selects 'Cancel', exit with error
if ~usercontinue
    error('No data permission selection made.')
end

% Assign filter, based on selected permissions
if numel(DataPermissions) == 1 && DataPermissions == 1  %Public Access
        permission_filter = ~EventData_Finds.CONFIDENTIAL;
elseif numel(DataPermissions) == 1 && DataPermissions == 2  %Full Access
        permission_filter = EventData_Finds.CONFIDENTIAL | ~EventData_Finds.CONFIDENTIAL;
elseif ismember(1,DataPermissions) || ismember(2,DataPermissions) % user selected group and individual permissions
    error('Invalid permission selection.  Select either group or individual permissions.')
else
        permission_filter = ~EventData_Finds.CONFIDENTIAL | ismember(EventData_Finds.Finder,DataPermissionLevels(DataPermissions));
end

% Create labels for data permissions
DataPermissionsTitle = convertStringsToChars(strcat("Data Permissions: ", DataPermissionLevels(DataPermissions(1))));
DataPermissionsFilename = convertStringsToChars(matlab.lang.makeValidName(strcat("CONFIDENTIAL_",DataPermissionLevels(DataPermissions(1))),'ReplacementStyle','delete'));
if numel(DataPermissionLevels(DataPermissions)) > 1
    for idx = 2:numel(DataPermissionLevels(DataPermissions))
        DataPermissionsTitle = convertStringsToChars(strcat(DataPermissionsTitle, ", ", DataPermissionLevels(DataPermissions(idx))));
        DataPermissionsFilename = convertStringsToChars(strcat(DataPermissionsFilename, "_",  matlab.lang.makeValidName(DataPermissionLevels(DataPermissions(idx)),'ReplacementStyle','delete')));
    end
end