% STREWNCONFIG load strewn field configuration file


webread_timeout = 60;

% Initialize globals
strewn_initialize

% Program locations
GoogleEarth_path = 'C:\Program Files\Google\Google Earth Pro\client\googleearth.exe';
WCT_path = 'C:\Program Files (x86)\wct-4.8.1\wct.exe';

% Load private keys
loadprivate

% Database settings
DatabaseFilename = 'StrewnifyDatabase'; %.mat filename
Database_prefix = 'sdb_*'; % all variables in the database must have this prefix, to be saved properly
Database_EventData_varname = 'sdb_Events'; % database integrity check, if this variable is not found, error
column_width = 25; % column width for reports and location string length.  WARNING: Database rebuild required to update old events.

% Sensor database settings
default_hor_FOV = 140;
default_aspectratio = 1.3;

% Generate a cell array of EventID increments, in case of multiple events in one hour
% Supports up to 1296 additional events
EventIDidx_char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
for cnt = 1:1296
    if cnt <= numel(EventIDidx_char)
        char1 = 'Z';
    else
        char1 = EventIDidx_char(ceil(cnt/numel(EventIDidx_char))-1);
    end
    char2 = EventIDidx_char(mod(cnt-1,numel(EventIDidx_char))+1);
    EventIDidx(cnt) = {[char1 char2]};
end

% Constants
planet = getPlanet();

% Data filters
slowmeteor_min_kps = 0; % meteors below this speed will be reported from ASGARD, regardless of altitude
end_alt_max_km = 50; % maximum end altitude, to filter data from ASGARD and GMN
Speed_max_kps = 110; % maximum meteor speed, to filter invalid data from ASGARD (like lightning strikes)
ImpactEnergy_min_kt = 4e-7; % Minimum impact energy filter, 4e-7 kt TNT is equivalent to 25 grams at 12km/s
mag_fireball = -3; % minimum brightness for a fireball ~ mag < -3

% Web access options
URL_IGRA_stationinventorydir = 'ftp://ftp.ncei.noaa.gov/pub/data/igra/';
IGRA_stationinventoryfile = 'igra2-station-list.txt';
URL_IGRA_pordatadir = 'ftp://ftp.ncei.noaa.gov/pub/data/igra/data/data-por/';
URL_IGRA_y2ddatadir = 'ftp://ftp.ncei.noaa.gov/pub/data/igra/data/data-y2d/';

% Simulation options
meas_density_err = 0.05; % error in density measurement, example 0.05 = 5%
stealth = false; % stealth mode suppresses common windows, like the waitbar
RealtimeMult = 100; % Simulation speed when useplot is true, 100 for max speed
distancestep = 200; % meters (don't forget to allow for one split per step)
minmass = 0.001; % minimum simulation mass in kilograms, typically 0.001 (1 gram)
maxflighttime = 14400; % maximum flight time in seconds
ablation_thresh = 0.02; % threshold for visible ablation, in kg/s (approximately 0.02?)

% Export options
if ~exist('exporting','var')
    exporting = false;
end
nom_startaltitude = 80000; % nominal path start altitude for visualization
max_pathlength3D_m = 150000; % For very horizontal paths, it is necessary to clip the path length to prevent very long path lengths and simulation times

% Graphing options
useplot = false;
speedplot = false;
timeplot = false;
plotstep = 1; %number of steps between plot updates
ref_marksize = 5; % size of the marker used for the known location
mark = 'bo';
default_marksize = 25; 
marksize = default_marksize;
MagnusMult = 1;  % Magnus effect multiplier, 0 for off, 1 for on
gridsize = 500; % Grid size in meters, typically 500
edge_type = 'k'; % 'k' for black, 'none' for none

% Monte Carlo parameters
sigma_thresh = 3;  % sigma threshold for Monte Carlo random number generation.  Typically 3.
sigma_mult = 4;  % determines the shape of the random number distribution, 1 is very flat, 6 is very pointed
WindSigma = 1.5; % how many standard deviations of wind speed to include
cubicity_mean = 0.5;
cubicity_stdev = 0.25;
cubicity_min = 0;
cubicity_max = 1;
frontalareamult_mean = 1;
frontalareamult_stdev = 0.25;
frontalareamult_min = 0.4;
frontalareamult_max = 1.6;

% Google Maps API
URL_GoogleElevationAPI = 'https://maps.googleapis.com/maps/api/elevation/xml?locations=';
URL_GoogleGeocodingAPI = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&key=';

% American Meteor Society (AMS) API
URL_AMS_API = 'https://www.amsmeteors.org/members/api/open_api/get_events?';

% Data release statement
release_statement = '**** DATA RELEASE STATEMENT AND TERMS OF USE ****';
release_statement = [release_statement newline 'This data/work is a product of Strewnify.com, and is not subject to copyright protection.  Strewnify.com provides this'];
release_statement = [release_statement newline 'data/work “AS IS” and makes no warranty of any kind, express or implied, as to the merchantability, fitness for a '];
release_statement = [release_statement newline 'particular purpose, non-infringement, or data accuracy. Strewnify does not warrant or make any representations regarding'];
release_statement = [release_statement newline 'the use of the data or the results thereof, including but not limited to the correctness, accuracy, reliability or '];
release_statement = [release_statement newline 'usefulness of the data. User assumes all risk. Always check local laws and obtain permission before hunting for meteorites.'];
release_statement = [release_statement newline newline 'Report generated by StrewnLAB software'];
release_statement = [release_statement newline 'Jim Goodall, Strewnify.com'];
    
% Check flag
check_configloaded = true;
