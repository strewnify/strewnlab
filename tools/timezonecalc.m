function [zone] = timezonecalc(longitude)
%TIMEZONECALC improved timezone by location


% Pre-allocate cell string
zone = repmat({''},size(longitude));

% Find invalid values
invalid = isnan(longitude);
valid = ~invalid;

% Calculate timezones
[rawzone(valid),~,~] = timezone(longitude(valid));
zone(valid) = cellstr(num2str(-rawzone(valid)','%+03.0f:00'));
zone(invalid) = {'UTC'};
