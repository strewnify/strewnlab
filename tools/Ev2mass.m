function [mass_kg] = Ev2mass(Energy_kt,velocity_mps)
% EV2MASS calculates entry mass, from impact energy and velocity
% [MASS_KG] = Ev2mass(ENERGY_KT,VELOCITY_MPS)
% Mass in kilograms, velocity in m/s, energy in kilotons of TNT
% The "kiloton of TNT" is a unit of energy equal to 4.184 terajoules (4.184×10^12 J)

mass_kg = 2 .* Energy_kt .* (4.184e12) ./ velocity_mps.^2;

end

