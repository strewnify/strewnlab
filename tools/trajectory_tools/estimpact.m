function [Energy_kt] = estimpact(end_alt_m,angle)
%[ENERGY_KT] = ESTIMPACT Estimate the impact energy in kt of TNT, given the
%incidence angle from vertical and the end altitude

% coefficients for rho_air = a*ln(E*cos(angle))+b
a = 0.0170;
b = 0.179;

% Calculate air density at end altitude, in kg/m^3
[~, ~, rho_air] = barometric(101000, 20, 0, end_alt_m);

% Estimate impact energy
if angle >=90
    angle = 89;
    warning('max angle support is 89')
end

Energy_kt = (exp((rho_air - b)./a))./cosd(angle);

if Energy_kt > 1000000
    Energy_kt = NaN;
    warning('irrational altitude')

end

