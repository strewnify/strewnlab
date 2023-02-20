function [ pressure, temperature, density] = barometric_data( pressure_data, temperature_data, ground, altitude)
%[pressure, temperature, density] = barometric( baro, TrefC, ground, altitude )
%Lookup temperature in Kelvin and pressure in Pa at any elevation.  
% Inputs:
% pressure interpolant, in Pa
% temperature interpolant, in K
% altitude above sea level, in meters
% Outputs:
% pressure in Pa
% temperature in Kelvin
% density in kg/m^3

if isnan(altitude)||~isreal(altitude)|| (altitude < -430)
     error('ERROR: Altitude invalid, %d',altitude)
end

TrefK = TrefC + 273.15;

% Constants
g0 = 9.80665; % surface gravitational acceleration in m/s^2
R = 8.3144598; % universal gas constant in J/(mol.K)
Rspec = 287.058; % specific gas constant dry air J/(kg.K)
M = 0.0289644; % molar mass of dry air in kg/mol

% Tb = [288.15 216.65 216.65 228.65 270.65 270.65 214.65]; % standard temp, K
% Pb = [101325 22632.1 5474.89 868.02 110.91 66.94 3.96]; % static pressure, Pa
 zb = [0 11000 20000 32000 47000 51000 71000]; % height above sea level, m
 Lb = [-0.0065 0 0.001 0.0028 0 -0.0028 -0.002]; % temperature lapse rate, K/m

% reference temp and pressure
Tb(1) = TrefK - Lb(1)*ground;
Pb(1) = pbaro/((Tb(1)/(Tb(1)+Lb(1)*ground))^((g0*M)/(R*Lb(1))));

for b = 1:6
    if(Lb(b) == 0)
        Pb(b+1) = Pb(b)*exp(-g0*M*(zb(b+1)-zb(b))/(R*Tb(b)));   
    else
        Pb(b+1) = Pb(b)*((Tb(b)/(Tb(b)+Lb(b)*(zb(b+1)-zb(b))))^((g0*M)/(R*Lb(b))));
    end
    Tb(b+1) = Tb(b) + Lb(b)*(zb(b+1)-zb(b));
end

if altitude <= zb(2)
    b = 1;
elseif altitude <= zb(3)
    b = 2;
elseif altitude <= zb(4)
    b = 3;
elseif altitude <= zb(5)
    b = 4;
elseif altitude <= zb(6)
    b = 5;
elseif altitude <= zb(7)
    b = 6;
elseif altitude <= 150000
    b = 7;
else
    error('ERROR: Altitude invalid, %d',altitude)
end

if(Lb(b) == 0)
    pressure = Pb(b)*exp(-g0*M*(altitude-zb(b))/(R*Tb(b)));   
else
    pressure = Pb(b)*((Tb(b)/(Tb(b)+Lb(b)*(altitude-zb(b))))^((g0*M)/(R*Lb(b))));
end

temperature = Tb(b) + Lb(b)*(altitude-zb(b))-273.15;
density = pressure/(Rspec*(temperature+273.15));

end

