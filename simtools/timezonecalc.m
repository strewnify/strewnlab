function [zone] = timezonecalc(longitude)
%TIMEZONECALC improved timezone by location
    [rawzone,~,~] = timezone(longitude);
    zone = sprintf('%+03.0f:00',-rawzone);
end

