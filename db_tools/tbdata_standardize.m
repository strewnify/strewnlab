function [std_tb] = tbdata_standardize(import_data, datasource, raw_tb, db_Variables)
% STANDARDIZE_TBDATA converts units, arbitrates data, and re-orders columns
%[STD_TB] = STANDARDIZE_TBDATA(DATA_TB) Clean table data

% Get planet data
planet = getPlanet();

% Copy tables
std_tb = import_data.(datasource).(raw_tb);

% Validate input data
std_tb = tbdata_validate(std_tb, db_Variables);

% Unit conversion
std_tb = tbdata_unitconvert(std_tb);

% Get datatypes to choose arbitration methods
% (Don't store in table)
data_types = type_events(std_tb);

% Identify measured values
% Debug, update based on variable database
errVar = db_Variables.err_calc_method ~= 'none'; % 
meas_var = cellstr(db_Variables.var_name(errVar)); % measured variables
err_var = cellstr(db_Variables.err_var(errVar)); % error variables
err_method = cellstr(db_Variables.err_calc_method(errVar)); % get error calculation method

% If measurement error is not given, estimate based on source
for var_i = 1:length(meas_var)
    
    % find records with measured variables and missing error variables
    calcErr = datapresent(std_tb,meas_var(var_i)) & ~datapresent(std_tb,err_var(var_i));
    
    if nnz(calcErr) > 0
        % Determine error for lat/long
        if strcmp(err_method{var_i},'lat')
            meas_lat_var = meas_var{var_i}; % lat var name
            meas_lon_var = meas_var{var_i + 1}; % assume lon var name follows lat
            meas_lat = std_tb.(meas_lat_var)(calcErr);
            meas_lon = std_tb.(meas_lon_var)(calcErr);
            quad_err_m = sqrt(2) .* 1000 .* import_data.(datasource).location_err_km; % quadrant corner distance

            % reckon quad corners
            [lat_NW,lon_NW] = reckon(meas_lat,meas_lon,quad_err_m,315,planet.ellipsoid_m);
            [lat_SE,lon_SE] = reckon(meas_lat,meas_lon,quad_err_m,135,planet.ellipsoid_m);

            % calculate average lat/lon error, NW and SE
            % for most point/error combinations, the difference is negligable, but corner cases near poles must be considered
            std_tb.(err_var{var_i})(calcErr) = mean([abs(meas_lat - lat_NW) abs(meas_lat - lat_SE)],2); % store lat error
            std_tb.(err_var{var_i+1})(calcErr) = mean([abs(meas_lon - lon_NW) abs(meas_lon - lon_SE)],2); % store lon error

        elseif strcmp(err_method{var_i},'long')
            % ignore, handled in lat logic above

        % Use datasource defaults
        elseif isfield(import_data.(datasource),err_method{var_i})
            std_tb.(err_var{var_i})(calcErr) = import_data.(datasource).(err_method{var_i});
        else
            logformat(sprintf('"%s" is not a recognized error type. Measurement error not assigned.',err_method{var_i}),'DEBUG')
        end
    end
end

% Reference point arbitration
refPriority = {'end' 'peak' 'entry' 'impact'}; % first entry takes priority
% Use first available point as reference point
for point_i = 1:length(refPriority)
    lat_var = [refPriority{point_i} '_Lat'];
    lon_var = [refPriority{point_i} '_Long'];
    height_var = [refPriority{point_i} '_Height_km'];
    speed_var = [refPriority{point_i} '_Speed_kps'];
    
    addRef = ~datapresent(std_tb,{'ref_Description' 'ref_Lat' 'ref_Long'}) & datapresent(std_tb,{lat_var lon_var height_var});
    if nnz(addRef) > 0
        std_tb.ref_Lat(addRef) = std_tb.(lat_var)(addRef);
        std_tb.ref_Long(addRef) = std_tb.(lon_var)(addRef);
        std_tb.ref_Height_km(addRef) = std_tb.(height_var)(addRef);
        std_tb.ref_Description(addRef) = refPriority(point_i);    
    end
    addRefSpd = addRef & datapresent(std_tb,{speed_var});
    if nnz(addRefSpd) > 0
        std_tb.ref_Speed_kps(addRefSpd) = std_tb.(speed_var)(addRefSpd);
    end
end

% Calculate angles, if missing and start and end point data is available
samplesize = 100000; % accuracy of the trajectory error calculation, 10000 for speed, 1000000 for most accurate
calcAng = ~datapresent(std_tb,{'Bearing_deg' 'ZenithAngle_deg'}) & datapresent(std_tb,{'entry_Lat' 'entry_Long' 'entry_Height_km' 'end_Lat' 'end_Long' 'end_Height_km' 'err_entry_Lat' 'err_entry_Long' 'err_entry_Height_km' 'err_end_Lat' 'err_end_Long' 'err_end_Height_km'});
if nnz(calcAng) > 0
[std_tb.Bearing_deg(calcAng),std_tb.ZenithAngle_deg(calcAng), std_tb.PathLength_km(calcAng), std_tb.err_Bearing_deg(calcAng), std_tb.err_ZenithAngle_deg(calcAng), std_tb.err_PathLength_km(calcAng)] =...
    trajectoryerror(std_tb.entry_Lat(calcAng), std_tb.entry_Long(calcAng), std_tb.entry_Height_km(calcAng).*1000, std_tb.end_Lat(calcAng), std_tb.end_Long(calcAng), std_tb.end_Height_km(calcAng).*1000,std_tb.err_entry_Lat(calcAng), std_tb.err_entry_Long(calcAng), std_tb.err_entry_Height_km(calcAng).*1000, std_tb.err_end_Lat(calcAng), std_tb.err_end_Long(calcAng), std_tb.err_end_Height_km(calcAng).*1000, samplesize);
end

% Calculate speed from duration
calcSpeed = ~datapresent(std_tb,{'entry_Speed_kps'}) & datapresent(std_tb,{'duration_s' 'err_duration_s' 'PathLength_km' 'err_PathLength_km'});
if nnz(calcSpeed) > 0 
    
    % Calculate average speed, from observed path length and duration
    avg_speed_kps =  std_tb.PathLength_km(calcSpeed) ./ std_tb.duration_s(calcSpeed);
    
    % Calculate error in the speed, using the uncertainty of the path length and duration
    err_avg_speed_kps = sqrt(std_tb.err_PathLength_km(calcSpeed).^2 + (std_tb.PathLength_km(calcSpeed).*std_tb.err_duration_s(calcSpeed)./std_tb.duration_s(calcSpeed)).^2) ./ std_tb.err_duration_s(calcSpeed);
    
    % DEBUG - need average speed to entry speed conversion
    std_tb.entry_Speed_kps(calcSpeed) = avg_speed_kps;
    std_tb.err_entry_Speed_kps(calcSpeed) = err_avg_speed_kps;
end

% Calculate nominal point, if input data is available
calcNom = datapresent(std_tb,{'Bearing_deg' 'ZenithAngle_deg' 'ref_Lat' 'ref_Long' 'ref_Height_km'});
if nnz(calcNom) > 0 
[std_tb.LAT(calcNom), std_tb.LONG(calcNom)] =...
                    nomlatlong(std_tb.Bearing_deg(calcNom),std_tb.ZenithAngle_deg(calcNom),std_tb.ref_Lat(calcNom),std_tb.ref_Long(calcNom),std_tb.ref_Height_km(calcNom));
end

% Calculate geometric impact point, if input data is available
calcImpact = ~datapresent(std_tb,{'impact_Lat' 'impact_Lon'}) & datapresent(std_tb,{'Bearing_deg' 'ZenithAngle_deg' 'ref_Lat' 'ref_Long' 'ref_Height_km'});
if nnz(calcImpact) > 0 
    [std_tb.impact_Lat(calcImpact),std_tb.impact_Long(calcImpact),~] = lookAtSpheroid(std_tb.ref_Lat(calcImpact),std_tb.ref_Long(calcImpact),std_tb.ref_Height_km(calcImpact),std_tb.Bearing_deg(calcImpact),std_tb.ZenithAngle_deg(calcImpact),planet.ellipsoid_m);    
end

% Default nominal point, for records with missing data
defaultNom = ~calcNom;
if nnz(defaultNom) > 0 
    std_tb.LAT(defaultNom) = std_tb.ref_Lat(defaultNom);
    std_tb.LONG(defaultNom) = std_tb.ref_Long(defaultNom);
end

% Add timezone
addTZ = ~datapresent(std_tb,{'Timezone'}) & datapresent(std_tb,{'LAT' 'LONG'}); % identify records with missing timezone
if nnz(addTZ) > 0
    std_tb.Timezone(addTZ) = timezonecalc(std_tb.LONG(addTZ));
    std_tb.Datetime_local(addTZ) = cellfun(@datetime, num2cell(std_tb.DatetimeUTC(addTZ)), repmat({'TimeZone'},nnz(addTZ),1), std_tb.Timezone(addTZ));
end

% Default timezone, if no nominal location
defaultTZ = ~datapresent(std_tb,{'Timezone'}) & ~datapresent(std_tb,{'LAT' 'LONG'});
if nnz(defaultTZ) > 0
    std_tb.Timezone(defaultTZ) = {'+00:00'};
end

% Apply standard column order
std_tb = tbdata_columnorder(std_tb, db_Variables);


