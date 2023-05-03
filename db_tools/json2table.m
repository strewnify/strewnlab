function [tb_out] = json2table(json_in, import_mapping)
%JSON2TABLE Convert a json input to a table

records = fieldnames(json_in);

% convert json to table of cells
for row = 1:numel(records)
    tb_out(row,:) = struct2table(json_in.(records{row}),'AsArray',true);
end

% If mapping is not provided, create default mapping
if nargin == 1
    import_mapping = mapsource(tb_out(1,:));
end

% Convert variables
for var_i = 1:numel(import_mapping.import_var)

    % Convert cell to vector
    if import_mapping.import_type(var_i) =='double'
        tb_out.(import_mapping.import_var{var_i}) = cell2mat(tb_out.(import_mapping.import_var{var_i}));
    end
    
end