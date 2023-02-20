%METEORSIM  Meteor simulation.
%   METEORSIM simulates a meteor impact with earth, based on given
%   diameter, shape, initial velocity, and other parameters.
%
%   Program written by Jim Goodall, April 2018

% Initialize
% clear all % clear variables
% clc % clear window
% figure % create plot
% hold on
% title('Simulation')
% xlabel('Distance, meters')
% ylabel('Altitude, meters')

% Constants
distancestep = 20; % meters
timestep = 0.001; % seconds
scenario = 1;
G = 6.674*10^-11; % gravitational constant in m^3 kg^-1 s^-2
earthradius = 6371000; % radius of Earth in meters
g = 9.80665; % surface gravitational acceleration in m/s^2
L = 0.0065; % temperature lapse rate in K/m
R = 8.31447; % universal gas constant in J/mol/K
Rspec = 287.058; % specific gas constant dry air
M = 0.0289644; % molar mass of dry air in kg/mol
psurf = 101.325; % standard pressure at sea level
earthmass = 5.972*10^24; % mass of Earth in kg
ground = 275; % elevation at ground level, in meters
y_max = 25000; % maximum elevation for drag forces
repeat = 1;
run = 0;
XMAX = 0;
XMIN = -5;
YMIN = ground;        
YMAX = ground + 5;


for diameter_input = 0.01:0.01:0.4
for cubicity_input = 0.2:0.3:0.8
for density_input = 2800:500:3800

    % Clear variables
    clear i t y x v vx vy p T rho DragForce CD CD_cube CD_sphere Fx Fy ax ay v_terminal c Mach b WindDrag windspeed

    run = run + 1;
    i = 1; % data index
    t(i) = 0; % time in seconds
    
    x(1) = -23686; % initial position
    y(1) = 40468;
    v(1) = 15249;
    density = density_input;
    angledeg = 30.34;
    diameter = diameter_input;
    cubicity = cubicity_input;
    TsurfC = -13.5; % surface temperature in C
    windsurf = 2.4; % surface windspeed in m/s
    
    % calculations
    radius = diameter/2;
    volume = (4/3)*pi*(radius)^3; % volume in m^3
    mass = density*volume; % mass in kg 
    FrontalArea = pi*radius^2; % frontal area in m^2
    TsurfK = TsurfC +273.15;
    T(1) = TsurfK-L*y(1); % air temperature estimate, as function of altitude
    c(1) = 20.05*sqrt(T); % Mach number
    anglerad(i) = deg2rad(angledeg);
    vx(1) = v(1)*sin(anglerad(1));
    vy(1) = -v(1)*cos(anglerad(1));

    while y(i) > ground

        % Set new time step
        timestep = distancestep/v(i);
        
        i = i + 1;
        t(i) = t(i-1) + timestep;
         
        anglerad(i) = atan(vx(i-1)/-vy(i-1));

        % Calculate Drag, if there is air
        if y(i-1) <= y_max
            p(i) = psurf*(1-((L*y(i-1))/TsurfK))^((g*M)/(R*L));
            T(i) = TsurfK-L*max(11000,y(i-1));
            rho(i) = (p(i)*1000)/(Rspec*T(i));
            c(i) = 20.05*sqrt(T(i-1)); % speed of sound
            Mach(i) = v(i-1)/c(i-1); % Mach number
            % coefficient of drag estimation - sphere
            if Mach(i) > 0.722
                CD_sphere(i) = 2.1*exp(-1.2*(Mach(i)+0.35))-8.9*exp(-2.2*(Mach(i)+0.35))+0.92;
            else
                CD_sphere(i) = 0.45*Mach(i)^2+0.424;
            end

            % coefficient of drag estimation - cube
            if Mach(i) > 1.15
                CD_cube(i) = 2.1*exp(-1.16*(Mach(i)+0.35))-6.5*exp(-2.23*(Mach(i)+0.35))+1.67;
            else
                CD_cube(i) = 0.6*Mach(i)^2+1.04;
            end
            CD(i) = cubicity*CD_cube(i)+(1-cubicity)*CD_sphere(i);
            DragForce(i) = 0.5*rho(i)*(v(i-1))^2*CD(i)*FrontalArea;
            
            windspeed(i) = windsurf*((y(i-1)-ground)/2)^0.143;
            WindDrag(i) = 0.5*rho(i)*(windsurf)^2*CD(i)*FrontalArea;

        % Otherwise, default air variables
        else
            p(i) = psurf*(1-((L*y_max)/TsurfK))^((g*M)/(R*L));
            T(i) = TsurfK-L*max(11000,y_max);
            rho(i) = (p(i)*1000)/(Rspec*T(i));
            c(i) = 20.05*sqrt(T(i-1)); % speed of sound
            Mach(i) = v(i-1)/c(i-1); % Mach number
            CD_sphere(i) = 0.92;
            CD_cube(i) = 1.67;
            CD(i) = cubicity*CD_cube(i)+(1-cubicity)*CD_sphere(i);
            DragForce(i) = 0;
            WindDrag(i) = 0;
        end
        Fx(i) = -DragForce(i)*sin(anglerad(i))-WindDrag(i);
        Fy(i) = DragForce(i)*cos(anglerad(i))-G*earthmass*mass/(earthradius+y(i-1))^2;
        ax(i) = Fx(i)/mass;
        ay(i)= Fy(i)/mass;

        % Calculate new velocities
        vx(i) = vx(i-1)+ax(i)*timestep;
        vy(i) = vy(i-1)+ay(i)*timestep;
        v(i) = sqrt((vx(i))^2+(vy(i))^2);
        v_terminal(i)=sqrt((2*mass*g)/(rho(i)*FrontalArea*CD(i)));

        % Calculate new location
        x(i)=x(i-1)+vx(i)*timestep;
        y(i)=y(i-1)+vy(i)*timestep;
        
    end

    % Calculate Statistics
    Mach1_index = find(Mach(2:end)<1,1,'first');
    Mach1_time = t(Mach1_index);
    Mach1_altitude = y(Mach1_index);
    ImpactTime = t(end);
    
    % Calculate Sonic Boom
    boom_timestep = 0.01;
    boom_y = Mach1_altitude;
    boom_t = 0;
    while boom_y > ground  
        boom_p = psurf*(1-((L*boom_y)/TsurfK))^((g*M)/(R*L));
        boom_T = TsurfK-L*boom_y;
        boom_rho = (boom_p*1000)/(Rspec*boom_T);
        boom_v = 20.05*sqrt(boom_T); % speed of sound
        boom_y = boom_y - boom_v * boom_timestep;
        boom_t = boom_t + boom_timestep;
    end
    boom2impact = t(end)-boom_t;    
    
    % Create plot
   
    XMIN_TEMP = min(x)-abs(0.05*min(x));
    if XMIN_TEMP < XMIN
        XMIN = XMIN_TEMP;
    end
    
    YMIN_TEMP = min(y)-abs(0.05*min(y));
    if YMIN_TEMP < YMIN
        YMIN = YMIN_TEMP;
    end
    
    XMAX_TEMP = max(x)+abs(0.05*max(x));
    if XMAX_TEMP > XMAX
        XMAX = XMAX_TEMP;
    end
    
    YMAX_TEMP = max(y)+abs(0.05*max(y));
    if YMAX_TEMP > YMAX
        YMAX = YMAX_TEMP;
    end
        
    axis([XMIN XMAX YMIN YMAX])

    pause(1);
    plot(x,y)
    
    
    results(scenario,:) = [x(1) y(1) v(1) angledeg diameter density cubicity TsurfC windsurf x(end) t(end) Mach1_time Mach1_altitude boom_t]; 
    scenario = scenario + 1;
end
end
end


