function [db_Sensors_out, inputdata] = addsensors(db_Sensors_in, inputdata)
%ADDSENSORS Add a new sensor to the database

% Load config for default FOV
strewnconfig

logformat('Need to fix sensor range calculation','DEBUG')

% Initialize variables
prefix = ''; % Station ID prefix
default_BaseScore = 5;
new_sensor_type = '';
nowtime_utc = datetime('now','TimeZone','UTC');
records_updated = 0;

% Disable table row assignment warning
warning('off','MATLAB:table:RowsAddedExistingVars');

% Check and Log request type

% No input data provided
if nargin == 1
    inputtable = false;
    inputdata = table; % Initialize an empty table to populate with user data
    numsensors = inf; % add sensors until cancelled
    
    % Log input type
    if getSession('state','userpresent')
        logformat('Adding new sensor(s) from user form.','USER')        
    else
        logformat('User not present. Data input required.','ERROR')
    end
    
% Input data table provided
elseif nargin == 2
    inputtable = true;
    numsensors = size(inputdata,1);
    if getSession('state','userpresent')
        logformat('User requested to add new sensors from data table.','USER')        
    else
        logformat('User not present. Automated sensor add routine started.','INFO')           
    end
    
% ERROR: Incorrect number of arguments
else
    if getSession('state','userpresent')
        logformat('Incorrect number of arguments.','ERROR')
    else
        logformat('User not present, incorrect number of arguments.','ERROR')
    end
end     

% Copy the database to output
db_Sensors_out = db_Sensors_in;

% Get sensor type for this session
while isempty(new_sensor_type)        
    sensor_types = categories(db_Sensors_in.Type);
    new_sensor_type = listdlg('ListString',sensor_types);
    new_sensor_type = convertCharsToStrings(sensor_types{new_sensor_type});
end

% Set defaults by sensor type
switch new_sensor_type
    case 'Camera'
        plot_color = [0.3961 0.4980 0.5882];
    case 'Seismic'
        plot_color = [0.2863 0.2863 0.2784];
    case 'Doppler'
        plot_color = [0.2863 0.2863 0.2784];
    case 'Geostationary'
        plot_color = [0 0 0];
    otherwise
        plot_color = [0.2863 0.2863 0.2784];               
end

% Get data an analyze sensors, one at a time
for sensor_i = 1:numsensors
    
    % Get data
    if ~inputtable

        incomplete = true;
        
        while incomplete
            logformat('User queried for sensor data.','USER')
            
            % Create a User Form for sensor data entry
            % Fields may be left blank for defaulting
            % 1 - Azimuth (numeric)
            % 2 - Elevation - degrees above horizon (numeric)
            % 3 - Horizontal FOV - degrees - (numeric)
            % 4 - Vertical FOV - degrees - (numeric)
            % 5 - Sensor Height - meters above ground (numeric)
            % 6 - Latitude - decimal degrees (numeric)
            % 7 - Longitude - decimal degrees (numeric)
            % 8 - Base Score - 1 to 100 (numeric)
            % 9 - StationID (text)
            % 10 - Operator (text)
            % 11 - Email (text)
            % 12 - Twitter (text)
            % 13 - Hyperlink1 (text)
            % 14 - Hyperlink2 (text)
            incomplete = false;
            dlgtitle = 'Input Station Data';
            opts.WindowStyle = 'normal';
            table_var = {'sensorAZ','sensorELEV','sensor_hor_FOV','sensor_vert_FOV','HeightAboveGround_m','LAT',     'LONG',     'BaseScore', 'StationID','Operator','Email','Twitter','Hyperlink1','Hyperlink2'};
            form_var =  {'Azimuth', 'Elevation', 'Horizontal FOV','Vertical FOV',   'Sensor Height',      'Latitude','Longitude','Base Score','StationID','Operator','Email','Twitter','Hyperlink1','Hyperlink2'};
            notes_var = {' (deg):', ' (deg above horizon):', ' (deg):',' (deg):',' (m above ground):',' (decimal deg):',' (decimal deg):',' (1 to 100):',':',':',':',':','',''};
            prompt = {['Enter Data for new station.' newline 'Fields may be left blank for defaulting.' newline newline ' Azimuth (deg):']};
            prompt = [prompt strcat(form_var(2:end),notes_var(2:end))];
            fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45;];
            definput = {'' '' '' '' '' '' '' '' '' '' '' '' '' ''};
            answer = inputdlg(prompt,dlgtitle,fieldsize,definput,opts);

            if isempty(answer)
                logformat(sprintf('Data input cancelled by user. %d records added.', records_updated),'USER')
                return
            end

            % store data for review
            inputdata.DateAccessed(sensor_i) = nowtime_utc;

            % Store numeric data
            for ans_i = 1:8
                if ~isempty(answer{ans_i})
                    temp_ans = str2num(answer{ans_i});
                    if ~isempty(temp_ans)
                        inputdata.(table_var{ans_i})(sensor_i) = temp_ans;
                    else
                        incomplete = true;
                        logformat(sprintf('Non-numeric data entry for %s',form_var{ans_i}),'WARN')                        
                    end
                end
            end

            % Store text data
            for ans_i = 9:14
                if ~isempty(answer{ans_i})
                    temp_ans = answer{ans_i};
                    if ~isempty(temp_ans)
                        inputdata.(table_var{ans_i}){sensor_i} = temp_ans;
                    else
                        incomplete = true;
                        logformat(sprintf('Invalid entry for %s',form_var{ans_i}),'WARN')
                    end
                end
            end        
        end
    end
    
    % Analyze Data
        
    % Check for LAT/LONG data
    if datapresent(inputdata(sensor_i,:),{'LAT', 'LONG'})
        
        % Sensor review log
        if inputtable
            logformat(sprintf('Reviewing input data table row %g...',sensor_i),'INFO')
        else
            logformat(sprintf('Reviewing user form data, sensor %g...',sensor_i),'INFO')
        end
               
        % Looking up Lat/Long in existing database, to avoid duplicating
        logformat(sprintf('Looking up location: %0.7g, %.7g',inputdata.LAT(sensor_i), inputdata.LONG(sensor_i)),'INFO')

        % calculate distance from existing stations of the same type
        sensitivity_m = 2;
        filt = db_Sensors_in.Type == new_sensor_type;
        db_Sensors_in.tempDist(filt) = distance(db_Sensors_in.LAT(filt),db_Sensors_in.LONG(filt), inputdata.LAT(sensor_i), inputdata.LONG(sensor_i) ,getPlanet('ellipsoid_m'))./1000;
        nearby = find(db_Sensors_in.Type == new_sensor_type & db_Sensors_in.tempDist < 2);
        if numel(nearby) > 0
            logformat(sprintf('Match found in sensor table at row %g, distance = %g meters\n', nearby, db_Sensors_in.tempDist(nearby)),'INFO')

            db_Sensors_in = movevars(db_Sensors_in,'tempDist','Before','StationID');
            db_Sensors_in(nearby,:)

            if getSession('state','userpresent')
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
                addnew = false;
                logformat('Duplicate sensor ignored in automated review.','WARN')
            end

        else
            addnew = true;
            logformat('No match found in sensor database, adding new sensor...','INFO')
        end
    else
        addnew = false;
        logformat(sprintf('Latitude/Longitude missing for sensor %f',sensor_i),'WARN')
    end

    % Add new sensor
    if addnew

        records_updated = records_updated + 1;
        add_i = size(db_Sensors_out,1) + 1;

        % Add new record
        % Get current time
        db_Sensors_out.DateAdded(add_i) = nowtime_utc;
        db_Sensors_out.LAT(add_i) = inputdata.LAT(sensor_i);
        db_Sensors_out.LONG(add_i) = inputdata.LONG(sensor_i);

        % Estimate lat/long error from precision
        clear precision
        precision = max(countprecision(db_Sensors_out.LAT(add_i)),countprecision(db_Sensors_out.LONG(add_i)));
        db_Sensors_out.error_Lat(add_i) = 5*10^-(precision);
        db_Sensors_out.error_Long(add_i) = 5*10^-(precision);

        % Set sensor type
        if ~datapresent(inputdata(sensor_i,:),{'Type'})
            db_Sensors_out.Type(add_i) = new_sensor_type;
        
        % Allow sensor type to be imported from data table
        else
            db_Sensors_out.Type(add_i) = new_sensor_type;
            logformat(sprintf('New station type imported as %s',db_Sensors_out.Type(add_i)),'INFO')
        end
        
        % default azimuth
        if ~datapresent(inputdata(sensor_i,:),{'sensorAZ'})
            db_Sensors_out.sensorAZ(add_i) = NaN;
            logformat('No azimuth provided, set to unknown (NaN).','INFO')

        % change azimuth
        else
            db_Sensors_out.sensorAZ(add_i) = inputdata.sensorAZ(sensor_i);
            logformat(sprintf('Azimuth set to %g.',db_Sensors_out.sensorAZ(add_i)),'INFO')
        end

        % default elevation
        if ~datapresent(inputdata(sensor_i,:),{'sensorELEV'})
            db_Sensors_out.sensorELEV(add_i) = NaN;
            logformat('No elevation provided, set to unknown (NaN).','INFO')

        % store elevation
        else
            db_Sensors_out.sensorELEV(add_i) = inputdata.sensorELEV(sensor_i);
            logformat(sprintf('Elevation set to %g.', db_Sensors_out.sensorELEV(add_i)),'INFO')
        end

        % default hor_FOV
        if ~datapresent(inputdata(sensor_i,:),{'sensor_hor_FOV'})
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
            db_Sensors_out.sensor_hor_FOV(add_i) = inputdata.sensor_hor_FOV(sensor_i);
            logformat(sprintf('hor_FOV set to %g.', db_Sensors_out.sensor_hor_FOV(add_i)),'INFO')
        end

        % default vert_FOV
        if ~datapresent(inputdata(sensor_i,:),{'sensor_vert_FOV'})
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
            db_Sensors_out.sensor_vert_FOV(add_i) = inputdata.sensor_vert_FOV(sensor_i);
            logformat(sprintf('vert_FOV set to %g.', db_Sensors_out.sensor_vert_FOV(add_i)),'INFO')
        end

        % Lookup ground altitude data
        if ~datapresent(inputdata(sensor_i,:),{'GroundAlt_m'})
            db_Sensors_out.GroundAlt_m(add_i) = getElevations(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i),'key', getPrivate('GoogleMapsAPIkey'));
            logformat(sprintf('Google provided ground elevation of %0.4g meters.', db_Sensors_out.GroundAlt_m(add_i)),'INFO')
            
        % Import ground altitude data
        else
            db_Sensors_out.GroundAlt_m(add_i) = inputdata.GroundAlt_m(sensor_i);
            logformat(sprintf('Ground altitude set to %g meters.', db_Sensors_out.GroundAlt_m(add_i)),'INFO')
        end
        
        % default height_m
        if ~datapresent(inputdata(sensor_i,:),{'HeightAboveGround_m'})
            db_Sensors_out.HeightAboveGround_m(add_i) = 0;
            logformat(sprintf('Sensor height defaulted to %0.4g meters.', db_Sensors_out.HeightAboveGround_m(add_i)),'INFO')

        % save height_m
        else
            db_Sensors_out.HeightAboveGround_m(add_i) = inputdata.HeightAboveGround_m(sensor_i);
            logformat(sprintf('Sensor height set to %0.4g meters.', db_Sensors_out.HeightAboveGround_m(add_i)),'INFO')
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

        % Altitude data is always calculated from Ground Altitude and Height, because the source cannot be confirmed
        db_Sensors_out.Altitude_m(add_i) = db_Sensors_out.GroundAlt_m(add_i) + db_Sensors_out.HeightAboveGround_m(add_i);
        logformat(sprintf('Sensor altitude calculated at %0.4g +/- %0.4g meters.', db_Sensors_out.Altitude_m(add_i), db_Sensors_out.error_Alt_m(add_i)),'INFO')

        % Default Start and End Year
        if ~datapresent(inputdata(sensor_i,:),{'StartYear', 'EndYear'})
            db_Sensors_out.StartYear(add_i) = 0;
            db_Sensors_out.EndYear(add_i) = 9999;

        % Import Start and End Year
        else
            db_Sensors_out.StartYear(add_i) = inputdata.StartYear(sensor_i);
            db_Sensors_out.EndYear(add_i) = inputdata.EndYear(sensor_i);
            logformat(sprintf('Sensor active from %g to %g.', db_Sensors_out.StartYear(add_i), db_Sensors_out.EndYear(add_i)),'INFO')
        end
        
        % Set Station Range
        if ~datapresent(inputdata(sensor_i,:),{'range_km'})
            db_Sensors_out.range_km(add_i) = 500;
            logformat(sprintf('Station range defaulted to %g.', db_Sensors_out.range_km(add_i)),'INFO')

        % Import Station Range
        else
            db_Sensors_out.range_km(add_i) = inputdata.range_km(sensor_i);
            logformat(sprintf('Station range imported: %g.', db_Sensors_out.range_km(add_i)),'INFO')
        end
        
        % default BaseScore
        if ~datapresent(inputdata(sensor_i,:),{'BaseScore'})
            db_Sensors_out.BaseScore(add_i) = default_BaseScore;
            logformat(sprintf('BaseScore defaulted to %g.', db_Sensors_out.BaseScore(add_i)),'INFO')

        % Save BaseScore
        else
            db_Sensors_out.BaseScore(add_i) = inputdata.BaseScore(sensor_i);
            logformat(sprintf('BaseScore set to %g.', db_Sensors_out.BaseScore(add_i)),'INFO')
        end


        % default StationID
        if ~datapresent(inputdata(sensor_i,:),{'StationID'})

            if getSession('state','userpresent')
                % Prompt user for station prefix
                while isempty(prefix)
                    prefix = inputdlg('Enter Station prefix.');
                    prefix = cell2mat(prefix);
                    logformat(sprintf('User provided station prefix %s.',prefix),'USER')
                end
            else
                switch db_Sensors_out.Type(add_i)
                    case 'Camera'
                        prefix = 'PVT';
                    otherwise
                        prefix = 'XXX';
                        logformat('undefined prefix!','ERROR')
                end
            end
        
            % Encode the StationID from lat/long
            db_Sensors_out.StationID(add_i) = [prefix encodelocation(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i))];
            logformat(sprintf('StationID encoded as %s',db_Sensors_out.StationID(add_i)),'INFO')

        % Save StationID
        else
            db_Sensors_out.StationID(add_i) = inputdata.StationID(sensor_i);
            logformat(sprintf('New station added as %s',db_Sensors_out.StationID(add_i)),'INFO')
        end

        % Import Station Name
        if datapresent(inputdata(sensor_i,:),{'StationName'})
            db_Sensors_out.StationName(add_i) = inputdata.StationName(sensor_i);
            logformat(sprintf('New station StationName added as %s',db_Sensors_out.StationName(add_i)),'INFO')
        end
        
        % Import Operator
        if datapresent(inputdata(sensor_i,:),{'Operator'}) && ~strcmp(inputdata.Operator(sensor_i),'All Rights Reserved')
            db_Sensors_out.Operator(add_i) = inputdata.Operator(sensor_i);
            logformat(sprintf('New station operator added as %s',db_Sensors_out.Operator(add_i)),'INFO')
        end
        
        % Get location data
        if ~datapresent(inputdata(sensor_i,:),{'City', 'State', 'Country'})
            
            % Geolocate LAT/LONG 
            [ ~, db_Sensors_out.City(add_i), db_Sensors_out.State(add_i), db_Sensors_out.Country(add_i), ~, ~ ] = getlocation(db_Sensors_out.LAT(add_i),db_Sensors_out.LONG(add_i));
            logformat(sprintf('New station location retrieved as %g.', db_Sensors_out.BaseScore(add_i)),'INFO')

        % Import location data
        else
            db_Sensors_out.City(add_i) = inputdata.City(sensor_i);
            db_Sensors_out.State(add_i) = inputdata.State(sensor_i);
            db_Sensors_out.Country(add_i) = inputdata.Country(sensor_i);
            logformat(sprintf('New station location imported: %s, %s, %s.', db_Sensors_out.City(add_i), db_Sensors_out.State(add_i), db_Sensors_out.Country(add_i)),'INFO')
        end
        
        if datapresent(inputdata(sensor_i,:),{'Email'})
            db_Sensors_out.Email(add_i) = inputdata.Email(sensor_i);
            logformat(sprintf('New station Email added as %s',db_Sensors_out.Email(add_i)),'INFO')
        end
        
        if datapresent(inputdata(sensor_i,:),{'Twitter'})
            db_Sensors_out.Twitter(add_i) = inputdata.Twitter(sensor_i);
            logformat(sprintf('New station Twitter added as %s',db_Sensors_out.Twitter(add_i)),'INFO')
        end

        if datapresent(inputdata(sensor_i,:),{'Notes'})
            db_Sensors_out.Notes(add_i) = inputdata.Notes(sensor_i);
            logformat(sprintf('New station Notes imported: %s',db_Sensors_out.Notes(add_i)),'INFO')
        end
        
        if ~datapresent(inputdata(sensor_i,:),{'plot_color'})
            db_Sensors_out.plot_color(add_i,:) = plot_color;
        else
            db_Sensors_out.plot_color(add_i,:) = inputdata.plot_color(sensor_i);            
        end
        
        if datapresent(inputdata(sensor_i,:),{'Hyperlink1'})
            db_Sensors_out.Hyperlink1(add_i) = inputdata.Hyperlink1(sensor_i);
            logformat(sprintf('New station Hyperlink1 added as %s',db_Sensors_out.Hyperlink1(add_i)),'INFO')
        end
        
        if datapresent(inputdata(sensor_i,:),{'Hyperlink2'})
            db_Sensors_out.Hyperlink2(add_i) = inputdata.Hyperlink2(sensor_i);
            logformat(sprintf('New station Hyperlink2 added as %s',db_Sensors_out.Hyperlink2(add_i)),'INFO')
        end
        
        if datapresent(inputdata(sensor_i,:),{'NumEvents'})
            db_Sensors_out.NumEvents(add_i) = inputdata.NumEvents(sensor_i);
            logformat(sprintf('New station NumEvents added as %s',db_Sensors_out.NumEvents(add_i)),'INFO')
        end
        
        if ~datapresent(inputdata(sensor_i,:),{'Contact'})
            db_Sensors_out.Contact(add_i) = 'None';
        else
            db_Sensors_out.Contact(add_i) = inputdata.Contact(sensor_i);
            logformat(sprintf('New station Contact imported as %s',db_Sensors_out.Contact(add_i)),'INFO')
        end
        
        % If manual form entry is used, no review needed
        if inputtable == false && getSession('state','userpresent')
            db_Sensors_out.NeedsReview(add_i) = false;
            
        % Otherwise, tag for later review
        else
            db_Sensors_out.NeedsReview(add_i) = true;
        end
        
        % Display added station data
        db_Sensors_out(add_i,:)
    end
end
