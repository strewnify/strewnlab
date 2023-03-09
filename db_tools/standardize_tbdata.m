function [std_tb] = standardize_tbdata(data_tb)
%[STD_TB] = ORDERCOLUMNS_EVENTDATA(DATA_TB) Standardize table data

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
    vars_convert = endsWith(data_tb.Properties.VariableNames,unit_to_convert);

    % Convert variables
    if any(vars_convert)
        data_tb{:,vars_convert} = data_tb{:,vars_convert} .* factor;
    end
    
    % Rename vars after unit conversion
    oldNames = data_tb.Properties.VariableNames(vars_convert);
    newNames = strcat(extractBefore(oldNames, unit_to_convert),target_unit);
    data_tb = renamevars(data_tb,oldNames,newNames);
end



% Standardize column order, after unit conversion
% multiple units included to future-protect for standard changes
standard_order = [{'EventID_nom'} {'EventID'} {'SourceKey'} {'EventName'} {'DatetimeUTC'} {'Datetime'} {'Timezone'} {'Datetime_local'} {'Bearing_deg'} {'ZenithAngle_deg'} {'ImpactEnergyEst_kt'}];
standard_order = [standard_order {'entry_Lat'} {'err_entry_Lat'} {'entry_Long'} {'err_entry_Long'} {'entry_Height_km'} {'entry_Height_m'} {'err_entry_Height_km'} {'err_entry_Height_m'} {'entry_Speed_kps'} {'entry_Speed_mps'} {'err_entry_Speed_kps'} {'err_entry_Speed_mps'}];
standard_order = [standard_order {'end_Lat'} {'err_end_Lat'} {'end_Long'} {'err_end_Long'} {'end_Height_km'} {'end_Height_m'} {'err_end_Height_km'} {'err_end_Height_m'} {'end_Speed_kps'} {'end_Speed_mps'} {'err_end_Speed_kps'} {'err_end_Speed_mps'} {'ref_Description'} ];
standard_order = [standard_order {'ref_Lat'} {'err_ref_Lat'} {'ref_Long'} {'err_ref_Long'} {'ref_Height_km'} {'ref_Height_m'} {'err_ref_Height_km'} {'err_ref_Height_m'} {'ref_Speed_kps'} {'ref_Speed_mps'} {'err_ref_Speed_kps'} {'err_ref_Speed_mps'}];
standard_order = [standard_order {'DateProcessed'} {'DateAccessed'} {'Hyperlink1'} {'Hyperlink2'} {'HyperMap'}];
Variablenames = data_tb.Properties.VariableNames;

% Move variables to the beginning, in reverse order
for std_i = numel(standard_order):-1:1
    if any(matches(Variablenames,standard_order(std_i)))
        data_tb = movevars(data_tb,standard_order(std_i),'Before',1);
    end
end

std_tb = data_tb;

