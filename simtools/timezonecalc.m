function [zone] = timezonecalc(longitude)
%TIMEZONECALC improved timezone by location
    [rawzone,~,~] = timezone(longitude);
    zone = cellstr(num2str(-rawzone,'%+03.0f:00'));
end

