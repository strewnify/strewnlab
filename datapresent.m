function [valid] = datapresent(input_data,req_var)
%CHECKMISSING Returns the table rows that are missing any of the required
%variables

% check input data
if istable(input_data) || isstruct(input_data)
    numrecords = size(input_data,1);  % number of data records
else
    error('Data input must be table or struct.')
end

% check variable list
if isvector(req_var) && iscell(req_var) && ischar(req_var{1})
    numvar = length(req_var); % number of required variables
else
    error('REQ_VAR must be a vector cell array of strings.')
end

% Create a false array, same size as the number of records
allfalse = false(numrecords,1);

% Get variable names
varnames = fieldnames(input_data);

% If all the variables are present in the table
if all(ismember(req_var,fieldnames(input_data)))
    
    % ****** matlab bugfix *******
    % cell arrays of character vectors are not supported
    % by the ismissing function, unless every cell is char type.  
    % (even though deleted values default to double!)
    % In order to fix the bug, cellstring arrays must be repaired
    
    % identify cell type variables
    cell_var = req_var(strcmp(varfun(@class, input_data(:,req_var), 'OutputFormat', 'cell'),'cell'));
    
    % Find non-char cell data and replace it with ''
    for cell_i = 1:length(cell_var)
        badcells = ~cellfun(@ischar,table2cell(input_data(:,cell_var{cell_i})));
        input_data(badcells,cell_var{cell_i}) = {''}; % turn bad data into missing data
    end
    % ****** matlab bugfix end *******
                   
    % flag records with any of the variables of interest missing
    invalid_records = any(ismissing(input_data(:,req_var)),2);
    
    % Return valid records as logical true
    valid = ~invalid_records;
else
    valid = allfalse;
end
