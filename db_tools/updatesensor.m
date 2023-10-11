function db_Sensors_out = updatesensor(db_Sensors_in, StationID)
%UPDATESENSOR Update sensor data after detailed review

default_hor_FOV = 140;
default_aspectratio = 1.3;

logformat(sprintf('User requested data update for %s.',StationID),'USER')

% Copy the database to output
db_Sensors_out = db_Sensors_in;

% updt_i = find(contains(db_Sensors_out.StationID,StationID));
updt_i = find(strcmp(db_Sensors_out.StationID,StationID));

if isempty(updt_i)
    logformat(sprintf('%s not found.',StationID),'ERROR')
end
if numel(updt_i) > 1
    logformat(sprintf('Searching for %s...',StationID),'INFO')
    logformat(sprintf('Match found in sensor table at row %0.0f\n', updt_i),'INFO')
    logformat(sprintf('Multiple results found for %s.',StationID),'ERROR')    
end
logformat(sprintf('Match found in sensor table at row %0.0f\n', updt_i),'INFO')

db_Sensors_in(updt_i,:)

% Create a dialog box
dlgtitle = 'Input Station Data';
opts.WindowStyle = 'normal';
opts.Resize = 'off';
prompt = {sprintf('Enter Data for Station %s:\nFields may be left blank for defaulting.\n\n Azimuth (deg):',StationID),'Elevation (deg above horizon):','Horizontal FOV (deg):','Vertical FOV (deg):','Sensor Height (m above ground):','Latitude:','Longitude:','Base Score:'};
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45;];
definput = {sprintf('%0.7g',db_Sensors_out.sensorAZ(updt_i)),sprintf('%0.9g',db_Sensors_out.sensorELEV(updt_i)),sprintf('%0.9g',db_Sensors_out.sensor_hor_FOV(updt_i)),sprintf('%0.9g',db_Sensors_out.sensor_vert_FOV(updt_i)),sprintf('%0.9g',db_Sensors_out.HeightAboveGround_m(updt_i)),sprintf('%0.9g',db_Sensors_out.LAT(updt_i)),sprintf('%0.9g',db_Sensors_out.LONG(updt_i)), sprintf('%0.9g',db_Sensors_out.BaseScore(updt_i))};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);

if isempty(answer)
    logformat('User cancelled data input.  No changes made to database.','USER')

else
    % **** answer 1 - sensor azimuth ****
    old_azimuth = db_Sensors_in.sensorAZ(updt_i);
    new_azimuth = str2num(answer{1});

    % default azimuth
    if isempty(new_azimuth)
        logformat('No defaulting strategy for azimuth. No change to azimuth.','INFO')

    % change azimuth
    elseif new_azimuth ~= old_azimuth
        db_Sensors_out.sensorAZ(updt_i) = new_azimuth;
        logformat(sprintf('Azimuth updated from %g to %g.',old_azimuth, new_azimuth),'INFO')

    % No change
    else
        logformat('No change to azimuth.','INFO')
    end

    % **** answer 2 - sensor elevation ****
    old_elevation = db_Sensors_in.sensorELEV(updt_i);
    new_elevation = str2num(answer{2});

    % default elevation
    if isempty(new_elevation)
        logformat('No defaulting strategy for elevation. No change to elevation.','INFO')

    % change elevation
    elseif new_elevation ~= old_elevation
        db_Sensors_out.sensorELEV(updt_i) = new_elevation;
        logformat(sprintf('elevation updated from %g to %g.',old_elevation, new_elevation),'INFO')

    % No change
    else
        logformat('No change to elevation.','INFO')
    end
    
    % **** answer 3 - sensor horizontal FOV ****
    old_hor_FOV = db_Sensors_in.sensor_hor_FOV(updt_i);
    new_hor_FOV = str2num(answer{3});

    % default hor_FOV
    if isempty(new_hor_FOV)
        db_Sensors_out.sensor_hor_FOV(updt_i) = default_hor_FOV;
        logformat(sprintf('hor_FOV defaulted to %g.', db_Sensors_out.sensor_hor_FOV(updt_i)),'INFO')

    % change hor_FOV
    elseif new_hor_FOV ~= old_hor_FOV
        db_Sensors_out.sensor_hor_FOV(updt_i) = new_hor_FOV;
        logformat(sprintf('hor_FOV updated from %g to %g.',old_hor_FOV, db_Sensors_out.sensor_hor_FOV(updt_i)),'INFO')

    % No change
    else
        logformat('No change to hor_FOV.','INFO')
    end
    
    % **** answer 4 - sensor vertical FOV ****
    old_vert_FOV = db_Sensors_in.sensor_vert_FOV(updt_i);
    new_vert_FOV = str2num(answer{4});

    % default vert_FOV
    if isempty(new_vert_FOV)
        db_Sensors_out.sensor_vert_FOV(updt_i) = db_Sensors_out.sensor_hor_FOV(updt_i)/default_aspectratio;
        logformat(sprintf('vert_FOV defaulted to %g, using default aspect ratio %g.', db_Sensors_out.sensor_vert_FOV(updt_i),default_aspectratio),'INFO')

    % change vert_FOV
    elseif abs(new_vert_FOV - old_vert_FOV) > 0.01
        db_Sensors_out.sensor_vert_FOV(updt_i) = new_vert_FOV;
        logformat(sprintf('vert_FOV updated from %g to %g.',old_vert_FOV, db_Sensors_out.sensor_vert_FOV(updt_i)),'INFO')

    % No change
    else
        logformat('No change to vert_FOV.','INFO')
    end
    
    % **** answer 5 - Height above ground ****
    old_height_m = db_Sensors_in.HeightAboveGround_m(updt_i);
    new_height_m = str2num(answer{5});

    % default height_m
    if isempty(new_height_m)
        logformat('No defaulting strategy for height. No change to height.','INFO')

    % change height_m
    elseif new_height_m ~= old_height_m
        db_Sensors_out.HeightAboveGround_m(updt_i) = new_height_m;
        db_Sensors_out.Altitude_m(updt_i) = db_Sensors_out.GroundAlt_m(updt_i) + db_Sensors_out.HeightAboveGround_m(updt_i);
        logformat(sprintf('Sensor height updated from %g to %0.4g meters.',old_height_m, db_Sensors_out.HeightAboveGround_m(updt_i)),'INFO')
        logformat(sprintf('New sensor altitude calculated at %0.4g meters.', db_Sensors_out.Altitude_m(updt_i)),'INFO')

    % No change
    else
        logformat('No change to height_m.','INFO')
    end
    
    % **** answer 6 - Latitude ****
    old_LAT = db_Sensors_in.LAT(updt_i);
    new_LAT = str2num(answer{6});

    % default LAT
    if isempty(new_LAT)
        logformat('No defaulting strategy for Latitude. No change to Latitude.','INFO')

    % change LAT
    elseif new_LAT ~= old_LAT
        db_Sensors_out.LAT(updt_i) = new_LAT;
        precision = countprecision(db_Sensors_out.LAT(updt_i));
        db_Sensors_out.error_Lat(updt_i) = 5*10^-(precision);
   
        logformat(sprintf('LAT updated from %0.7g to %0.7g.',db_Sensors_in.LAT(updt_i), db_Sensors_out.LAT(updt_i)),'INFO')
        logformat(sprintf('LAT error updated from %0.8g to %0.8g.',db_Sensors_in.error_Lat(updt_i), db_Sensors_out.error_Lat(updt_i)),'INFO')

    % No change
    else
        logformat('No change to LAT.','INFO')
    end
    
    % **** answer 7 - Longitude ****
    old_LONG = db_Sensors_in.LONG(updt_i);
    new_LONG = str2num(answer{7});

    % default LONG
    if isempty(new_LONG)
        logformat('No defaulting strategy for Longitude. No change to Longitude.','INFO')

    % change LONG
    elseif new_LONG ~= old_LONG
        db_Sensors_out.LONG(updt_i) = new_LONG;
        precision = countprecision(db_Sensors_out.LONG(updt_i));
        db_Sensors_out.error_LONG(updt_i) = 5*10^-(precision);
        logformat(sprintf('LONG updated from %0.7g to %0.7g.',old_LONG, db_Sensors_out.LONG(updt_i)),'INFO')
        logformat(sprintf('LONG error updated from %0.8g to %0.8g.',db_Sensors_in.error_Long(updt_i), db_Sensors_out.error_Long(updt_i)),'INFO')

    % No change
    else
        logformat('No change to LONG.','INFO')
    end
    
    % **** answer 8 - base score ****
    old_BaseScore = db_Sensors_in.BaseScore(updt_i);
    new_BaseScore = str2num(answer{8});

    % default BaseScore
    if isempty(new_BaseScore)
        logformat('No defaulting strategy for BaseScore. No change to BaseScore.','INFO')

    % change BaseScore
    elseif new_BaseScore ~= old_BaseScore
        db_Sensors_out.BaseScore(updt_i) = new_BaseScore;
        logformat(sprintf('BaseScore updated from %g to %g.',old_BaseScore, new_BaseScore),'INFO')

    % No change
    else
        logformat('No change to BaseScore.','INFO')
    end
    
end

db_Sensors_out(updt_i,:)
    