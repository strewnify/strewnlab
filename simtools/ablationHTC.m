speed = 18000;
rho = 0.0038;
Cd = 0.7;
noseradius = 0.05;
shapefactor = 1.9;
density = 3400;
material = 'h chondrite';
%function [ HTC ] = ablationHTC( speed, rho, Cd, noseradius, shapefactor, density, material )
%HTC = ABLATIONHTC()    Calculate the ablation heat transfer coefficient, as
% FUNCTION INCOMPLETE, refer to "Ablationa and Breakup of Large Meteoroids
% during Atmospheric Entry" Baldwin and Sheaffer 1971

% Projectile properties lookup
% density in kg/m^3
% heat transfer coefficient, for ablation simulation, in W/m2.K
% sig_t1 and sig_c2, in N/m^2
% m1 and m2, in kg
% heat of melting, spalling, and total ablation, in J/kg
% Tf in Kelvin (flow temperature??)
% Molar mass M, in kg/mole
% k, in W/m.K
% i, in Kelvin

% Constants
StefBolt = 7.5657*10^-16;
c = 0.943 * 10^-4;
C_HRMAX = 0.1363;
P = 0.15;
alpha = 0.3;
rho_21 = 9;
sig1 = 0.1;

% Tabulated constants, by material
switch lower(material)
    case 'carbonaceous'
        At = 1/6;
        Ac = 1/12;
        C1 = 10.63;
        C2 = -16750;
        Cu = 1.525*10^-8;
        Cs = 0.85;
        i = 14800;
        k = 2;
        M = 0.03985;
        m1 = 0.000432;
        m2 = 0.00439;
        Tf = 1785;
        emissivity = 0.6;
        sig_c2 = 1000000;
        sig_t1 = 22500000;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 8510000; 
    case 'h chondrite'
        At = 1/6;
        Ac = 1/12;
        C1 = 9.6;
        C2 = -13500;
        Cu = 2.195*10^-8;
        Cs = 0;
        i = 20150;
        k = 2;
        M = 0.05;
        m1 = 0.000432;
        m2 = 0.00439;
        Tf = 1785;
        emissivity = 0.6;
        sig_c2 = 1.736*10^8;
        sig_t1 = 22500000;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 8510000; 
    case 'iron'
        At = 0;
        C1 = 9.607;
        C2 = -16120;
        Cu = 5.86*10^-8;
        Cs = 0;
        i = 2765;
        k = 40;
        M = 0.056;
        Tf = 1818;
        emissivity = 0.6;
        sig_c2 = 5*10^8;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 8010000; 
    case 'l chondrite'
        At = 1/6;
        Ac = 1/12;
        C1 = 14.215;
        C2 = -26700;
        Cu = 1.655*10^-9;
        Cs = 0.85;
        i = 23030;
        k = 2;
        M = 0.03985;
        m1 = 0.000432;
        m2 = 0.00439;
        Tf = 1800;
        emissivity = 0.6;
        sig_c2 = 1.736*10^8;
        sig_t1 = 22500000;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 7980000; 
    case 'stony'
        At = 1/6;
        Ac = 1/12;
        C1 = 9.6;
        C2 = -13500;
        Cu = 2.195*10^-8;
        Cs = 0;
        i = 20150;
        k = 2;
        M = 0.05;
        m1 = 0.000432;
        m2 = 0.00439;
        Tf = 1785;
        emissivity = 0.6;
        sig_c2 = 1.736*10^8;
        sig_t1 = 22500000;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 8245000; 
    case 'stony-iron'
        At = 1/6;
        Ac = 1/12;
        C1 = 9.6;
        C2 = -13500;
        Cu = 2.195*10^-8;
        Cs = 0;
        i = 20150;
        k = 21;
        M = 0.053;
        m1 = 0.000432;
        m2 = 0.00439;
        Tf = 1785;
        emissivity = 0.6;
        sig_c2 = 1.736*10^8;
        sig_t1 = 22500000;
        meltingheat = 1884000;
        spallingheat = 1000000;
        totalheat = 8170000; 
end

% Calculations
rho_prime = rho / 1.225
if speed >= 13700
    C_Hcu = 41.6 * rho_prime^0.8 * (speed / 10^4)^2.05 * noseradius * exp(-7.2 * 10^-8 / (rho_prime * noseradius))
else
    C_Hcu = 1.58 * rho_prime^0.8 * (speed / 10^4)^12.45 * noseradius * exp(-7.2 * 10^-8 / (rho_prime * noseradius))
end
if rho_prime >= 10^-3
    C_Hnu = 0.6 * 10^-6 * rho_prime^-1 * (speed / 10^4)^4 * exp(-7.2 * 10^-8 / (rho_prime * noseradius))
else
    C_Hnu = 0.6 * 10^-3 * (speed / 10^4)^4 * exp(-7.2 * 10^-8 / (rho_prime * noseradius))
end
C_HRT = C_Hcu + C_Hnu
C_HR = C_HRT * exp(-2 * (C_HRT / C_HRMAX)) + C_HRMAX * (1-exp(-C_HRT/C_HRMAX))^2

% Iterative Calculation
T = 20000; % initial value guess
T_prev = 9999; % initial T prev
omega_s = 134;
omega_s_prev = 130;
HTC = 0.1;
C_Hcvu = 0.1 - C_HR; % initial value guess
while 1 == 1
    
    % Solve definite integral for viscosity function G(T) for given material
    fun = @(n) n*exp(-(i*(T-Tf)*n)/(T*(T-(T-Tf)*n)));
    G_var = integral(fun,0,1)
    
    pv = 10^(C1+C2/T)
    omega_FM = 0.1383 * M^0.5 * pv / T^0.5
    omega_d = (34.4*M*C_Hcvu*pv)/(speed*((1-pv)/(rho*speed^2)))
    if pv > (rho*speed^2)
        omega = omega_FM
    else
        omega = 1/(1/omega_FM + 1/omega_d)
    end
    C_Fu = (2*C_Hcvu)/(rho_21^0.5)
    CF = C_Fu*exp(-C_Fu) + 2 * (1 - exp(-C_Fu/2))^2
           
    something = 1; % TBD
    rho_f = rho; % TBD
    
    % Solve for omega_s
    %while abs((omega_s-omega_s_prev)/omega_s_prev) > 0.01
        %omega_s_prev = omega_s;
        numerator = CF * rho * speed^2 * (1 + ((1-shapefactor^(2/3)*Cd)*2*k*(T-Tf))/(4*pi^0.5*rho_f*omega_s*CF*noseradius)) * ((k^2*(T-Tf)^2*G_var)/(meltingheat^2*noseradius*Cu*exp(something/T)))
        denominator = (1-Cs)*omega_s - omega
        omega_s = sqrt(numerator/denominator)        
    %end
    
    % Solve for T
    T = ((0.5 * HTC * rho * speed^3 - (totalheat - meltingheat)*omega - ((1-Cs)*meltingheat + Cs*spallingheat)*omega_s)/(emissivity*StefBolt))^(1/4)
    
    trash = input('any key to continue'); % Pause
    
    % Calculate heat of ablation
    Term1 = (c*speed^(P * speed))/((rho_prime*noseradius)^(1/2));
    Term2 = sig1 + (1-sig1)/(1+alpha * speed^2 * exp(-7.2 * 10^-8 / (rho_prime * noseradius)) * omega / (emissivity * StefBolt * T^4 + totalheat * omega));
    C_Hcvu = Term1 * Term2
    C_Hu = C_Hcvu + C_HR
    HTC = C_Hu * exp(-2 * C_Hu) + (1 - exp(-C_Hu))^2
    ablationheat = (HTC * rho * speed^3) / (2*omega_s)
    
    
end




