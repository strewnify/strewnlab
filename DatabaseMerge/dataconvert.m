StrewnData.dummy = 0;

for i = 1:size(StrewnifyDatabase,1)
    
    % if the event exists
    if isfield(StrewnData,StrewnifyDatabase.EventID{i})
        
        % if the source exists
        if isfield(StrewnData.(StrewnifyDatabase.EventID{i}),StrewnifyDatabase.DataSource{i})
            
            % shift data to previous and add new record
            for r = numel(StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i})):-1:1
                StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i})(r+1) = StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i})(r);
            end
            
            % add new record
            StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i})(1) = table2struct(StrewnifyDatabase(i,3:end));
        
        % new source record
        else
            StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i}) = table2struct(StrewnifyDatabase(i,3:end));
        end
        
    % new event record
    else
        StrewnData.(StrewnifyDatabase.EventID{i}).(StrewnifyDatabase.DataSource{i}) = table2struct(StrewnifyDatabase(i,3:end));
    end
end