if ~exist('dupreviewed','var') || dupreviewed == false
    dupreviewed = false;
    
    % Check for duplicates and manually review
    % Took resolve duplicates, a random character is added to one of the StationIDs
    supported_char = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'; 
    num_dupl = inf;
    while num_dupl > 0
        [x, diff_i] = unique(sdb_Sensors.StationID, 'stable');
        duplicate_indices = setdiff( 1:size(sdb_Sensors,1), diff_i);
        duplicate_IDs = sdb_Sensors.StationID(duplicate_indices);
        num_dupl = numel(duplicate_IDs);
        delete_rows = []; % row indices to delete

        for dup_i = 1:numel(duplicate_IDs)
            row_indices = find(strcmp(sdb_Sensors.StationID,duplicate_IDs(dup_i)));
            row_indices = row_indices(1:2);
            
            % Display the first 2 duplicates
            disp_duplicates = sdb_Sensors(row_indices,:);
            disp_duplicates.Choose = ['A';'B'];
            disp_duplicates = movevars(disp_duplicates,'Choose','Before','StationID')
                        
            % Query the user 
            if getSession('state','userpresent')
                answer = questdlg('Choose which entry to keep.  If Keep Both is selected, Station B will be renamed.','Resolve Duplicates','Keep A','Keep B','Keep Both','Keep Both');
                                
            % If the user is not present, keep both entries
            else
                answer = 'Keep Both';
            end
            
            switch answer
                    case 'Keep A'
                        logformat(sprintf('StationID %s: User selected to ''Keep A'' (row %g).  Row %g will be DELETED.',duplicate_IDs{dup_i}, row_indices(1), row_indices(2)),'USER')
                        delete_rows(end+1) = row_indices(2);
                        % delete
                    case 'Keep B'
                        logformat(sprintf('StationID %s: User selected to ''Keep B'' (row %g).  Row %g will be DELETED.',duplicate_IDs{dup_i}, row_indices(2), row_indices(1)),'USER')
                        delete_rows(end+1) = row_indices(1);
                        % delete                        
                    case 'Keep Both'
                        logformat(sprintf('StationID %s: User selected to ''Keep Both'' (rows %g & %g).',duplicate_IDs{dup_i}, row_indices(1), row_indices(2)),'USER')                                                            
                        
                        % Prompt user for new StationID name
                        logformat(sprintf('User prompted to rename StationID ''%s''',duplicate_IDs{dup_i}),'USER')                            
                        if getSession('state','userpresent')
                            prompt = {'New StationID:'};
                            dlgtitle = 'Rename Duplicate StationID';
                            fieldsize = [1 20];
                            definput = duplicate_IDs(dup_i);
                            newID = [];
                            while isempty(newID)
                                newID = char(inputdlg(prompt,dlgtitle,fieldsize,definput));     
                            end
                            
                            logformat(sprintf('User entered new StationID ''%s''',newID),'USER')                            
                        
                        % Automated duplicate name update
                        else
                            newID = [duplicate_IDs{dup_i} 'dup' supported_char(randi(numel(supported_char)))];
                        end
                        sdb_Sensors.StationID(row_indices(2)) = newID;
                        logformat(sprintf('StationID %s: Sensor Database Row %g incremented to %s.',duplicate_IDs{dup_i},row_indices(2), newID),'DATABASE')                                                            
                    otherwise
                        logformat(sprintf('Review interrupted by user at %s',duplicate_IDs{dup_i}),'ERROR')                                                
            end
        end
        
        % Delete selected rows
        if numel(delete_rows) > 0
            sdb_Sensors(delete_rows,:) = [];
            logformat(sprintf('Deleted sensor database rows: %s ',strjoin(string(delete_rows), ', ')),'DATABASE')
        end
    end
    dupreviewed = true;
end


if ~exist('review_count','var')
    review_count = 1;
    numreview = nnz(sdb_Sensors.NeedsReview);
    table_i = 1;
    
end

table_size = size(sdb_Sensors,1);

WaitbarHandle = waitbar(0,'Reviewing Sensors...'); 

while table_i <= table_size
            
    if sdb_Sensors.NeedsReview(table_i) == true
        
        waitbar(review_count/numreview,WaitbarHandle,sprintf('Reviewing Sensor %0.0f of %0.0f...',review_count,numreview))
        
        % Print station data
        logformat(sprintf('StationID: %s',sdb_Sensors.StationID{table_i}),'INFO')
        if ~ismissing(sdb_Sensors.Hyperlink1(table_i))
            logformat(sprintf('Hyperlink1: %s',sdb_Sensors.Hyperlink1{table_i}),'INFO')
        end
        if ~ismissing(sdb_Sensors.Hyperlink2(table_i))
            logformat(sprintf('Hyperlink2: %s',sdb_Sensors.Hyperlink2{table_i}),'INFO')
        end
        
        % open the page
        success = openlink(sdb_Sensors.Hyperlink1{table_i});
        if ~success
            logformat(sprintf('Failed to open %s',sdb_Sensors.Hyperlink1{table_i}),'ERROR')
        end

        answer = questdlg('Video Type','Choose','Good','Poor','Bad','Good');

        switch answer
            case 'Good'
                logformat(sprintf('StationID ''%s'' marked ''Good'' by user.',sdb_Sensors.StationID{table_i}),'INFO')
                sdb_Sensors.NeedsReview(table_i) = false;
            case 'Poor'
                logformat(sprintf('StationID ''%s'' derated by user - unlikely usable',sdb_Sensors.StationID{table_i}),'INFO')
                sdb_Sensors = deratesensor(sdb_Sensors,sdb_Sensors.StationID{table_i},"unlikely usable sensor",1);
                sdb_Sensors.NeedsReview(table_i) = false;             
            case 'Bad'
                logformat(sprintf('StationID ''%s'' derated by user - not usable',sdb_Sensors.StationID{table_i}),'INFO')
                sdb_Sensors = deratesensor(sdb_Sensors,sdb_Sensors.StationID{table_i},"not a usable sensor",0);
                sdb_Sensors.NeedsReview(table_i) = false;
            otherwise
                logformat(sprintf('Review interrupted by user at %s',sdb_Sensors.StationID{table_i}),'WARN')
                close(WaitbarHandle)
                return
        end
        review_count = review_count + 1;
    end
    
    
    table_i = table_i + 1;
end

close(WaitbarHandle)