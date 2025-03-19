function [Energy_kt] = mv2energy(mass_kg,velocity_mps)
% [ENERGY_KT] = MV2ENERGY(MASS_KG,VELOCITY_MPS)
% Mass in kilograms, velocity in m/s, energy in kilotons of TNT
% The "kiloton of TNT" is a unit of energy equal to 4.184 terajoules (4.184×10^12 J)

Energy_kt = (0.5 .* mass_kg .* velocity_mps.^2)./(4.184e12);

end

