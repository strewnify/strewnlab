function [std_tb] = tbdata_unitconvert(import_table)
% TBDATA_UNITCONVERT converts units
%[std_tb] = tbdata_unitconvert(import_table)

% Copy table
std_tb = import_table;

% Configure out units
out_units = [{'km'} {'kps'}];

% Define unit conversion factors
unit_convert = [{'km'} {'m'} {1000}; {'kps'} {'mps'} {1000}];

% for each unit to be converted
for unit_i = 1:numel(out_units)

    % Lookup conversion factor
    idx_matches = [matches(unit_convert(:,[1 2]),out_units{unit_i}) false(size(unit_convert,1),1)]; % logical array of unit conversion target matches
    [row,col] = ind2sub(size(unit_convert),find(idx_matches)); % convert logical to row/column address
    switch col
        case 1 % target unit in column 1
            unit_to_convert = ['_' unit_convert{row,2}];
            target_unit = ['_' unit_convert{row,1}];
            factor = 1 ./ unit_convert{row,3};
        case 2 % target unit in column 1
            unit_to_convert = ['_' unit_convert{row,1}];
            target_unit = ['_' unit_convert{row,2}];
            factor = unit_convert{row,3};
        otherwise
            error('unknown error');
    end

    % find variables to convert
    vars_convert = endsWith(std_tb.Properties.VariableNames,unit_to_convert);

    % Convert variables
    if any(vars_convert)
        std_tb{:,vars_convert} = std_tb{:,vars_convert} .* factor;
    end
    
    % Rename vars after unit conversion
    oldNames = std_tb.Properties.VariableNames(vars_convert);
    newNames = strcat(extractBefore(oldNames, unit_to_convert),target_unit);
    std_tb = renamevars(std_tb,oldNames,newNames);
end
