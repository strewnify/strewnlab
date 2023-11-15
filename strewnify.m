%STREWNIFY Monte Carlo Meteor Simulation.
%   STREWNIFY simulates a meteor impact with earth and predicts a meteorite
%   strewn field.
%
%   Program originally written by Jim Goodall, April 2018

diary off

% Load config file
if ~exist('check_configloaded','var') || ~check_configloaded
    strewnconfig
end

if ~stealth
    load splat % load splat sound
end

% Load event data
if ~exist('check_eventdataloaded','var') || ~check_eventdataloaded
    load_eventdata
end

% Update file and folder names
syncevent

% Create or update the simulation monitor
if ~exist('SimMonitor','var')
    sim_index = 1;
    sim_time = datetime('now','TimeZone','UTC');
    sim_scenario = 0;
    frag_index = 1;
    if foldercreated
        sim_status = "init - new event folder created";
    else
        sim_status = "init";
    end
    SimMonitor = table(sim_index, sim_time, sim_scenario, frag_index, sim_status);
    
else
    sim_index = sim_index + 1;
    sim_time = datetime('now','TimeZone','UTC');
    SimMonitor.sim_index(sim_index) = sim_index;
    SimMonitor.sim_time(sim_index) = sim_time;
    SimMonitor.sim_scenario(sim_index) = sim_scenario;
    SimMonitor.frag_index(sim_index) = frag_index;
    if foldercreated
        SimMonitor.sim_status(sim_index) = "re-init - new event folder created";
    else
        SimMonitor.sim_status(sim_index) = "re-init";
    end    
end

% If the waitbar was closed, open a new one
if ~exist('WaitbarHandle','var') || ~ishghandle(WaitbarHandle)
    WaitbarHandle = waitbar(0,'Please wait...');
    movegui(WaitbarHandle,[-100 500])  
end
   
% Add timeout dialog here
if ~exist('check_weatherloaded','var') || ~check_weatherloaded
    getweather
end

% Initialize plots
if speedplot
    handle_speedplot = figure;
    %plot(ref_speed,0,'x','MarkerSize',ref_marksize)
    hold on
    title('Projectile Speed')
    ylabel('Altitude, km');
    xlabel('Speed, km/s');
end
if timeplot
    handle_timeplot = figure;
    
    hold on
    title('Distance vs. Altitude')
    xlabel('Distance, km');
    ylabel('Altitude, km');
end

% start
plotlevel = ground;  %generate strewn field at this level, useful for estimating radar
%test = erfinv(confidence/100)*sqrt(2);  % experimental confidence interval
while (sim_scenario < 8000)
clc % clear window
clear projectile % clear projectile data from previous simulation
clear splits   

% Update monitor
warning('off','MATLAB:table:RowsAddedExistingVars')
sim_index = sim_index + 1;
sim_time = datetime('now','TimeZone','UTC');
sim_scenario = sim_scenario + 1;
SimMonitor.sim_index(sim_index) = sim_index;
SimMonitor.sim_time(sim_index) = sim_time;
SimMonitor.sim_scenario(sim_index) = sim_scenario;
SimMonitor.frag_index(sim_index) = frag_index;
SimMonitor.sim_status(sim_index) = "new scenario";
SimMonitor

% Reset marksize to default
marksize = default_marksize;

% Calculate random inputs, based on nominal values and known uncertainty
bearing = wrapTo360(randbetween(nom_bearing - error_bearing, nom_bearing + error_bearing)); % initial bearing, use to align wind to x-axis
angledeg = randbetween(nom_angle - error_angle, nom_angle + error_angle); % incidence angle from vertical
if angledeg >= 90 || angledeg < 0
    angledeg
    error('incidence angle invalid')       
end
ref_latitude = randbetween(nom_lat - error_lat, nom_lat + error_lat); % known latitude, in decimal degrees
ref_longitude = randbetween(nom_long - error_long, nom_long + error_long); % known longitude, in decimal degrees
geometric_ref_elevation = randbetween(geometric_elevation - error_elevation, geometric_elevation + error_elevation); % known altitude, in meters above sea level
entryspeed = randbetween(nom_speed - error_speed, nom_speed + error_speed); % known speed, at known position
lowmass = nom_mass*(0.5*nom_mass*entryspeed^2)^-0.075;  % minimum mass from photometric estimate
highmass = nom_mass*(0.5*nom_mass*entryspeed^2)^0.075;  % maximum mass from photometric estimate
lowenergy_kt = mv2energy(lowmass,nom_speed - error_speed); 
highenergy_kt = mv2energy(highmass,nom_speed + error_speed);
entrymass = nom_mass*(0.5*nom_mass*entryspeed^2)^randbetween(-0.075,0.075); % simulation entry mass, from photometric estimate

% Generate weather data based on normal distribution variation plus or minus sigma
error_wind = randnsigma(0,1,sigma_thresh,weather_minsigma,weather_maxsigma);

if error_wind >= 0
    windn = (1-error_wind) * EventData_WINDN_MODEL(EventData_altitudes) + error_wind .* EventData_WINDN_MAX_MODEL(EventData_altitudes);    
    winde = (1-error_wind) * EventData_WINDE_MODEL(EventData_altitudes) + error_wind .* EventData_WINDE_MAX_MODEL(EventData_altitudes);    
else
    windn = (1+error_wind) * EventData_WINDN_MODEL(EventData_altitudes) - error_wind .* EventData_WINDN_MIN_MODEL(EventData_altitudes);    
    winde = (1+error_wind) * EventData_WINDE_MODEL(EventData_altitudes) - error_wind .* EventData_WINDE_MIN_MODEL(EventData_altitudes); 
end
windspeed = (windn.^2 + winde.^2).^0.5;
winddir = wrapTo360(atan2d(winde,windn));
windspeed_model = griddedInterpolant(EventData_altitudes,windspeed,'linear','nearest');
winddir_model = griddedInterpolant(EventData_altitudes,winddir,'linear','nearest'); 

% Copy weather models that do not currently support sigma variation
temperature_model = EventData_TEMPERATURE_MODEL;
pressure_model = EventData_PRESSURE_MODEL;
density_model = EventData_DENSITY_MODEL;

% Material selection
% If random is selected, select a random material based on fall
% distribution of specific materials
% stony - 90%, iron - 4%, carbonaceous - 5%, stony-iron - 1% 
% undiscovered materials also included
if strcmpi(material_sim,'random')
    possible_materials = [repmat({'stony'},1,90) repmat({'iron'},1,4) repmat({'carbonaceous'},1,5) repmat({'stony-iron'},1,1) repmat({'undiscovered-LD'},1,1) repmat({'undiscovered-HD'},1,1)];
    meteoroid_material = possible_materials{randi(size(possible_materials,2),1)};
% otherwise, use input material
else
    meteoroid_material = material_sim;
end

% Define forced splits
% parent body n, altitude z, mass m
% [n1 n2 n3...; z1 z2 z3...; m1 m2 m3]
% Example: [ 1 1 1 2; 24344 24344 21000 21000; 0.103 0.050 0.010 0.0003];
predefinedsplits = true;
lognrndmultlow = 0.001; % typically 0.001
lognrndmulthigh = 0.1; % typically 0.1
count1 = randbetween(2,100); % number of fragments

for i = 1:count1
    splits(i,1) = 1;
    splits(i,2) = randbetween(darkflight_elevation,fragaltitude);
    splits(i,3) = lognrnd(2.52,1.41,1,1)*randbetween(lognrndmultlow,lognrndmulthigh);
end
%     % chelyabinsk
%     
%     splits(i+1,1) = 1;
%     splits(i+1,2) = randbetween(25000,30000);
%     splits(i+1,3) = 3225;
%     % CHELYABINSK
splits = sortrows(splits,-2);

SplitProbability = 0; %randbetween(40,300); %roughly 40
SplitChanceMax = 0; %roughly 2 

% Calculate release vector
slope = -1/tan(degtorad(angledeg));
startposition = [(startaltitude - geometric_ref_elevation) / slope 0 startaltitude];
endposition = [-(geometric_ref_elevation - ground) / slope 0 ground];
ref_position = [0 0 geometric_ref_elevation];

% Limit path length for shallow entry angles
% If path length is exceeded, set the start altitude such that the
% half of the allowed path length is before the reference point
startseg = norm(startposition - ref_position); % length of the start segment in meters
endseg = norm(endposition - ref_position); % length of the end segment in meters
if (endseg + startseg) > max_pathlength3D_m
    eff_startaltitude = geometric_ref_elevation + ((max_pathlength3D_m/2)/startseg)*(startaltitude - geometric_ref_elevation);
    warning(['Extreme entry angle, start altitude adjusted to ' num2str(eff_startaltitude/1000) 'km'])
    startposition = [(eff_startaltitude - geometric_ref_elevation) / slope 0 eff_startaltitude];       
else
    eff_startaltitude = startaltitude;
end

% Calculation start and end locations
AZ = bearing + atan2d(-startposition(2),startposition(1)); % convert position to azimuth angle
ARCLEN = norm([startposition(1),startposition(2)]); % distance in meters
startlocation = reckon(ref_latitude, ref_longitude, ARCLEN, AZ,planet.ellipsoid_m); 
AZ = bearing + atan2d(-endposition(2),endposition(1)); % convert position to azimuth angle
ARCLEN = norm([endposition(1),endposition(2)]); % distance in meters
endlocation = reckon(ref_latitude, ref_longitude, ARCLEN, AZ,planet.ellipsoid_m); 

% Calculate distance to reference point
ref_flightdist = norm(startposition - ref_position);

% Set elevation limits for graphing
ZMIN = ground;
ZMAX = eff_startaltitude;

% find the size of the ground plot area
pathheight = eff_startaltitude - ground;
dlat_meters = abs(startlocation(1)-endlocation(1))*111200;
dlong_meters = abs(startlocation(2)-endlocation(2))*long_metersperdeg;
plotradius = max([pathheight dlat_meters dlong_meters])/2;
dlat_plot = plotradius / 111200;
dlong_plot = plotradius / long_metersperdeg;

% average latitude and longitude for the path
meanlat = mean([startlocation(1) endlocation(1)]);
meanlong = mean([startlocation(2) endlocation(2)]);

% plot limits
MINLAT = meanlat - dlat_plot;
MAXLAT = meanlat + dlat_plot;
MINLONG = meanlong - dlong_plot;
MAXLONG = meanlong + dlong_plot;

% MINLONG = nom_long - plot_elevation/169416.913;
% MAXLONG = nom_long + plot_elevation/169416.913;
% MINLAT = nom_lat - plot_elevation/222403.0152;
% MAXLAT = nom_lat + plot_elevation/222403.0152;
XMIN = startposition(1);
XMAX = endposition(1);
YMIN = 0;
YMAX = YMIN - (XMAX - XMIN);

% Calculate a camera view location for the plot
cam_lat_offset = -0.05;
cam_long_offset = 0.05 * sign(endlocation(2)-startlocation(2));
cam_elevation = 20000;
%cam_location = startlocation+0.9*(endlocation - startlocation) + [cam_lat_offset cam_long_offset];
%cam_location = [flip(cam_location) cam_elevation];
%cam_location = [-83.912 42.4359 60000];

% Display progress
fprintf('Running Total: %0.0f meteorites modeled. \n', frag_index)
disp('Please wait... ');

if useplot
    handle_trajectoryplot = figure;
    set(1,'Position',[100,90,1200,900])
    plot3(ref_longitude,ref_latitude,ref_elevation,'bx','MarkerSize',ref_marksize)
    plot3(-112.716640, 34.761939,4800,'bD','MarkerSize',ref_marksize)
    plot3(-112.639759, 34.774645,6200,'bD','MarkerSize',ref_marksize)
    plot3([startlocation(2) endlocation(2)],[startlocation(1) endlocation(1)],[startposition(3), endposition(3)])
    hold on
    title(['Simulation: ' SimulationName])
    xlabel('Longitude');
    ylabel('Latitude');
    zlabel('Altitude, meters');
    
end

% Simulation variables
n = 1;
rockcount = 1;
inflightcount = 1;
splitcounter = 1;
plotcounter = 0;
history = 2; % preallocation size
current = 1;
previous = 2;
impactcounter = 0;
zmax = -9999999;
zmax_current = -9999999;
vmax_current = -9999999;
vmax_previous = 9999999;
maxtimestep = 9999999;
    
% Initialize Arrays
t = zeros(history,1); % time in seconds
timestep = zeros(history,1);
projectile(n).position = zeros(history,3); % 3D position in meters
projectile(n).location = zeros(history,2); % 2D location in latitude and longitude
projectile(n).spin = zeros(history,3);
projectile(n).velocity = zeros(history,3);
projectile(n).speed = zeros(history,1);
projectile(n).flightdist = zeros(history,1);
projectile(n).acceleration = zeros(history,3);
projectile(n).unitvector = zeros(history,3);
projectile(n).force = zeros(history,3);
projectile(n).windvelocity = zeros(history, 3);
projectile(n).airspeed = zeros(history,1);
projectile(n).airvelocity = zeros(history,3);
projectile(n).Mach = zeros(history,1);
projectile(n).pressure = zeros(history,1);
projectile(n).temperature = zeros(history,1);
projectile(n).rho = zeros(history,1);
projectile(n).DragForce = zeros(history,3);
projectile(n).dMdt = zeros(history,1);
projectile(n).MagnusForce = zeros(history,3);
projectile(n).CD = zeros(history,1);
projectile(n).v_terminal = zeros(history,1);
projectile(n).flighttime = 0;
projectile(n).inflight = 1;
projectile(n).landed = 0;
projectile(n).xend = 0;
projectile(n).yend = 0;
projectile(n).vend = 0;
projectile(n).fdist = 0;
projectile(n).impactenergy = 0;
projectile(n).parent = 0;
projectile(n).flighttime = 0;
projectile(n).flightcounter = 0;
projectile(n).ref_time = 0;
projectile(n).ref_determined_altitude = 0;
projectile(n).ref_determined_speed = 0;
projectile(n).ref_determined_slope = 0;
projectile(n).darkflight = 0;
projectile(n).ablated = false;

projectile(n).ref_altitude_corr = 0;
projectile(n).ref_speed_corr = 0;
projectile(n).ref_slope_corr = 0;

[nom_density, error_density, HTC, ablationheat, dot_mark] = materialprops(meteoroid_material);

% Estimate strewn mass
strewnmass_predicted = eststrewnmass(entrymass,entryspeed,ablationheat, HTC);

projectile(n).mass = entrymass; 
projectile(n).cubicity = randnsigma(cubicity_mean,cubicity_stdev,sigma_thresh,cubicity_min,cubicity_max);
if meas_density == 0
    density = randbetween(nom_density - error_density, nom_density + error_density);
else
    density = randbetween(meas_density * (1-meas_density_err), meas_density * (1+meas_density_err));
end
projectile(n).density = density;
projectile(n).frontalareamult = randnsigma(frontalareamult_mean,frontalareamult_stdev,sigma_thresh,frontalareamult_min,frontalareamult_max);

% Generate projectile spin
randomvector = [rand rand rand];
randomunitvector = randomvector ./ norm(randomvector);
spinmagnitude = lognrnd(2.52,1,1,1)*0.00001;
projectile(n).spin(current,:) = spinmagnitude .* randomunitvector;

% Projectile calculations
projectile(n).volume = projectile(n).mass/projectile(n).density;
projectile(n).radius = (0.75 * projectile(n).volume / pi)^(1/3);
projectile(n).diameter = projectile(n).radius*2;
projectile(n).frontalarea = pi*projectile(n).radius^2*projectile(n).frontalareamult; % frontal area in m^2
projectile(n).noseradius = sqrt(projectile(n).frontalarea / pi);
projectile(n).shapefactor = projectile(n).frontalarea / (projectile(n).volume)^(2/3);

% Initial conditions
% Position specified as [x y z]
% Positive x = direction of motion
% Positive y = left
% Positive z = up

% Calculate release vector
vector = endposition - startposition;
projectile(n).unitvector(current,:) = vector/norm(vector);
    
projectile(n).x0 = startposition(1);
projectile(n).y0 = 0;
projectile(n).z0 = eff_startaltitude;
projectile(n).v0 = entryspeed;

% Progress Bar
if projectile(n).z0 > zmax
    zmax = projectile(n).z0;
    zmax_current = zmax;
end

% Calculate initial vectors
projectile(n).position(current,:) = [projectile(n).x0 0 projectile(n).z0];
projectile(n).speed(current) = projectile(n).v0;
projectile(n).velocity(current,:) = projectile(n).speed(current) * projectile(n).unitvector(current,:);

% Calculation initial latitude and longitude location
AZ = bearing + atan2d(-projectile(n).position(current,2),projectile(n).position(current,1)); % convert position to azimuth angle
ARCLEN = norm([projectile(n).position(current,1),projectile(n).position(current,2)]); % distance in meters
projectile(n).location(current,:) = reckon(ref_latitude, ref_longitude, ARCLEN, AZ,planet.ellipsoid_m); 

% Calculate initial conditions
projectile(n).pressure(current) = pressure_model(projectile(n).position(current,3));
projectile(n).temperature(current) = temperature_model(projectile(n).position(current,3));
projectile(n).rho(current) = density_model(projectile(n).position(current,3));
%             [projectile(n).pressure(current), projectile(n).temperature(current), projectile(n).rho(current)] = ...
%                 barometric(psurf_Pa,TsurfC,ground,projectile(n).position(current,3));
[projectile(n).windvelocity(current,1), projectile(n).windvelocity(current,2), projectile(n).windvelocity(current,3)] = windlookup(projectile(n).position(current,3), windspeed_model, winddir_model, bearing, ground);
projectile(n).airvelocity(current,:) = -projectile(n).velocity(current,:) + projectile(n).windvelocity(current,:);
projectile(n).airspeed(current) = norm(projectile(n).airvelocity(current,:));
projectile(n).speedsound = 20.05*sqrt(projectile(n).temperature(current)+273.15); % local speed of sound
projectile(n).Mach(current) = projectile(n).airspeed(current)/projectile(n).speedsound; % local Mach number
projectile(n).CD(current) = dragcoef(projectile(n).Mach(current), projectile(n).cubicity);
airvelocityunitvector = projectile(n).airvelocity(current,:)/norm(projectile(n).airvelocity(current,:));
projectile(n).DragForce(current,:) = airvelocityunitvector(current,:).*dragforce(projectile(n).airspeed(current), projectile(n).rho(current), projectile(n).CD(current), projectile(n).frontalarea);
g = ref.G_constant*planet.mass_kg/(planet.ellipsoid_m.MeanRadius + projectile(n).position(current,3))^2;
projectile(n).v_terminal(current) = sqrt((2*projectile(n).mass*g)/(projectile(n).rho(current)*projectile(n).frontalarea*projectile(n).CD(current)));
projectile(n).MagnusForce(current,:) = MagnusMult * 8/3 * pi * projectile(n).radius^3 * projectile(n).rho(current) * projectile(n).CD(current) * cross(projectile(n).airvelocity(current,:), projectile(n).spin(current,:));
projectile(n).force(current,1) = projectile(n).DragForce(current,1); % drag force in the x direction
projectile(n).force(current,2) = projectile(n).DragForce(current,2); % drag force in the y direction
projectile(n).force(current,3) = projectile(n).DragForce(current,3)-ref.G_constant*planet.mass_kg*projectile(n).mass/(planet.ellipsoid_m.MeanRadius + projectile(n).position(current,3))^2; % z drag force and gravity applied down
projectile(n).acceleration(current,:) = projectile(n).force(current,:)./ projectile(n).mass;
projectile(n).maxtimestep = 99999;

if useplot
    %Update projectile position plot
    figure(handle_trajectoryplot)
    camproj('orthographic')
    %camproj('perspective')
    axis([MINLONG MAXLONG MINLAT MAXLAT ZMIN ZMAX]);
    daspect([1/long_metersperdeg 1/lat_metersperdeg 1])
    plot3(projectile(n).location(current,2), projectile(n).location(current,1), projectile(n).position(current,3),mark,'MarkerSize',marksize*projectile(n).diameter);
    grid on
end

if speedplot
    %Update projectile speed plot
    figure(handle_speedplot)
    VMAX = max([projectile.v0]);
    %axis([XMIN XMAX 0 VMAX]);
    %scatter(projectile(1).speed(current)/1000,projectile(1).position(current,3)/1000,'r.')
end

if timeplot
    %Update projectile speed plot
    figure(handle_timeplot)
    VMAX = max([projectile.v0]);
    
    %scatter(t(current), projectile(1).position(current,3)/1000,'b.')
end

% Time-based Simulation
while inflightcount > 0
    % Progress Bar
    zmax_current = -9999999;
    vmax_current = -9999999;
    maxtimestep_prev = maxtimestep;
    maxtimestep = 500;
    for n = 1:rockcount
        if projectile(n).inflight > 0
            if projectile(n).position(current,3) > zmax_current
                zmax_current = projectile(n).position(current,3);
            end
            if projectile(n).speed(current) > vmax_current
                vmax_current = projectile(n).speed(current);
            end
            if projectile(n).position(current,3) < 20000 && projectile(n).position(current,3) > projectile(n).position(previous,3)
                fprintf('Error: Projectile %d has changed direction.\n', n);
            end
            if projectile(n).maxtimestep < maxtimestep
                maxtimestep = projectile(n).maxtimestep;
            end
            if projectile(n).flighttime > maxflighttime
                projectile(n).inflight = 0;
                inflightcount = inflightcount - 1;
                fprintf('Error: Projectile %d reached max flight time.\n',n)
            end
        end
    end
    
    if plotcounter > plotstep && ~stealth
        try
            waitbar((zmax-zmax_current)/(zmax-plotlevel),WaitbarHandle,sprintf('%0.0f Meteorites in Flight, %d Landed\nt = %0.2fs, vmax = %0.0f m/s', inflightcount, impactcounter, t(current), vmax_current));
        catch
            strewnbackup
            error([newline 'Simulation stopped by user. A backup workspace has been saved to:  ' exportfolder newline newline 'To restart simulation, type ''strewnify''.']);
        end
    end
    
    % Store time history
    for i = history:-1:2
        t(i) = t(i-1);
        timestep(i) = timestep(i-1);
    end
    
    
    % Set timestep
    
    timestep(current) = min(maxtimestep,distancestep/vmax_current);
    t(current) = t(previous) + timestep(current);
    
    for n = 1:rockcount
       
        if projectile(n).position(current,3) > plotlevel && projectile(n).inflight > 0
                        
            % Calculate local barometric conditions
            projectile(n).pressure(current) = pressure_model(projectile(n).position(current,3));
            projectile(n).temperature(current) = temperature_model(projectile(n).position(current,3));
            projectile(n).rho(current) = density_model(projectile(n).position(current,3));
%             [projectile(n).pressure(current), projectile(n).temperature(current), projectile(n).rho(current)] = ...
%                 barometric(psurf_Pa,TsurfC,ground,projectile(n).position(current,3));
            
            % Ablation Simulation
            % loss of mass, due to high temperature evaporation           
            if projectile(n).mass > minmass
                projectile(n).dMdt(current) = (HTC*projectile(n).frontalarea*projectile(n).rho(current)*(projectile(n).speed(current))^3)/(2*ablationheat);
                projectile(n).ablationrate = projectile(n).dMdt(current)/projectile(n).mass;
                projectile(n).mass = projectile(n).mass - projectile(n).dMdt(current) * timestep(current);
                
                % Detect if ablation occurred
                if projectile(n).ablated == false && projectile(n).dMdt(current) >= ablation_thresh
                    projectile(n).ablated = true;
                end
                
                % Detect min mass
                if projectile(n).mass < minmass
                    projectile(n).mass = minmass;
                    projectile(n).inflight = 0;
                    inflightcount = inflightcount - 1;
                    projectile(n).darkflight = projectile(n).position(current,3);
                    fprintf('Projectile %d burned up.\n',n)
                end
                
                % If the fragment still exists, check for darkflight
                if projectile(n).inflight && projectile(n).ablated == true && projectile(n).dMdt(current) < ablation_thresh && projectile(n).darkflight == 0
                        projectile(n).darkflight = projectile(n).position(current,3);
                        
                end
%                 
%                 % Chely Testing
%                 if projectile(n).mass > 400000 && projectile(n).inflight && projectile(n).ablated == true && projectile(n).position(current,3) <= 12600 && projectile(n).position(previous,3) > 12600  
%                     ablation_12600(end+1) = projectile(n).dMdt(current);
%                 end
                projectile(n).volume = projectile(n).mass/projectile(n).density;
                projectile(n).radius = (0.75 * projectile(n).volume / pi)^(1/3);
                projectile(n).diameter = projectile(n).radius*2;
                projectile(n).frontalarea = pi*projectile(n).radius^2*projectile(n).frontalareamult; % frontal area in m^2
            
            end
            % end Ablation Simulation
            
            % Calculate local wind conditions
            [projectile(n).windvelocity(current,1), projectile(n).windvelocity(current,2), projectile(n).windvelocity(current,3)] = windlookup(projectile(n).position(current,3), windspeed_model, winddir_model, bearing, ground);
            projectile(n).airvelocity(current,:) = -projectile(n).velocity(current,:) + projectile(n).windvelocity(current,:);
            projectile(n).airspeed(current) = norm(projectile(n).airvelocity(current,:));
            projectile(n).speedsound = 20.05*sqrt(projectile(n).temperature(current)+273.15); % local speed of sound
            projectile(n).Mach(current) = projectile(n).airspeed(current)/projectile(n).speedsound; % local Mach number
            projectile(n).CD(current) = dragcoef(projectile(n).Mach(current), projectile(n).cubicity);
            airvelocityunitvector = projectile(n).airvelocity(current,:)/norm(projectile(n).airvelocity(current,:));
            projectile(n).DragForce(current,:) = airvelocityunitvector(current,:).*dragforce(projectile(n).airspeed(current), projectile(n).rho(current), projectile(n).CD(current), projectile(n).frontalarea);
            projectile(n).MagnusForce(current,:) = MagnusMult * 8 * pi / 3 * projectile(n).radius * projectile(n).rho(current) * projectile(n).CD(current) * cross(projectile(n).velocity(current,:), projectile(n).spin(current,:));
            g = ref.G_constant*planet.mass_kg/(planet.ellipsoid_m.MeanRadius + projectile(n).position(current,3))^2;
            projectile(n).v_terminal(current) = sqrt((2*projectile(n).mass*g)/(projectile(n).rho(current)*projectile(n).frontalarea*projectile(n).CD(current)));
            projectile(n).force(current,1) = projectile(n).DragForce(current,1) + projectile(n).MagnusForce(current,1); % drag force in the x direction
            
%             % **** CORIOLIS ADDED - TEMPORARY TEST for France
%             % This calculation will not work for other trajectories
%             
%             if projectile(n).position(current,3) < darkflight_elevation
%                 [X, Y, Z] = geodetic2ecef(planet.ellipsoid_m, 47.359449, 2.279083, projectile(n).position(current,3));
%                 vectorspeed = 0.707.*projectile(n).velocity(current,3);
%                 fict_vector = fict_forces(projectile(n).mass,[X Y Z],[vectorspeed vectorspeed 0]);
%                 FICTITIOUS = fict_vector(2);
%             else
%                FICTITIOUS = 0; 
%             end
%                         
%             % *** CORIOLIS ADDED *****  see line 565
            
            projectile(n).force(current,2) = projectile(n).DragForce(current,2) + projectile(n).MagnusForce(current,2); %- FICTITIOUS; % drag force in the y direction
            projectile(n).force(current,3) = projectile(n).DragForce(current,3) + projectile(n).MagnusForce(current,3) - ref.G_constant*planet.mass_kg*projectile(n).mass/(planet.ellipsoid_m.MeanRadius + projectile(n).position(current,3))^2; % gravity applied down

            % Shift data to previous
            for i = history:-1:2
                projectile(n).v_terminal(i) = projectile(n).v_terminal(i-1);
                projectile(n).airspeed(i) = projectile(n).airspeed(i-1);
                projectile(n).windvelocity(i,:) = projectile(n).windvelocity(i-1,:);
                projectile(n).airvelocity(i,:) = projectile(n).airvelocity(i-1,:);
                projectile(n).acceleration(i,:) = projectile(n).acceleration(i-1,:);
                projectile(n).Mach(i) = projectile(n).Mach(i-1);
                projectile(n).velocity(i,:) = projectile(n).velocity(i-1,:);
                projectile(n).speed(i) = projectile(n).speed(i-1);
                projectile(n).flightdist(i) = projectile(n).flightdist(i-1);
                projectile(n).position(i,:) = projectile(n).position(i-1,:);
                projectile(n).location(i,:) = projectile(n).location(i-1,:);
                projectile(n).force(i,:) = projectile(n).force(i-1,:);
                projectile(n).spin(i,:) = projectile(n).spin(i-1,:);
                projectile(n).MagnusForce(i,:) = projectile(n).MagnusForce(i-1,:);
                projectile(n).DragForce(i,:) = projectile(n).DragForce(i-1,:);
                projectile(n).dMdt(i) = projectile(n).dMdt(i-1);
            end
            
            % Calculate new position and velocity
            projectile(n).position(current,:) = projectile(n).position(previous,:) + projectile(n).velocity(previous,:) .* timestep(current) + ...
                0.5 .* projectile(n).acceleration(previous,:) .* timestep(current)^2; 
            projectile(n).velocity(current,:) = projectile(n).velocity(previous,:) + projectile(n).acceleration(previous,:) .* timestep(current);
            projectile(n).speed(current) = norm(projectile(n).velocity(current,:));
            speedratio = projectile(n).speed(current)/projectile(n).speed(previous);
            projectile(n).spin(current,:) = projectile(n).spin(previous,:) * speedratio;  % angular acceleration proportional to change in velocity
                        
            % Calculation latitude and longitude location
            AZ = bearing + atan2d(-projectile(n).position(current,2),projectile(n).position(current,1)); % convert position to azimuth angle
            ARCLEN = norm([projectile(n).position(current,1),projectile(n).position(current,2)]); % distance in meters
            projectile(n).location(current,:) = reckon(ref_latitude, ref_longitude, ARCLEN, AZ,planet.ellipsoid_m); 
            
            % Calculate new acceleration
            projectile(n).acceleration(current,:) = projectile(n).force(current,:)./ projectile(n).mass;
                        
            % Update flight counters
            projectile(n).flighttime = projectile(n).flighttime + timestep(current);
            projectile(n).flightcounter = projectile(n).flightcounter + 1;
            projectile(n).flightdist(current) = projectile(n).flightdist(previous) + norm(projectile(n).position(current,:)-projectile(n).position(previous,:));
            
            
            if (projectile(n).flightdist(previous) < ref_flightdist && projectile(n).flightdist(current) >= ref_flightdist)
                projectile(n).ref_time = t(current);
                projectile(n).ref_determined_altitude = projectile(n).position(current,3);
                projectile(n).ref_determined_speed = projectile(n).speed(current);
                dz = projectile(n).position(current,3)-projectile(n).position(previous,3);
                dp = norm(projectile(n).position(current,:)-projectile(n).position(previous,:));
                projectile(n).ref_determined_slope = rad2deg(acos(-dz/dp));
                projectile(n).ref_altitude_corr = ref_elevation - projectile(n).ref_determined_altitude; 
                projectile(n).ref_speed_corr = ref_speed - projectile(n).ref_determined_speed;
                projectile(n).ref_slope_corr = ref_slope - projectile(n).ref_determined_slope;
            end
                      
            % Calculate max timestep
            projectile(n).maxtimestep_prev = projectile(n).maxtimestep;
            timetostop = norm(projectile(n).velocity(current,:))/norm(projectile(n).acceleration(current,:)); % time for speed to reach zero
            timetoimpact(1) = -(projectile(n).velocity(current,3)+sqrt(projectile(n).velocity(current,3)^2 + 2*projectile(n).acceleration(current,3)*plotlevel - 2*projectile(n).acceleration(current,3)*projectile(n).position(current,3)))/projectile(n).acceleration(current,3);
            timetoimpact(2) = -(projectile(n).velocity(current,3)-sqrt(projectile(n).velocity(current,3)^2 + 2*projectile(n).acceleration(current,3)*plotlevel - 2*projectile(n).acceleration(current,3)*projectile(n).position(current,3)))/projectile(n).acceleration(current,3);
            projectile(n).timetoimpact = min(timetoimpact(timetoimpact>0)); % quadratic solutions
            if isreal(projectile(n).timetoimpact)
            projectile(n).maxtimestep = min(timetostop/2,projectile(n).timetoimpact);
            else
                projectile(n).maxtimestep = timetostop/2;
            end
        end        
        % If the meteorite has landed, store data
        if projectile(n).position(current,3) <= plotlevel && projectile(n).inflight > 0
            impactcounter = impactcounter + 1;
            %sound(y,Fs);
            projectile(n).position(current,3) = plotlevel;
            projectile(n).xend = projectile(n).position(current,1);
            projectile(n).yend = projectile(n).position(current,2);
            projectile(n).vend = projectile(n).speed(current);
            projectile(n).fdist = norm([projectile(n).xend projectile(n).yend]);
            projectile(n).impactenergy = 0.5 * projectile(n).mass * (projectile(n).speed(current))^2;
            projectile(n).impacttime = t(current);
            projectile(n).inflight = 0;
            projectile(n).landed = 1;
            inflightcount = inflightcount - 1;
            
%             % Chely Testing
%             if projectile(n).mass > 400000 && projectile(n).mass < 600000
%                 ablation_ground(end+1) = projectile(n).dMdt(current)
%             end
        end
        
        % Otherwise, predict break-up, generate new meteors
        if projectile(n).inflight > 0
            % Check pre-defined splits
            forcesplit = false; % initialize
            if predefinedsplits &&...
                    splitcounter <= size(splits,1) && splits(splitcounter,1) == n &&...
                    projectile(n).position(current,3) <= splits(splitcounter,2)
                forcesplit = true;
                splitmass = splits(splitcounter,3);
                splitcounter = splitcounter + 1;           
            else
                splitchance = min(SplitChanceMax,SplitProbability*log(1+projectile(n).ablationrate))*timestep(current);
                if rand < splitchance
                    forcesplit = true;
                    splitmass = lognrnd(2.52,1.41,1,1)*randbetween(lognrndmultlow,lognrndmulthigh);
                end
            end 
            % if the parent or child mass is too small, skip the split
            if forcesplit && (projectile(n).mass - splitmass) < minmass
                forcesplit = false;
                %fprintf('Error: Split mass invalid\n');
            end

            % Determine if breakup occurs now and if the mass is large enough
            if forcesplit
                
                % Split the current projectile into two projectiles
                rockcount = rockcount + 1;
                inflightcount = inflightcount + 1;
                projectile(rockcount) = projectile(n);
                projectile(rockcount).mass = splitmass;
                projectile(n).mass = projectile(n).mass - projectile(rockcount).mass;
                
                % Old Projectile re-calculations
                randomvector = [rand rand rand];
                randomunitvector = randomvector ./ norm(randomvector);
                spinmagnitude = lognrnd(2.52,1,1,1)*0.00001;
                projectile(n).spin(current,:) = spinmagnitude .* randomunitvector;
                projectile(n).cubicity = randnsigma(cubicity_mean,cubicity_stdev,sigma_thresh,cubicity_min,cubicity_max);
                projectile(n).frontalareamult = randnsigma(frontalareamult_mean,frontalareamult_stdev,sigma_thresh,frontalareamult_min,frontalareamult_max);
                projectile(n).volume = projectile(n).mass/projectile(n).density;
                projectile(n).radius = (0.75 * projectile(n).volume / pi)^(1/3);
                projectile(n).diameter = projectile(n).radius*2;
                projectile(n).frontalarea = pi*projectile(n).radius^2*projectile(n).frontalareamult; % frontal area in m^2
                
                % New projectile properties 
                projectile(rockcount).parent = n;
                projectile(rockcount).cubicity = randnsigma(cubicity_mean,cubicity_stdev,sigma_thresh,cubicity_min,cubicity_max);
                projectile(rockcount).frontalareamult = randnsigma(frontalareamult_mean,frontalareamult_stdev,sigma_thresh,frontalareamult_min,frontalareamult_max);
                projectile(rockcount).ref_time = 0;
                projectile(rockcount).xend = 0;
                projectile(rockcount).yend = 0;
                projectile(rockcount).vend = 0;
                projectile(rockcount).fdist = 0;
                projectile(rockcount).impactenergy = 0;
                projectile(rockcount).impacttime = 0;
                projectile(rockcount).flightcounter = 0;
                projectile(rockcount).ref_determined_altitude = 0;
                projectile(rockcount).ref_determined_speed = 0;
                projectile(rockcount).ref_determined_slope = 0;
                projectile(rockcount).darkflight = 0;
                projectile(rockcount).ref_altitude_corr = 0;
                projectile(rockcount).ref_speed_corr = 0;
                projectile(rockcount).ref_slope_corr = 0;

                
                % New projectile spin
                randomvector = [rand rand rand];
                randomunitvector = randomvector ./ norm(randomvector);
                spinmagnitude = lognrnd(2.52,1,1,1)*0.00001;
                projectile(rockcount).spin(current,:) = spinmagnitude .* randomunitvector;
              
                % New Projectile calculations
                projectile(rockcount).volume = projectile(rockcount).mass/projectile(rockcount).density;
                projectile(rockcount).radius = (0.75 * projectile(rockcount).volume / pi)^(1/3);
                projectile(rockcount).diameter = projectile(rockcount).radius*2;
                projectile(rockcount).frontalarea = pi*projectile(rockcount).radius^2*projectile(rockcount).frontalareamult; % frontal area in m^2

                % Initial conditions
                % Position specified as [x y z]
                % Positive x = direction of motion
                % Positive y = left
                % Positive z = up

                projectile(rockcount).x0 = projectile(n).position(current,1);
                projectile(rockcount).y0 = projectile(n).position(current,2);
                projectile(rockcount).z0 = projectile(n).position(current,3);
                projectile(rockcount).v0 = projectile(n).speed(current);

                % Progress Bar
                if projectile(rockcount).z0 > zmax
                    zmax = projectile(rockcount).z0;
                    zmax_current = zmax;
                end

                % Calculate new projectile initial vectors
                projectile(rockcount).position(current,:) = projectile(n).position(current,:);
                projectile(rockcount).speed(current) = projectile(rockcount).v0;
                projectile(rockcount).flightdist = zeros(history,1);
                projectile(rockcount).velocity(current,:) = projectile(n).velocity(current,:);
                
                % Calculation latitude and longitude location
                AZ = bearing + atan2d(-projectile(rockcount).position(current,2),projectile(rockcount).position(current,1)); % convert position to azimuth angle
                ARCLEN = norm([projectile(rockcount).position(current,1),projectile(rockcount).position(current,2)]); % distance in meters
                projectile(rockcount).location(current,:) = reckon(ref_latitude, ref_longitude, ARCLEN, AZ,planet.ellipsoid_m); 

                % Calculate initial conditions
                projectile(rockcount).pressure(current) = pressure_model(projectile(rockcount).position(current,3));
                projectile(rockcount).temperature(current) = temperature_model(projectile(rockcount).position(current,3));
                projectile(rockcount).rho(current) = density_model(projectile(rockcount).position(current,3));
                %[projectile(rockcount).pressure(current), projectile(rockcount).temperature(current), projectile(rockcount).rho(current)] = barometric(psurf_Pa,TsurfC,ground,projectile(rockcount).position(current,3)); % air temperature estimate, as function of altitude
                [projectile(rockcount).windvelocity(current,1), projectile(rockcount).windvelocity(current,2), projectile(rockcount).windvelocity(current,3)] = windlookup(projectile(rockcount).position(current,3), windspeed_model, winddir_model, bearing, ground);
                projectile(rockcount).airvelocity(current,:) = -projectile(rockcount).velocity(current,:) + projectile(rockcount).windvelocity(current,:);
                projectile(rockcount).airspeed(current) = norm(projectile(rockcount).airvelocity(current,:));
                projectile(rockcount).speedsound = 20.05*sqrt(projectile(rockcount).temperature(current)+273.15); % local speed of sound
                projectile(rockcount).Mach(current) = projectile(rockcount).airspeed(current)/projectile(rockcount).speedsound; % local Mach number
                projectile(rockcount).CD(current) = dragcoef(projectile(rockcount).Mach(current), projectile(rockcount).cubicity);
                airvelocityunitvector = projectile(rockcount).airvelocity(current,:)/norm(projectile(rockcount).airvelocity(current,:));
                projectile(rockcount).DragForce(current,:) = airvelocityunitvector(current,:).*dragforce(projectile(rockcount).airspeed(current), projectile(rockcount).rho(current), projectile(rockcount).CD(current), projectile(rockcount).frontalarea);
                g = ref.G_constant*planet.mass_kg/(planet.ellipsoid_m.MeanRadius + projectile(rockcount).position(current,3))^2;
                projectile(rockcount).v_terminal(current) = sqrt((2*projectile(rockcount).mass*g)/(projectile(rockcount).rho(current)*projectile(rockcount).frontalarea*projectile(rockcount).CD(current)));
                projectile(rockcount).MagnusForce(current,:) = MagnusMult * 8 * pi / 3 * projectile(rockcount).radius * projectile(rockcount).rho(current) * projectile(rockcount).CD(current) * cross(projectile(rockcount).velocity(current,:), projectile(rockcount).spin(current,:));
                projectile(rockcount).force(current,1) = projectile(rockcount).DragForce(current,1); % drag force in the x direction
                projectile(rockcount).force(current,2) = projectile(rockcount).DragForce(current,2); % drag force in the y direction
                projectile(rockcount).force(current,3) = projectile(rockcount).DragForce(current,3)-ref.G_constant*planet.mass_kg*projectile(rockcount).mass/(planet.ellipsoid_m.MeanRadius + projectile(rockcount).position(current,3))^2; % gravity applied down
                projectile(rockcount).acceleration(current,:) = projectile(rockcount).force(current,:)./ projectile(rockcount).mass;
                projectile(rockcount).maxtimestep = norm(projectile(rockcount).velocity(current,:))./norm(projectile(rockcount).acceleration(current,:))/2; % half the time for speed to reach zero
            end
        end
    end
    
    % Update plots
    % Pause the simulation to simulate realtime
    if RealtimeMult < 100
        pause(floor((timestep(current)*100)/(RealtimeMult))/100);
        %fprintf('t = %0.2f, pause = %0.3f\n', t(1), floor(timestep(current)*plotstep/1.5/RealtimeMult/inflightcount*100)/100);
    end
    
    if useplot && plotcounter > plotstep
        plotcounter = 1;
        figure(handle_trajectoryplot)
        hold on
        if zmax_current + 100 < (darkflight_elevation * 2)
            ZMAX = max(darkflight_elevation + 2, zmax_current + 100);
            axis([MINLONG MAXLONG MINLAT MAXLAT ZMIN ZMAX]);
        end
        camtarget([projectile(1).location(current,2) projectile(1).location(current,1) projectile(1).position(current,3)])
        if ~exist('cam_location','var')
            cam_location = campos;
        end
        %campos(cam_location);
        cla
        plot3(startlocation(2),startlocation(1),startposition(3),'bx','MarkerSize',ref_marksize)
        plot3(ref_longitude,ref_latitude,ref_elevation,'bx','MarkerSize',ref_marksize)
        plot3(-112.716640, 34.761939,4800,'bD','MarkerSize',ref_marksize)
        plot3(-112.639759, 34.774645,6200,'bD','MarkerSize',ref_marksize)
        plot3([startlocation(2) endlocation(2)],[startlocation(1) endlocation(1)],[startposition(3), endposition(3)])
        
        for n = 1:rockcount
            if projectile(n).Mach(previous) > 1 && projectile(n).Mach(current) <= 1
                projectile(n).boomheight = projectile(n).position(current,3);
                projectile(n).boomtime = t(current);
                mark = 'rp';
                marksize = 3*default_marksize;
            end
            if projectile(n).dMdt(current)> ablation_thresh
                mark = 'ro';
            else
                mark = 'ko';
            end
            if projectile(n).position(current,3) > plotlevel && projectile(n).inflight > 0
                if useplot
                    %Update projectile position plot
                    figure(handle_trajectoryplot)
                    plot3(projectile(n).location(current,2), projectile(n).location(current,1), projectile(n).position(current,3),mark,'MarkerSize',marksize*projectile(n).diameter);
                end


            elseif useplot && projectile(n).position(current,3) == plotlevel
                figure(handle_trajectoryplot)
                plot3(projectile(n).location(current,2), projectile(n).location(current,1), projectile(n).position(current,3),'kx','MarkerSize',marksize*projectile(n).diameter)
            end
            % reset plot marker
            mark = 'bo';
            marksize = default_marksize;    
        end
    else
        plotcounter = plotcounter + 1;
    end
    
    % Optional plot
    for projectile_i = 1:size(projectile,2)

        if speedplot
            %Update projectile speed plot
            figure(handle_speedplot)
            VMAX = max([projectile.v0]);
    %         %axis([XMIN XMAX 0 VMAX]);
    
            % data collection
            data_idx = data_idx + 1;
            data_t(data_idx) = t(current);       
            data_ang(data_idx) = angledeg;
            data_rho(data_idx) = projectile(projectile_i).rho(current);                       
            data_dist(data_idx) = projectile(projectile_i).flightdist(current);
            data_matdens_kg(data_idx) = projectile(projectile_i).density(current);
            data_m_kg(data_idx) = projectile(projectile_i).mass(current);
            data_entry_v_kps(data_idx) = entryspeed/1000;

            data_v_kps(data_idx) = projectile(projectile_i).speed(current)/1000;
            data_z_km(data_idx) = projectile(projectile_i).position(current,3)/1000;
            
            % plot data
            %scatter(projectile(projectile_i).speed(current)/1000, projectile(projectile_i).position(current,3)/1000,dot_mark)
        end
        % Optional plot
        if timeplot
            %Update projectile speed plot
            figure(handle_timeplot)
            VMAX = max([projectile.v0]);
    %         axis([XMIN XMAX 0 VMAX]);
            scatter(projectile(projectile_i).position(current,1)/1000, projectile(projectile_i).position(current,3)/1000,dot_mark)
        end
    end
end
                
if ~stealth
    % Update strewn field plot
    if exist('handle_strewn') && ishandle(handle_strewn)
        figure(handle_strewn)
    else
        handle_strewn = figure;
    end
    hold on
    daspect([1/long_metersperdeg 1/lat_metersperdeg 1])
    %movegui(handle_strewn,[-10 660])
    title([SimulationName ' Strewn Field'])
    xlabel('Longitude');
    ylabel('Latitude');
    axis([MINLONG MAXLONG MINLAT MAXLAT]);

    % plot finds, if available
    if exist('EventData_Finds','var')
        plotfinds
    end
    plot(ref_longitude,ref_latitude,'x','MarkerSize',ref_marksize)
    plot(-112.716640, 34.761939,'D','MarkerSize',ref_marksize)
    plot(-112.639759, 34.774645,'D','MarkerSize',ref_marksize)
end

% clear scenario stats
strewn_mass = 0;
strewn_count = 0;
strewn_mainmass = 0;
strewn_mainmass_n = 0;
darkflight = eff_startaltitude;
for n = 1:rockcount
    if projectile(n).mass < 0.001
        graphtext = cellstr(num2str(roundn(projectile(n).mass,-4)*1000));
    else
        graphtext = cellstr(num2str(roundn(projectile(n).mass,-3)*1000));
    end
    
    % If the projectile landed, graph and store data
    if projectile(n).position(current,3) == plotlevel
        if ~stealth
            text(projectile(n).location(current,2), projectile(n).location(current,1), graphtext, 'FontSize',6);
        end
        
        % Store landed fragments to struct
        strewn_struct.sim_scenario = sim_scenario;
        strewn_struct.entrymass = entrymass; 
        strewn_struct.angledeg = angledeg; 
        strewn_struct.bearing = bearing;
        strewn_struct.SplitProbability = SplitProbability;
        strewn_struct.geometric_ref_elevation = geometric_ref_elevation;
        strewn_struct.entryspeed = entryspeed;
        strewn_struct.error_wind = error_wind;
        strewn_struct.parent =  projectile(n).parent;
        strewn_struct.cubicity = projectile(n).cubicity;
        strewn_struct.material = {meteoroid_material};
        strewn_struct.density = projectile(n).density;
        strewn_struct.frontalareamult = projectile(n).frontalareamult;
        strewn_struct.n = n;
        strewn_struct.Longitude = projectile(n).location(current,2);
        strewn_struct.Latitude = projectile(n).location(current,1);
        strewn_struct.vend = projectile(n).vend;
        strewn_struct.impactenergy = projectile(n).impactenergy;
        strewn_struct.impacttime = projectile(n).impacttime;
        strewn_struct.mass = projectile(n).mass;
        strewn_struct.ref_time = projectile(n).ref_time;
        strewn_struct.ref_altitude_corr = projectile(n).ref_altitude_corr;
        strewn_struct.ref_speed_corr = projectile(n).ref_speed_corr;
        strewn_struct.ref_slope_corr = projectile(n).ref_slope_corr;
        strewn_struct.darkflight = projectile(n).darkflight;
        
        % Add data to table
        if exist('strewndata','var')
            if size(strewndata,2) == length(fieldnames(strewn_struct))
                strewndata = [strewndata; struct2table(strewn_struct)];
            else
                error('Loaded data is incompatible with current version.  Clear loaded data and restart simulation.')
            end
        else
            strewndata = struct2table(strewn_struct);
        end
                
        % Increment running total of all fragments simulated
        frag_index = frag_index + 1;
        
        % Increment strewn field counters
        strewn_mass = strewn_mass + projectile(n).mass;
        strewn_count = strewn_count + 1;
        
        % Scenario stats
        if projectile(n).mass > strewn_mainmass
            strewn_mainmass = projectile(n).mass;
            strewn_mainmass_n = n;
        end
        
        if projectile(n).darkflight < darkflight
            darkflight = projectile(n).darkflight;
        end
    end
    
end

% report scenario stats
SimMonitor.entrymass(sim_index) = entrymass;
SimMonitor.entryspeed(sim_index) = entryspeed;
SimMonitor.slope(sim_index) = angledeg;
SimMonitor.strewn_mass(sim_index) = strewn_mass;
SimMonitor.strewn_ratio(sim_index) = strewn_mass / entrymass;
SimMonitor.strewn_count(sim_index) = strewn_count;
SimMonitor.strewn_mainmass_n(sim_index) = strewn_mainmass_n;
SimMonitor.strewn_mainmass(sim_index) = strewn_mainmass;
SimMonitor.darkflight(sim_index) = darkflight;
SimMonitor.alt_corr(sim_index) = projectile(1).ref_altitude_corr;
SimMonitor.speed_corr(sim_index) = projectile(1).ref_speed_corr;
SimMonitor.slope_corr(sim_index) = projectile(1).ref_slope_corr;
SimMonitor.strewnmass_predicted(sim_index) = strewnmass_predicted;

% Backup the simulation results
try
    strewnbackup
catch
    failtime = datestr(datetime('now','TimeZone','UTC'),'yyyy/mm/dd HH:MM')
end

end
% Close program
if ~stealth
    waitbar(1,WaitbarHandle,'All meteorites landed!');
    close(WaitbarHandle)
    pause(1)
    disp('Done. ')
end
beep
