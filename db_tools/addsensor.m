function db_Sensors_out = addsensor(db_Sensors_in, inputdata)
%ADDSENSOR Add a new sensor to the database

% Load config for default FOV
strewnconfig

% Initialize variables
planet = getPlanet();
prefix = ''; % Station ID prefix
default_BaseScore = 5;
new_sensor_type = '';

% Error checking
if nargin == 1 || nargin > 3
    logformat('ADDSENSOR requires 2 or 3 inputs.','ERROR')
end
if ~getSession('user','userpresent') && nargin == 2
    logformat('Input data required in scheduled function.','ERROR')
end

% Log request type
if getSession('user','userpresent')
    if nargin == 2
        logformat('User requested to add new sensor from manual input.','USER')
    elseif nargin == 3
        logformat('User requested to add new sensor from data table.','USER')
    end
else
    logformat('Automated sensor add routine started.','INFO')
end

% Copy the database to output
db_Sensors_out = db_Sensors_in;

% if no data was provided, prompt user
if nargin == 2
    
    % Get sensor type for this session
    while isempty(new_sensor_type)        
        sensor_types = categories(db_Sensors_in.Type);
        new_sensor_type = listdlg('ListString',sensor_types);
        new_sensor_type = convertCharsToStrings(sensor_types{new_sensor_type});
    end
    
    dlgtitle = 'Input Station Data';
    opts.WindowStyle = 'normal';
    prompt = {['Enter Data for new station.' newline 'Fields may be left blank for defaulting.' newline newline ' Azimuth (deg):'],'Elevation (deg above horizon):','Horizontal FOV (deg):','Vertical FOV (deg):','Sensor Height (m above ground):','Latitude:','Longitude:','Base Score:','StationID:','Operator:','Email:','Twitter:','Hyperlink1','Hyperlink2'};
    fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45;];
    definput = {'' '' '' '' '' '' '' '' '' '' '' '' '' ''};
    answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);
else
    logformat('input data table not yet supported.','ERROR')    
end

if isempty(answer)
    logformat('User cancelled data input.  No changes made to database.','USER')
    return
end

% store data for review
new_azimuth = str2num(answer{1});
new_elevation = str2num(answer{2});
new_hor_FOV = str2num(answer{3});
new_vert_FOV = str2num(answer{4});
new_height_m = str2num(answer{5});
new_LAT = str2num(answer{6});
new_LONG = str2num(answer{7});
new_BaseScore = str2num(answer{8});
new_StationID = answer{9};
new_Operator = answer{10};
new_Email = answer{11};
new_Twitter = answer{12};
new_Hyperlink1 = answer{13};
new_Hyperlink2 = answer{14};

% check LAT/LONG
if isempty(new_LAT) || isempty(new_LONG)
    logformat('Latitude/Longitude is required.','ERROR')

% Lookup Lat/Long in existing database, to avoid duplicating
else
    logformat(sprintf('Looking up location: %0.7g, %.7g',new_LAT, new_LONG),'INFO')

    % calculate distance from existing stations of the same type
    filt = db_Sensors_in.Type == new_sensor_type;
    db_Sensors_in.tempDist(filt) = distance(db_Sensors_in.LAT(filt),db_Sensors_in.LONG(filt), new_LAT, new_LONG ,planet.ellipsoid_m)./1000;
    nearby = find(db_Sensors_in.Type == new_sensor_type & db_Sensors_in.tempDist < 2);
    if numel(nearby) > 0
        logformat(sprintf('Match found in sensor table at row %0.0f, distance = %0.\n', nearby),'INFO')

        db_Sensors_in = movevars(db_Sensors_in,'tempDist','Before','StationID');
        db_Sensors_in(nearby,:)
        
        % Ask user to resolve duplicates
        userquest = 'Possible duplicate(s) found.  Add sensor as new?';
        logformat(userquest,'USER')
        addnew_answer = questdlg(userquest,'Add New Sensor','Yes','No','No');
        switch addnew_answer
            case 'Yes'
                addnew = true;
                logformat('User accepted to add new sensor.','USER')
            otherwise
                addnew = false;
                logformat('User declined to add new sensor.','USER')
        end

    else
        addnew = true;
        logformat('No match found in sensor table, adding new sensor...','INFO')
    end

end

% Add new sensor
if addnew
    
    add_i = size(db_Sensors_out,1) + 1;
   
    % add new record
    % Get current time
    db_Sensors_out.DateAdded(add_i) = datetime('now','TimeZone','UTC');
    db_Sensors_out.Type(add_i) = new_sensor_type;
    db_Sensors_out.LAT(add_i) = new_LAT;
    db_Sensors_out.LONG(add_i) = new_LONG;
    
    % Estimate lat/long error from precision
    clear precision
    precision = max(countprecision(db_Sensors_out.LAT(add_i)),countprecision(db_Sensors_out.LONG(add_i)));
    db_Sensors_out.error_Lat(add_i) = 5*10^-(precision);
    db_Sensors_out.error_Long(add_i) = 5*10^-(precision);
        
    % default azimuth
    if isempty(new_azimuth)
        db_Sensors_out.sensorAZ(add_i) = NaN;
        logformat('No azimuth provided, set to unknown (NaN).','INFO')

    % change azimuth
    else
        db_Sensors_out.sensorAZ(add_i) = new_azimuth;
        logformat(sprintf('Azimuth set to %g.',new_azimuth),'INFO')
    end

    % default elevation
    if isempty(new_elevation)
        db_Sensors_out.sensorELEV(add_i) = NaN;
        logformat('No elevation provided, set to unknown (NaN).','INFO')
        
    % store elevation
    else
        db_Sensors_out.sensorELEV(add_i) = new_elevation;
        logformat(sprintf('Elevation set to %g.', new_elevation),'INFO')
    end

    % default hor_FOV
    if isempty(new_hor_FOV)
        if db_Sensors_out.sensorELEV(add_i) == 90
            db_Sensors_out.sensor_hor_FOV(add_i) = 180;
        elseif isnan(db_Sensors_out.sensorAZ(add_i))
            db_Sensors_out.sensor_hor_FOV(add_i) = NaN;
        else
            db_Sensors_out.sensor_hor_FOV(add_i) = default_hor_FOV;
        end
        logformat(sprintf('hor_FOV defaulted to %g.', db_Sensors_out.sensor_hor_FOV(add_i)),'INFO')

    % Save hor_FOV
    else
        db_Sensors_out.sensor_hor_FOV(add_i) = new_hor_FOV;
        logformat(sprintf('hor_FOV set to %g.', db_Sensors_out.sensor_hor_FOV(add_i)),'INFO')
    end

    % default vert_FOV
    if isempty(new_vert_FOV)
        if db_Sensors_out.sensorELEV(add_i) == 90
            db_Sensors_out.sensor_vert_FOV(add_i) = 180;
        elseif isnan(db_Sensors_out.sensorAZ(add_i))
            db_Sensors_out.sensor_vert_FOV(add_i) = NaN;
        else
            db_Sensors_out.sensor_vert_FOV(add_i) = db_Sensors_out.sensor_hor_FOV(add_i)/default_aspectratio;
        end
        logformat(sprintf('vert_FOV defaulted to %g, using default aspect ratio %g.', db_Sensors_out.sensor_vert_FOV(add_i),default_aspectratio),'INFO')

    % save vert_FOV
    else
        db_Sensors_out.sensor_vert_FOV(add_i) = new_vert_FOV;
        logformat(sprintf('vert_FOV set to %g.', db_Sensors_out.sensor_vert_FOV(add_i)),'INFO')
    end

    % Lookup ground altitude data
    db_Sensors_out.GroundAlt_m(add_i) = getElevations(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i),'key', getPrivate('GoogleMapsAPIkey'));
    logformat(sprintf('Google provided ground elevation of %0.4g meters.', db_Sensors_out.GroundAlt_m(add_i)),'INFO')
    
    % default height_m
    if isempty(new_height_m)
        db_Sensors_out.HeightAboveGround_m(add_i) = 0;
        logformat(sprintf('Sensor height defaulted to %0.4g meters.', db_Sensors_out.HeightAboveGround_m(add_i)),'INFO')
        
    % save height_m
    else
        db_Sensors_out.HeightAboveGround_m(add_i) = new_height_m;                
    end
    
    % Calculate sensor altitude and error
    db_Sensors_out.Altitude_m(add_i) = db_Sensors_out.GroundAlt_m(add_i) + db_Sensors_out.HeightAboveGround_m(add_i);
    
    if db_Sensors_out.HeightAboveGround_m(add_i) == 0
        db_Sensors_out.error_Alt_m(add_i) = 20;
    else
        clear precision
        precision = countprecision(db_Sensors_out.HeightAboveGround_m(add_i));
        db_Sensors_out.error_Alt_m(add_i) = 2*10^-(precision);
    end
    
    db_Sensors_out.Altitude_m(add_i) = db_Sensors_out.GroundAlt_m(add_i) + db_Sensors_out.HeightAboveGround_m(add_i);
    logformat(sprintf('Sensor altitude calculated at %0.4g +/- %0.4g meters.', db_Sensors_out.Altitude_m(add_i), db_Sensors_out.error_Alt_m(add_i)),'INFO')


    % default BaseScore
    if isempty(new_BaseScore)
        db_Sensors_out.BaseScore(add_i) = default_BaseScore;
        logformat(sprintf('BaseScore defaulted to %g.', db_Sensors_out.BaseScore(add_i)),'INFO')

    % Save BaseScore
    else
        db_Sensors_out.BaseScore(add_i) = new_BaseScore;
        logformat(sprintf('BaseScore set to %g.', db_Sensors_out.BaseScore(add_i)),'INFO')
    end

        
    % default StationID
    if isempty(new_StationID)
        
        % Prompt user for station prefix
        while isempty(prefix)
            prefix = inputdlg('Enter Station prefix.');
            prefix = cell2mat(prefix);
            logformat(sprintf('User provided station prefix %s.',prefix),'USER')
        end
        
        % Encode the StationID from lat/long
        db_Sensors_out.StationID(add_i) = [prefix encodelocation(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i))];
        logformat(sprintf('StationID encoded as %s',db_Sensors_out.StationID(add_i)),'INFO')

    % Save StationID
    else
        db_Sensors_out.StationID(add_i) = new_StationID;
        logformat(sprintf('New station added as %s',db_Sensors_out.StationID(add_i)),'INFO')
    end

    % Add geolocation data
    [ ~, db_Sensors_out.City(add_i), db_Sensors_out.State(add_i), db_Sensors_out.Country(add_i), ~, ~ ] = getlocation(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i));
           
    % Add default data
    db_Sensors_out.StartYear(add_i) = 0;
    db_Sensors_out.EndYear(add_i) = 9999;
    db_Sensors_out.range_km(add_i) = 500;
    db_Sensors_out.Contact(add_i) = 'None';
    
    if ~isempty(new_Operator)
        db_Sensors_out.Operator(add_i) = new_Operator;
        logformat(sprintf('New station operator added as %s',db_Sensors_out.Operator(add_i)),'INFO')
    end
    if ~isempty(new_Email)
        db_Sensors_out.Hyperlink1(add_i) = new_Email;
        logformat(sprintf('New station Email added as %s',db_Sensors_out.Email(add_i)),'INFO')
    end
    if ~isempty(new_Twitter)
        db_Sensors_out.Twitter(add_i) = new_Twitter;
        logformat(sprintf('New station Twitter added as %s',db_Sensors_out.Twitter(add_i)),'INFO')
    end
    
    if ~isempty(new_Hyperlink1)
        db_Sensors_out.Hyperlink1(add_i) = new_Hyperlink1;
        logformat(sprintf('New station hyperlink added as %s',db_Sensors_out.Hyperlink1(add_i)),'INFO')
    end
    if ~isempty(new_Hyperlink2)
        db_Sensors_out.Hyperlink2(add_i) = new_Hyperlink2;
        logformat(sprintf('New station hyperlink 2 added as %s',db_Sensors_out.Hyperlink2(add_i)),'INFO')
    end
    
    % Display added station data
    db_Sensors_out(add_i,:)
end
