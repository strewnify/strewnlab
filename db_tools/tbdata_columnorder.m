function [std_tb] = tbdata_columnorder(import_table, db_Variables)
% TBDATA_COLUMNORDER re-orders table columns per variable list in the database 
%[std_tb] = tbdata_columnorder(import_table, Variables)

std_tb = import_table;

% Get variable list from database
% Standardize column order, after unit conversion
% multiple units included to future-protect for standard changes
standard_order = [db_Variables.var_name db_Variables.err_var]; %concatenate table columns
standard_order = reshape(standard_order',1,numel(standard_order))'; % reshape row-wise, to interlace variables and error variables
standard_order(cellfun(@isempty,standard_order)) = []; % delete empty cells
import_varnames = std_tb.Properties.VariableNames;

% Move variables to the beginning, in reverse order
for std_i = numel(standard_order):-1:1
    if any(matches(import_varnames,standard_order(std_i)))
        std_tb = movevars(std_tb,standard_order(std_i),'Before',1);
    end
end