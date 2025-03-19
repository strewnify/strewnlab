% INTERSECTSOLVE Solves for the intersection point of two 3D lines
traj_AZ = 102.1629
traj_ELEV = -48.5766
traj_lat = 49.831261
traj_lon = 0.503375
traj_height = 44751.68

B_lat = 50.82
B_long = -0.14
B_ELEV = 8.5645
B_cam_height = 5
B_height = 13000; % init estimate

err_idx = 0;
for B_AZ = 145:0.1:154
err_idx = err_idx + 1;
test_AZ(err_idx) = B_AZ;
% Find intersection
[latIntersect,lonIntersect] = crossfix([B_lat traj_lat],[B_long traj_lon], [B_AZ traj_AZ]);
LAT(err_idx) = latIntersect(1);
LON(err_idx) = lonIntersect(1);

% Get height on trajectory
for height = 1:traj_height
    [AZ, ELEV, slantRange] = geodetic2aer(LAT(err_idx), LON(err_idx), height, traj_lat, traj_lon, traj_height ,planet);
    error(height) = abs(ELEV - traj_ELEV);
end
[~,test_height(err_idx)] = min(error);

[AZ, ELEV, slantRange] = geodetic2aer(LAT(err_idx), LON(err_idx), test_height(err_idx), B_lat, B_long, B_cam_height ,planet);
elev_error(err_idx) = abs(ELEV - B_ELEV);

end

[~,soln_idx] = min(elev_error);
LAT_soln = LAT(soln_idx)
LON_soln = LON(soln_idx)
height_soln = test_height(soln_idx)
AZ_soln = test_AZ(soln_idx)

