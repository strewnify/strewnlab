function [ pressure, temperature, density] = barometric( pbaro, TrefC, ground, altitude_in)
%[pressure, temperature, density] = barometric( baro, TrefC, ground, altitude )
%Calculate temperature in Kelvin and pressure in Pa at any elevation.  Inputs include:
%barometric pressure at the ground, in Pa
%temperature at the ground, in K
%density in kg/m^3
%ground elevation above sea level, in meters
%altitude above sea level, in meters
%

if isnan(pbaro)||~isreal(pbaro)||(pbaro < 50000)
    error('ERROR: Barometric pressure invalid, %d',pbaro)
elseif isnan(TrefC)||~isreal(TrefC)||(TrefC < -40)
    warning('ERROR: Tref invalid, %d',TrefC)
elseif isnan(ground)||~isreal(ground)||(ground <= -430)||(ground > 11000)
    warning('ERROR: Ground elevation invalid, %d',ground)
elseif isnan(altitude_in)||~isreal(altitude_in)|| (altitude_in < -430)
    warning('ERROR: Altitude invalid, %d',altitude_in)
end

max_alt = 150000;  % maximum valid altitude
altitude = min(altitude_in,max_alt); % effective alt for calc

TrefK = TrefC + 273.15;

% Constants
persistent planet
if isempty(planet)
    planet = getPlanet();
end

persistent R
if isempty(R)
    R = getConstant('R_JmolK');
end

g0 = planet.g0_mps2; % surface gravitational acceleration in m/s^2
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
elseif altitude <= max_alt
    b = 7;
else
    error('UNKNOWN ERROR, %d',altitude)        
end

if(Lb(b) == 0)
    pressure = Pb(b)*exp(-g0*M*(altitude-zb(b))/(R*Tb(b)));   
else
    pressure = Pb(b)*((Tb(b)/(Tb(b)+Lb(b)*(altitude-zb(b))))^((g0*M)/(R*Lb(b))));
end

temperature = Tb(b) + Lb(b)*(altitude-zb(b))-273.15;

% Extreme altitude handling
minpress = 1.322*10^-11;
mintemp = -270;
if altitude_in > 1000000
    pressure = minpress;
    temperature = mintemp;
elseif altitude_in > max_alt
    pressure = interp1([max_alt 1000000],[pressure minpress],altitude_in);
    temperature = interp1([max_alt 1000000],[temperature mintemp],altitude_in);
end

if pressure < minpress
    pressure = minpress;
end
if temperature < mintemp
    temperature = mintemp;
end

density = pressure/(Rspec*(temperature+273.15));

