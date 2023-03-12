function [std_tb] = standardize_tbdata(data_tb, datasource)
% STANDARDIZE_TBDATA converts units, arbitrates data, and re-orders columns
%[STD_TB] = STANDARDIZE_TBDATA(DATA_TB) Clean table data

% Copy table
std_tb = data_tb;

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

% Get datatypes to choose arbitration methods
% (Don't store in table)
data_types = type_events(std_tb);

% Instead of looping, need to see how much can be re-written in array format

% Need to re-write, check which events need to be calculated and calculate them

% Reference point arbitration

% If end point is available, use end point as reference point
attempt = 0;
while attempt <= 2
    attempt = attempt + 1;
    addRef = ~datapresent(std_tb,{'ref_Description' 'ref_Lat' 'ref_Long'});
    
    % if some records are still missing reference points
    if nnz(addRef) > 0
        switch attempt
            case 1
                addRef = addRef & datapresent(std_tb,{'end_Lat' 'end_Long' 'end_Height_km'}) ;
                std_tb.ref_Lat(addRef) = std_tb.end_Lat(addRef);
                std_tb.ref_Long(addRef) = std_tb.end_Long(addRef);
                std_tb.ref_Height_km(addRef) = std_tb.end_Height_km(addRef);
                std_tb.ref_Description(addRef) = {'end'};
            case 2
                addRef = addRef & datapresent(std_tb,{'entry_Lat' 'entry_Long' 'entry_Height_km'}) ;
                std_tb.ref_Lat(addRef) = std_tb.entry_Lat(addRef);
                std_tb.ref_Long(addRef) = std_tb.entry_Long(addRef);
                std_tb.ref_Height_km(addRef) = std_tb.entry_Height_km(addRef);
                std_tb.ref_Description(addRef) = {'entry'};
            otherwise
                logformat(sprintf('Missing reference points in %s data',datasource),'DEBUG')
        end
    end
end

% Arbitrate signals
% try
%     std_tb.ref_Lat = std_tb.end_Lat;
%     std_tb.ref_Long = std_tb.end_Long;
%     std_tb.ref_Height_km = std_tb.end_Height_km;
%     std_tb.ref_Description(:) = {'end'};
% catch
%     logformat(sprintf('Reference point not found for %s.%s.%s, updated record created.',std_tb.EventID_nom{event_i}, datatype, datasource),'WARN')
% end


% % Nominal location
% % requires ref_Bearing_deg, ref_ZenithAngle_deg, ref_Lat, ref_Long, ref_Height_km
% [import_data.(datasource).LatestData.LAT(event_i), import_data.(datasource).LatestData.LONG(event_i)] =...
%                     nomlatlong(import_data.(datasource).LatestData.Bearing_deg(event_i),import_data.(datasource).LatestData.ZenithAngle_deg(event_i),import_data.(datasource).LatestData.ref_Lat(event_i),import_data.(datasource).LatestData.ref_Long(event_i),import_data.(datasource).LatestData.ref_Height_km(event_i));
%             else
%                 nomcalc = false;
%                 import_data.(datasource).LatestData.LAT(event_i) = import_data.(datasource).LatestData.ref_Lat(event_i);
%                 import_data.(datasource).LatestData.LONG(event_i) = import_data.(datasource).LatestData.ref_Long(event_i);
% 
% % Timezone and local time
% for event_i = 1:size(std_tb,1);
% 
%             % Post processing - complex functions for each record
%             if ~ismember('Timezone',fieldnames(std_tb)) && ~isnan(std_tb.LONG(event_i))
%                 std_tb.Timezone(event_i) = {timezonecalc(std_tb.LONG(event_i))};
%                 std_tb.Datetime_local(event_i) = datetime(std_tb.DatetimeUTC(event_i),'TimeZone',std_tb.Timezone{event_i});
%                 %std_tb.HyperMap(event_i) = {['https://maps.google.com/?q=' num2str(std_tb.LAT(event_i),'%f') '%20' num2str(std_tb.LONG(event_i),'%f')]};
%             else
%                 std_tb.Timezone(event_i) = {'+00:00'};
%                 %std_tb.HyperMap(event_i) = {''};
%             end
% end

% Standardize column order, after unit conversion
% multiple units included to future-protect for standard changes
standard_order = [{'EventID_nom'} {'EventID'} {'SourceKey'} {'EventName'} {'DatetimeUTC'} {'Datetime'} {'Timezone'} {'Datetime_local'} {'LAT'} {'LONG'} {'ImpactEnergyEst_kt'} {'duration_s'} {'err_duration_s'} {'Bearing_deg'} {'err_Bearing_deg'} {'ZenithAngle_deg'} {'err_ZenithAngle_deg'}];
standard_order = [standard_order {'entry_Lat'} {'err_entry_Lat'} {'entry_Long'} {'err_entry_Long'} {'entry_Height_km'} {'entry_Height_m'} {'err_entry_Height_km'} {'err_entry_Height_m'} {'entry_Speed_kps'} {'entry_Speed_mps'} {'err_entry_Speed_kps'} {'err_entry_Speed_mps'}];
standard_order = [standard_order {'end_Lat'} {'err_end_Lat'} {'end_Long'} {'err_end_Long'} {'end_Height_km'} {'end_Height_m'} {'err_end_Height_km'} {'err_end_Height_m'} {'end_Speed_kps'} {'end_Speed_mps'} {'err_end_Speed_kps'} {'err_end_Speed_mps'} {'ref_Description'} ];
standard_order = [standard_order {'ref_Lat'} {'err_ref_Lat'} {'ref_Long'} {'err_ref_Long'} {'ref_Height_km'} {'ref_Height_m'} {'err_ref_Height_km'} {'err_ref_Height_m'} {'ref_Speed_kps'} {'ref_Speed_mps'} {'err_ref_Speed_kps'} {'err_ref_Speed_mps'}];
standard_order = [standard_order {'geometric_impact_Lat'} {'err_geometric_impact_Lat'} {'geometric_impact_Long'} {'err_geometric_impact_Long'} ];
standard_order = [standard_order {'DateProcessed'} {'DateAccessed'} {'Hyperlink1'} {'Hyperlink2'} {'HyperMap'} {'ImpactEnergy_kt'} {'RadiatedEnergy_J'}];
Variablenames = std_tb.Properties.VariableNames;

% Move variables to the beginning, in reverse order
for std_i = numel(standard_order):-1:1
    if any(matches(Variablenames,standard_order(std_i)))
        std_tb = movevars(std_tb,standard_order(std_i),'Before',1);
    end
end



