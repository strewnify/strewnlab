nom_lat = 43;

planet = getPlanet();
% Calculate aspect ratio at event latitude, for graphing
lat_metersperdeg = 2*planet.radius_m*pi/360;
long_metersperdeg = 2*planet.radius_m*pi*cos(deg2rad(nom_lat))/360;

alt1 = 30000:200:35000;
alt2 = 20000:200:31000;
G_rang = 0.025; %lat/long error in GOES measurement
ST_rang = 0.3; %degree error in St. Thomas measurement
i1 = 1;
I2 = 1;
for sceni = 1:15
    G_err = randbetween(-G_rang,G_rang);
    G_err2 = randbetween(-G_rang,G_rang);
    ST_err1 = randbetween(-ST_rang,ST_rang);
    ST_err2 = randbetween(-ST_rang,ST_rang);
    ST_err3 = randbetween(-ST_rang,ST_rang);
    ST_err4 = randbetween(-ST_rang,ST_rang);
    
    for idx = 1:size(alt1,2)

        alt1i(i1) = alt1(idx);
        % Solve GOES1 project location for altitude
        [G1_AZ, G1_ELEV, slantRange] = geodetic2aer(43.24 + G_err,-76.54 + G_err2,10000,0,-75.199997,35786020,planet.ellipsoid_m);
        [G1_LAT(i1),G1_LONG(i1),slantrange] = aer2geosolve(G1_AZ,G1_ELEV,0,-75.199997,35786020,alt1(idx),planet);

        % Solve St. Thomas 1 projected location for altitude
        [ST1_LAT(i1),ST1_LONG(i1),slantrange] = aer2geosolve(84.22 + ST_err1,3.08974 + ST_err2,42.792764,-81.161779,237,alt1(idx),planet);
        
        i1=i1+1;
    end

    for idx = 1:size(alt2,2)

        alt2i(I2) = alt2(idx);
        % Solve GOES2 project location for altitude
        [G2_AZ, G2_ELEV, slantRange] = geodetic2aer(43.13 + G_err,-76.645 + G_err2,10000,0,-75.199997,35786020,planet.ellipsoid_m);
        [G2_LAT(I2),G2_LONG(I2),slantrange] = aer2geosolve(G2_AZ,G2_ELEV,0,-75.199997,35786020,alt2 (idx),planet);

        % Solve St. Thomas 2 projected location for altitude
        [ST2_LAT(I2),ST2_LONG(I2),slantrange] = aer2geosolve(85.60 + ST_err3,2.86871 + ST_err4,42.792757,-81.161503,237,alt2 (idx),planet);
        I2=I2+1;
    end
    
end

figure
hold on
grid on
scatter3(ST1_LONG,ST1_LAT,alt1i,'r')
scatter3(G1_LONG,G1_LAT,alt1i,'b')
scatter3(ST2_LONG,ST2_LAT,alt2i,'r')
scatter3(G2_LONG,G2_LAT,alt2i,'b')

%Solution?
%plot3([-76.55 -76.635],[43.03 42.95],[31000,28000])
scatter3(-76.51,43.025,32500,'k','filled')
scatter3(-76.655,42.945,28500,'k','filled')
