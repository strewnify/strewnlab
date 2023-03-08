%SONIC  Sonic Boom simulation.
%   SONIC simulates the propagation of a sonic boom from a given altitude, to seismic station
% Program written by Jim Goodall, May 2019.

% Initialize
clc % clear window
figure(1)
hold on
title('Sonic Path')
xlabel('x');
ylabel('z');
axis([0 30000 0 30000]);
alt_i= 1;
angledeg = 45;

for start_altitude = 5000:1000:40000
% Inputs
%start_altitude = 25000;
%angledeg = 20;
TsurfC = 20;
psurf = 98000;
ground = 1500;

% Pre-allocate
current = 1;
previous = 2;
history = 5;
position = zeros(history,3); % 3D position in meters

% Calculate release vector
slope = -1/tan(degtorad(angledeg));
startposition = [0 0 start_altitude];
endposition = [-(start_altitude - ground) / slope 0 ground];
vector = endposition - startposition;
unitvector = vector/norm(vector);

% Initialize variables
t = 0;
distance = 0;
position(previous,:) = startposition;
timestep = 1;

% Initialize environment
[pressure, temperature, rho] = barometric(psurf,TsurfC,ground,position(3)); % air temperature estimate, as function of altitude
%speedsound = 20.05*sqrt(temperature+273.15); % local speed of sound
speedsound = sound(find(sound<start_altitude,1,'first'),2);
velocity(previous,:) = speedsound * unitvector;

while position(previous,3) > ground
    % Update position
    position(current,:) = position(previous,:) + velocity(previous,:) .* timestep;
    
    % Update environment
    %[pressure, temperature, rho] = barometric(psurf,TsurfC,ground,position(current,3)); % air temperature estimate, as function of altitude
    %speedsound = 20.05*sqrt(temperature+273.15); % local speed of sound
    speedsound = sound(find(sound<position(current,3),1,'first'),2);
    velocity(current,:) = speedsound * unitvector;
    
    % Update flight counters
    distance = distance + norm(position(current,:)-position(previous,:));
    t = t + timestep;
    
    % Shift data to previous
    for i = history:-1:2
        position(i,:) = position(i-1,:);
    end
    
    %Update plot
%figure(1)
%plot(position(current,1),position(current,3),'b.')
%drawnow
end

averagespeed = distance / t;
elevation_ang = 90-angledeg;
sounddata_alt(alt_i,:) = [start_altitude distance t averagespeed]
angle_i = angle_i + 1;
alt_i = alt_i + 1;
end
    