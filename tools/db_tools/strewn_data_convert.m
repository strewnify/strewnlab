% STREWN_DATA_CONVERT Converts strewn field array results, generated before
% January 20, 2020, to the new table format.  This file can be deleted
% after some time (when old data has become obsolete.  Don't forget that
% mat files not containing sim_scenario are not convertable to the new format.

clear

% Get file and path from user
[conv_filename,conv_path] = uigetfile;

% load file
load([conv_path conv_filename]);

if exist('sim_scenario','var')
    % convert strewn data
    temp = array2table(strewn_data,'VariableNames',{'sim_scenario','entrymass','angledeg','bearing','SplitProbability','geometric_ref_elevation','entryspeed','parent','cubicity','density','frontalareamult','n','Longitude','Latitude','vend','impactenergy','mass','ref_time','ref_altitude_corr','ref_speed_corr','ref_slope_corr','darkflight'});
    clear strewn_data
    strewndata = temp;
    clear temp;
else
    error('Format not convertible.');
end

% demonstrate successful conversion
strewnhist

% save file
save([conv_path conv_filename]);

clear