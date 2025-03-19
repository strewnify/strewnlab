function [EoT] = EqOfTime(day)
% [EOT] = EQOFTIME(DAY) The Equation of Time

B = (360/365) .* (day - 81);
EoT = 9.87 .* sind(2.*B) - 7.53 .* cosd(B) - 1.5 .* sind(B);

end

