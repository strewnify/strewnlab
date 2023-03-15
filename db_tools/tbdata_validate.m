function [std_tb] = tbdata_validate(import_table, db_Variables)
% TBDATA_COLUMNORDER validate incoming data and remove invalid values
%[std_tb] = tbdata_columnorder(import_table)

% copy the input table
std_tb = import_table;

% Get planet data for min Height
planet = getPlanet();

% DEBUG, need to add import logging, to capture these bad data errors

db_varname = db_Variables.var_name; % get variable name order from database
validation = db_Variables.validation; % get validation type from database
import_varnames = std_tb.Properties.VariableNames;

% Move variables to the beginning, in reverse order
for var_i = 1:length(db_varname)
    
    % If the variable exists in the file, check non-missing data for validity
    check = datapresent(std_tb,db_varname(var_i));
    if nnz(check) > 0
        switch validation(var_i)
            case 'lat'
                
                % Find data outside -90 to 90
                baddata = check & ((std_tb.(db_varname{var_i}) < -90) | (std_tb.(db_varname{var_i}) > 90));
                
                % delete the bad coordinates, lat and long
                std_tb.(db_varname{var_i})(baddata) = missing; % delete lat data
                std_tb.(db_varname{var_i+1})(baddata) = missing; % delete long data
                
            case 'long'
                % Find data outside -180 to 180
                baddata = check & ((std_tb.(db_varname{var_i}) < -180) | (std_tb.(db_varname{var_i}) > 180));
                
                % delete the bad coordinates, lat and long
                std_tb.(db_varname{var_i-1})(baddata) = missing; % delete lat data
                std_tb.(db_varname{var_i})(baddata) = missing; % delete long data
                
            case 'height_m'
                % Find data less than min height in meters
                baddata = check & (std_tb.(db_varname{var_i}) < planet.min_height_m);
                
                % delete the bad data
                std_tb.(db_varname{var_i})(baddata) = missing;
                
            case 'height_km'
                % Find data less than min height in km
                baddata = check & (std_tb.(db_varname{var_i}) < (planet.min_height_m/1000));
                
                % delete the bad data
                std_tb.(db_varname{var_i})(baddata) = missing;

            case 'positive'
                % Find data less than zero
                baddata = check & (std_tb.(db_varname{var_i}) < 0);
                
                % delete the bad data
                std_tb.(db_varname{var_i})(baddata) = missing;

            case 'AZ'
                % find data outside the 0 to 360 range
                baddata = check & ((std_tb.(db_varname{var_i}) < 0) | (std_tb.(db_varname{var_i}) > 360));
                
                % delete the bad data
                std_tb.(db_varname{var_i})(baddata) = missing;

            case 'acute'
                % find data outside the 0 to 90 range
                baddata = check & ((std_tb.(db_varname{var_i}) < 0) | (std_tb.(db_varname{var_i}) > 90));
                
                % delete the bad data
                std_tb.(db_varname{var_i})(baddata) = missing;
                
            case 'none'
                % do nothing
            otherwise
                logformat(sprintf('Unknown validation type in variable database: %s',validation(var_i)),'DEBUG')
        end
    end
end


% validateattributes(lat0,{'single','double'},{'real','>=',-90,'<=',90},'','lat0')
%     validateattributes(lon0,{'single','double'},{'real','finite'},'','lon0')
%     validateattributes(h0,{'single','double'},{'real','nonnegative','finite'},'','h0')
%     validateattributes(az,{'single','double'},{'real','finite'},'','az')
%     validateattributes(tilt,{'single','double'},{'real','nonnegative','<=',180},'','tilt')




