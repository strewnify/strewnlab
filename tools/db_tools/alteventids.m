function [EventIDs] = alteventids(LAT, LONG, Datetime, error_s, radius_km)

EventIDs = {eventid(LAT, LONG, Datetime)};

% Initialize ellipsoid
planet = getPlanet();

% To identify all possible grid zones inside of a circle, the grid zone is
% identified at 75km steps around the outside of the circle and then filled
% with possibilities
circ_step_km = 75; %km steps along circumference
radius_step_km = 100; %km steps in radius

if contains(EventIDs{1},'XXZ')
    Datetime_nom = [(Datetime - hours(24)):minutes(30):(Datetime + hours(24)) Datetime];    
else
    Datetime_nom = [(Datetime - seconds(error_s)):minutes(60):(Datetime + seconds(error_s)) Datetime];
end

% Step through times
id_i = 2;
for Datetime_inc = Datetime_nom
    
    if contains(EventIDs{1},'XXX')
        EventIDs(id_i,1) = {eventid(LAT,LONG,Datetime_inc)};
        id_i = id_i + 1;
    else
        % Step through radii
        for radius_km = [radius_step_km:radius_step_km:radius_km radius_km]

            circumference_km = pi*2*radius_km;
            az_step = 360*circ_step_km/circumference_km;
            az_steps = 0:az_step:360;
            numsteps = numel(az_steps);

            %preallocate arrays
            latout = zeros(numsteps,1);
            lonout = zeros(numsteps,1);

            % Step around circumference
            radius_m = radius_km.*1000;
            for az_i = 1:numsteps
                [latout(az_i),lonout(az_i)] = reckon(LAT,LONG,radius_m,az_steps(az_i),getPlanet('ellipsoid_m'));
                EventIDs(id_i,1) = {eventid(latout(az_i),lonout(az_i),Datetime_inc)};
                id_i = id_i + 1;
            end        
        end
    end
end

EventIDs = unique(EventIDs);
EventIDs = sortrows(EventIDs,1);


