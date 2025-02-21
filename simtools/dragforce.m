function [ force ] = dragforce( airspeed, airdensity, dragcoef, frontalarea_m2 )
%force = DRAGFORCE( airspeed, airdensity, dragcoef, frontalarea_m2 )
%Calculate drag force in Newtons.  Inputs include:
%airspeed in m/s
%air density in kg/m^3
%coefficient of drag
%frontal area in m^2

% Error checking
if isnan(airspeed)||~isreal(airspeed)
     error('ERROR: Air speed invalid, %d',airspeed)
elseif isnan(airdensity)||~isreal(airdensity)||(airdensity < 0)
     error('ERROR: Air density invalid, %d',airdensity)
elseif isnan(dragcoef)||~isreal(dragcoef)||(dragcoef <= 0)
     error('ERROR: Drag coefficient invalid, %d',dragcoef)
elseif isnan(frontalarea_m2)||~isreal(frontalarea_m2)|| (frontalarea_m2 < 0)
     error('ERROR: Frontal area invalid, %d',frontalarea_m2)
end

% Calculate force
force = 0.5*airdensity*(airspeed)^2*dragcoef*frontalarea_m2;

end

