function [ImpactEnergy_kt] = rad2impact(RadiatedEnergy_J)
% [IMPACTENERGY_KT] = RAD2IMPACT(RADIATEDENERGY_J) Converts radiated energy
% in joules to impact energy in kt of TNT
% The "kiloton of TNT" is a unit of energy equal to 4.184 terajoules (4.184×10^12 J)

RadiatedEnergy_kt = RadiatedEnergy_J ./ (4.184e12);
ImpactEnergy_kt = 8.2508 .* RadiatedEnergy_kt .^ 0.885;

end

