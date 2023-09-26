
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