function [EventIDs] = alteventids(LAT, LONG, Datetime, error_minutes, radius_km)

EventIDs = {eventid(LAT, LONG, Datetime)};

% Initialize ellipsoid
earth = referenceEllipsoid('earth','km');

% To identify all possible grid zones inside of a circle, the grid zone is
% identified at 75km steps around the outside of the circle and then filled
% with possibilities
circ_step = 75; %km steps along circumference
radius_step = 100; %km steps in radius

if contains(EventIDs{1},'XXZ')
    Datetime_nom = [(Datetime - hours(24)):minutes(30):(Datetime + hours(24)) Datetime];    
else
    Datetime_nom = [(Datetime - minutes(error_minutes)):minutes(60):(Datetime + minutes(error_minutes)) Datetime];
end

% Step through times
id_i = 2;
for Datetime_nom = Datetime_nom
    
    if contains(EventIDs{1},'XXX')
        EventIDs(id_i,1) = {eventid(LAT,LONG,Datetime_nom)};
        id_i = id_i + 1;
    else
        % Step through radii
        for radius = [radius_step:radius_step:radius_km radius_km]

            circumference_km = pi*2*radius;
            az_step = 360*circ_step/circumference_km;
            az_steps = 0:az_step:360;
            numsteps = numel(az_steps);

            %preallocate arrays
            latout = zeros(numsteps,1);
            lonout = zeros(numsteps,1);

            % Step around circumference
            for az_i = 1:numsteps
                [latout(az_i),lonout(az_i)] = reckon(LAT,LONG,radius,az_steps(az_i),earth);
                EventIDs(id_i,1) = {eventid(latout(az_i),lonout(az_i),Datetime_nom)};
                id_i = id_i + 1;
            end        
        end
    end
end

EventIDs = unique(EventIDs);
EventIDs = sortrows(EventIDs,1);


